import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../data/local_store.dart';
import '../../data/map_providers.dart';
import '../../domain/charging_station.dart';
import '../../domain/energy_estimator.dart';
import '../../domain/ownership_record.dart';
import '../../domain/routing_provider.dart';
import '../../domain/trip_prompt.dart';
import '../../domain/vehicle.dart';
import '../garage/garage_screen.dart';
import '../garage/record_editor.dart';
import '../ownership/vehicle_log_button.dart';

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key, required this.store});
  final LocalStore store;

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  final prompt = TextEditingController();
  final originName = TextEditingController();
  final destinationName = TextEditingController();
  final origin = TextEditingController();
  final destination = TextEditingController();
  final distance = TextEditingController();
  final capacity = TextEditingController();
  final efficiency = TextEditingController();
  final soc = TextEditingController();
  final reserve = TextEditingController(text: '20');
  final connector = TextEditingController();
  final client = http.Client();
  late final vehicles = widget.store.vehicles();
  bool busy = false;
  String output = '';

  @override
  void dispose() {
    for (final field in [
      prompt,
      originName,
      destinationName,
      origin,
      destination,
      distance,
      capacity,
      efficiency,
      soc,
      reserve,
      connector,
    ]) {
      field.dispose();
    }
    client.close();
    super.dispose();
  }

  void readPrompt() {
    final parsed = parseTripPrompt(prompt.text);
    if (parsed == null) {
      setState(
        () => output = 'Use “from Kochi to Thrissur with 60% keep 20%”.',
      );
      return;
    }
    originName.text = parsed.origin;
    destinationName.text = parsed.destination;
    if (parsed.socPercent != null) soc.text = parsed.socPercent.toString();
    reserve.text = parsed.reservePercent.toString();
    setState(() => output = 'Review the parsed values before estimating.');
  }

  Future<void> run({bool road = false}) async {
    final battery = double.tryParse(capacity.text);
    final consumption = double.tryParse(efficiency.text);
    final departure = double.tryParse(soc.text);
    final minimum = double.tryParse(reserve.text);
    if (battery == null ||
        consumption == null ||
        departure == null ||
        minimum == null) {
      setState(
        () => output =
            'Enter battery capacity, consumption, departure charge and reserve.',
      );
      return;
    }
    EnergyEstimate estimate(double km, double startingSoc) => estimateJourney(
      distanceKm: km,
      batteryKwh: battery,
      whPerKm: consumption,
      departureSocPercent: startingSoc,
      reservePercent: minimum,
    );
    final name = [
      originName.text.trim(),
      destinationName.text.trim(),
    ].where((text) => text.isNotEmpty).join(' → ');
    final from = parseCoordinates(origin.text);
    final to = parseCoordinates(destination.text);
    final plug = connector.text.trim();
    setState(() {
      busy = true;
      output = '';
    });
    try {
      estimate(0, departure);
      final enteredDistance = double.tryParse(distance.text);
      RouteOption? route;
      final provider = OsrmRouting(client);
      if (road) {
        if (from == null || to == null) {
          throw const FormatException(
            'Enter origin and destination as latitude, longitude.',
          );
        }
        final routes = await provider.route(origin: from, destination: to);
        if (routes.isEmpty) throw const FormatException('No road route found.');
        route = routes.first;
      } else if (enteredDistance == null) {
        throw const FormatException(
          'Enter a distance for an offline estimate.',
        );
      }
      final km = route?.distanceKm ?? enteredDistance!;
      final direct = estimate(km, departure);
      final lines = <String>[
        if (name.isNotEmpty) name,
        '${km.toStringAsFixed(1)} km · ${direct.energyKwh.toStringAsFixed(2)} kWh',
        if (route != null)
          '${route.durationMinutes.round()} min driving · ${route.source}',
        if (direct.feasible)
          'Estimated arrival ${direct.arrivalSocPercent.toStringAsFixed(1)}% with a ${minimum.toStringAsFixed(0)}% reserve.',
        if (!direct.feasible) 'The direct journey falls below your reserve.',
      ];
      if (route != null &&
          from != null &&
          to != null &&
          !direct.feasible &&
          plug.isNotEmpty &&
          departure >= minimum) {
        final directory = OsmChargingStations(client);
        final available = await directory.corridor(route.points);
        final candidates = available
            .where(
              (station) =>
                  matchesConnector(station, plug) &&
                  estimate(
                    straightLineKm(from, station.point),
                    departure,
                  ).feasible &&
                  estimate(straightLineKm(station.point, to), 100).feasible,
            )
            .toList();
        candidates.sort(
          (a, b) => straightLineKm(
            from,
            b.point,
          ).compareTo(straightLineKm(from, a.point)),
        );
        (ChargingStation, RouteOption, double, double)? best;
        for (final station in candidates.take(5)) {
          final via = await provider.routeWithLegs([from, station.point, to]);
          if (via == null || via.$2.length != 2) continue;
          final arrival = estimate(via.$2.first, departure);
          final finalLeg = estimate(via.$2.last, 100);
          if (arrival.feasible &&
              finalLeg.feasible &&
              (best == null || via.$1.distanceKm < best.$2.distanceKm)) {
            best = (
              station,
              via.$1,
              arrival.arrivalSocPercent,
              100 - finalLeg.arrivalSocPercent + minimum,
            );
          }
        }
        if (best == null) {
          lines.add(
            'No feasible one-stop option found among the matched chargers checked.',
          );
        } else {
          lines.addAll([
            'Potential stop: ${best.$1.name}',
            'Arrive at ${best.$3.toStringAsFixed(1)}%. Recharge to at least ${best.$4.ceil()}%.',
            '${best.$2.distanceKm.toStringAsFixed(1)} km via charger. Confirm access and working status with the operator.',
          ]);
        }
      } else if (route != null && !direct.feasible && plug.isEmpty) {
        lines.add('Enter a connector to check possible stops.');
      }
      lines.add(
        'Range estimate based on the consumption you entered. Allow for traffic, weather and terrain.',
      );
      if (mounted) setState(() => output = lines.join('\n'));
    } on FormatException catch (failure) {
      if (mounted) setState(() => output = failure.message);
    } on ArgumentError {
      if (mounted) {
        setState(
          () => output =
              'Use finite measurements, a positive battery capacity and percentages from 0 to 100.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => output =
              'Could not contact the route or charging provider. Try an offline estimate.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Plan trip', style: Theme.of(context).textTheme.headlineMedium),
      VehicleLogButton(
        store: widget.store,
        category: RecordCategory.trip,
        label: 'Trip logs',
      ),
      FutureBuilder<List<EvVehicle>>(
        future: vehicles,
        builder: (context, snapshot) {
          final active =
              snapshot.data?.where((vehicle) => !vehicle.archived).toList() ??
              [];
          if (active.isEmpty) return const SizedBox.shrink();
          return DropdownButtonFormField<EvVehicle>(
            decoration: const InputDecoration(labelText: 'Use garage vehicle'),
            items: [
              for (final vehicle in active)
                DropdownMenuItem(
                  value: vehicle,
                  child: Text(vehicleName(vehicle)),
                ),
            ],
            onChanged: busy
                ? null
                : (vehicle) {
                    if (vehicle == null) return;
                    capacity.text = vehicle.batteryKwh.toString();
                    connector.text = vehicle.connector;
                  },
          );
        },
      ),
      editorField(prompt, 'Trip prompt'),
      OutlinedButton(
        onPressed: busy ? null : readPrompt,
        child: const Text('Fill trip details from prompt'),
      ),
      editorField(originName, 'Origin name'),
      editorField(destinationName, 'Destination name'),
      editorField(distance, 'Manual distance (km)', numeric: true),
      editorField(capacity, 'Usable battery (kWh)', numeric: true),
      editorField(efficiency, 'Consumption (Wh/km)', numeric: true),
      editorField(soc, 'Departure battery (%)', numeric: true),
      editorField(reserve, 'Minimum reserve (%)', numeric: true),
      FilledButton(
        onPressed: busy ? null : run,
        child: const Text('Estimate manually'),
      ),
      if (OsrmRouting.endpoint.isNotEmpty) ...[
        editorField(origin, 'Origin latitude, longitude'),
        editorField(destination, 'Destination latitude, longitude'),
        editorField(connector, 'Charger connector (e.g. CCS2)'),
        const Text(
          'Road planning sends coordinates to the configured routing service and charger directory. Driving routes can include roads unsuitable for scooters.',
        ),
        OutlinedButton(
          onPressed: busy ? null : () => run(road: true),
          child: const Text('Check road route'),
        ),
      ],
      if (busy) const LinearProgressIndicator(),
      if (output.isNotEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(output),
          ),
        ),
    ],
  );
}
