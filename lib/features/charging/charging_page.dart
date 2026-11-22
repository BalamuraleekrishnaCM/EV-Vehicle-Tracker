import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local_store.dart';
import '../../data/map_providers.dart';
import '../../domain/charging_station.dart';
import '../../domain/ownership_record.dart';
import '../../domain/routing_provider.dart';
import '../garage/record_editor.dart';
import '../ownership/vehicle_log_button.dart';

class ChargingPage extends StatefulWidget {
  const ChargingPage({super.key, required this.store});
  final LocalStore store;

  @override
  State<ChargingPage> createState() => _ChargingPageState();
}

class _ChargingPageState extends State<ChargingPage> {
  final coordinates = TextEditingController();
  final connector = TextEditingController();
  final radius = TextEditingController(text: '20');
  final client = http.Client();
  var stations = <ChargingStation>[];
  var favorites = <String>{};
  DateTime? fetchedAt;
  bool busy = false;
  bool savedOnly = false;
  String? message;

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('charger_search');
      final restored = cached == null ? null : jsonDecode(cached) as Map;
      if (!mounted) return;
      setState(() {
        favorites = (prefs.getStringList('charger_favorites') ?? []).toSet();
        if (restored != null && fetchedAt == null && !busy) {
          fetchedAt = DateTime.parse(restored['at'] as String);
          stations = [
            for (final raw in restored['stations'] as List)
              ChargingStation(
                id: raw['id'] as String,
                name: raw['name'] as String,
                latitude: (raw['lat'] as num).toDouble(),
                longitude: (raw['lon'] as num).toDouble(),
                connectorTypes: List<String>.from(raw['connectors'] as List),
              ),
          ];
        }
      });
    } catch (_) {
      if (mounted) setState(() => message = 'Could not read saved chargers.');
    }
  }

  Future<void> search({bool useGps = false}) async {
    final distance = double.tryParse(radius.text);
    if (distance == null ||
        !distance.isFinite ||
        distance < 1 ||
        distance > 50) {
      setState(() => message = 'Enter a radius between 1 and 50 km.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
      savedOnly = false;
    });
    try {
      GeoPoint? point = parseCoordinates(coordinates.text);
      if (useGps) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw const FormatException(
            'Location permission is unavailable. Enter coordinates to search manually.',
          );
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            timeLimit: Duration(seconds: 12),
          ),
        );
        point = GeoPoint(position.latitude, position.longitude);
        if (mounted) {
          coordinates.text =
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        }
      }
      if (point == null) {
        throw const FormatException(
          'Enter latitude and longitude separated by a comma.',
        );
      }
      final searchPoint = point;
      final results = await OsmChargingStations(client).nearby(
        latitude: point.latitude,
        longitude: point.longitude,
        radiusKm: distance,
      );
      results.sort(
        (a, b) => straightLineKm(
          searchPoint,
          a.point,
        ).compareTo(straightLineKm(searchPoint, b.point)),
      );
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        stations = results;
        fetchedAt = now;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'charger_search',
        jsonEncode({
          'at': now.toIso8601String(),
          'stations': [
            for (final station in results)
              {
                'id': station.id,
                'name': station.name,
                'lat': station.latitude,
                'lon': station.longitude,
                'connectors': station.connectorTypes,
              },
          ],
        }),
      );
    } catch (failure) {
      if (mounted) {
        setState(
          () => message = failure is FormatException
              ? failure.message
              : 'Search failed. Check location services or your internet connection.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> favorite(ChargingStation station) async {
    final next = {...favorites};
    if (!next.add(station.id)) next.remove(station.id);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await prefs.setStringList('charger_favorites', next.toList()) &&
          mounted) {
        setState(() => favorites = next);
      }
    } catch (_) {
      if (mounted) setState(() => message = 'Could not save favorite.');
    }
  }

  @override
  void dispose() {
    coordinates.dispose();
    connector.dispose();
    radius.dispose();
    client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = connector.text.trim();
    final visible = stations.where(
      (station) =>
          (!savedOnly || favorites.contains(station.id)) &&
          (query.isEmpty || matchesConnector(station, query)),
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Charging', style: Theme.of(context).textTheme.headlineMedium),
        VehicleLogButton(
          store: widget.store,
          category: RecordCategory.charging,
          label: 'Charging logs',
        ),
        editorField(coordinates, 'Latitude, longitude'),
        editorField(radius, 'Search radius (km)', numeric: true),
        TextField(
          controller: connector,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Connector filter (optional)',
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: busy ? null : search,
              child: const Text('Find chargers'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => search(useGps: true),
              icon: const Icon(Icons.my_location),
              label: const Text('Use my location'),
            ),
          ],
        ),
        const Text(
          'Search sends coordinates to the directory. Charger status and scooter access must be confirmed with the operator.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (message != null) Text(message!),
        if (fetchedAt != null) ...[
          Text(
            'OpenStreetMap contributors · Directory retrieved ${fetchedAt!.toLocal().toString().split('.').first}',
          ),
          SwitchListTile(
            title: const Text('Favorites in these results'),
            value: savedOnly,
            onChanged: (value) => setState(() => savedOnly = value),
          ),
          if (visible.isEmpty)
            const ListTile(title: Text('No matching mapped chargers')),
          for (final station in visible)
            Card(
              child: ListTile(
                title: Text(station.name),
                subtitle: Text(
                  station.connectorTypes.isEmpty
                      ? 'Connector unknown'
                      : station.connectorTypes.join(', '),
                ),
                onTap: () async {
                  try {
                    final opened = await launchUrl(
                      Uri.https('www.openstreetmap.org', '/', {
                        'mlat': '${station.latitude}',
                        'mlon': '${station.longitude}',
                      }).replace(
                        fragment:
                            'map=17/${station.latitude}/${station.longitude}',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                    if (opened) return;
                  } catch (_) {}
                  if (mounted) {
                    setState(() => message = 'Could not open the station map.');
                  }
                },
                trailing: IconButton(
                  tooltip: favorites.contains(station.id)
                      ? 'Remove favorite'
                      : 'Save favorite',
                  onPressed: () => favorite(station),
                  icon: Icon(
                    favorites.contains(station.id)
                        ? Icons.star
                        : Icons.star_outline,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
