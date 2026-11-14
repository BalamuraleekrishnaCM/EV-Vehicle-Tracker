import 'package:flutter/material.dart';
import '../../data/local_store.dart';
import '../../domain/vehicle.dart';
import '../../domain/energy_estimator.dart';
import '../../domain/trip_prompt.dart';
import '../../ui/ev_theme.dart';
import '../../ui/widgets/ev_widgets.dart';
import '../garage/garage_screen.dart';

/// Dashboard UI is data-safe: live charger status, SOC and health are never invented.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key, required this.store});
  final LocalStore store;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      OverviewPage(store: widget.store, onSelect: (i) => setState(() => selected = i)),
      GarageScreen(store: widget.store),
      const ChargingPage(),
      const TripPlannerPage(),
      const MorePage(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: selected, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.electric_scooter_outlined), label: 'Garage'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), label: 'Charge'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'More'),
        ],
      ),
    );
  }
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, required this.store, required this.onSelect});
  final LocalStore store;
  final ValueChanged<int> onSelect;
  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late Future<List<EvVehicle>> vehicles;
  @override
  void initState() { super.initState(); vehicles = widget.store.vehicles(); }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      setState(() => vehicles = widget.store.vehicles());
      await vehicles;
    },
    child: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('EV Vehicle Tracker', style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: EvPalette.deepGreen)),
      const SizedBox(height: 24),
      Text('Your electric journey', style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold)),
      const Text('Everything you need. Nothing you don’t.',
          style: TextStyle(color: EvPalette.secondary)),
      const SizedBox(height: 18),
      FutureBuilder<List<EvVehicle>>(
        future: vehicles,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const EvEmptyState(
            icon: Icons.error_outline, title: 'Could not load vehicles',
            message: 'Check local storage and try again.');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final all = snapshot.data!;
          if (all.isEmpty) return EvEmptyState(
            icon: Icons.electric_car, title: 'Your garage is empty',
            message: 'Add a car or scooter to start recording ownership costs and trips.',
            action: FilledButton(
              onPressed: () => widget.onSelect(1), child: const Text('Open garage')),
          );
          final v = all.first;
          return Card(child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${v.brand} ${v.model}', style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('${v.type.name.toUpperCase()} · ${v.batteryKwh} kWh battery'),
              const SizedBox(height: 20),
              const Text('Live battery status not connected',
                  style: TextStyle(color: EvPalette.secondary)),
              const SizedBox(height: 8),
              Text('${v.odometerKm.toStringAsFixed(0)} km',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Text('Recorded odometer'),
            ]),
          ));
        },
      ),
      const EvSectionTitle('Quick actions'),
      Row(children: [
        Expanded(child: _QuickAction(Icons.ev_station_outlined, 'Find charge',
            () => widget.onSelect(2))),
        Expanded(child: _QuickAction(Icons.route, 'Plan trip',
            () => widget.onSelect(3))),
        Expanded(child: _QuickAction(Icons.electric_scooter, 'My garage',
            () => widget.onSelect(1))),
      ]),
      const EvSectionTitle('Privacy first'),
      const EvEmptyState(icon: Icons.shield_outlined, title: 'Local by default',
        message: 'Vehicle records stay on your device. Live data requires an optional supported provider.'),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      child: Column(children: [
        Icon(icon, color: EvPalette.deepGreen),
        const SizedBox(height: 10),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ])),
  ));
}

class ChargingPage extends StatelessWidget {
  const ChargingPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('Charging', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Nearby and along your route', style: TextStyle(color: EvPalette.secondary)),
      SizedBox(height: 22),
      EvEmptyState(icon: Icons.ev_station_outlined, title: 'Station discovery coming soon',
        message: 'A live station directory, map, connector filters and location controls are planned. '
            'No charging locations or availability are shown without a verified provider.'),
      EvSectionTitle('Designed for EV owners'),
      EvMetricCard(label: 'Compatible plugs', value: 'AC / DC', icon: Icons.power,
        detail: 'Vehicle-specific filtering planned'),
      EvMetricCard(label: 'Charging reliability', value: 'Unknown', icon: Icons.info_outline,
        detail: 'Live status will be marked with a verification time'),
    ],
  );
}

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});
  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  final prompt = TextEditingController();
  final distance = TextEditingController();
  final capacity = TextEditingController();
  final efficiency = TextEditingController();
  final soc = TextEditingController();
  String output = '';

  @override
  void dispose() {
    prompt.dispose(); distance.dispose(); capacity.dispose();
    efficiency.dispose(); soc.dispose(); super.dispose();
  }

  void calculate() {
    final parsed = parseTripPrompt(prompt.text);
    final d = double.tryParse(distance.text);
    final b = double.tryParse(capacity.text);
    final e = double.tryParse(efficiency.text);
    final s = double.tryParse(soc.text) ?? parsed?.socPercent;
    if (d == null || b == null || e == null || s == null ||
        !d.isFinite || !b.isFinite || !e.isFinite || !s.isFinite) {
      setState(() => output = 'Enter valid distance, battery, efficiency and departure charge.');
      return;
    }
    try {
      final result = estimateJourney(
        distanceKm: d, batteryKwh: b, whPerKm: e,
        departureSocPercent: s, reservePercent: parsed?.reservePercent ?? 20);
      setState(() => output =
        'Estimated consumption: ${result.energyKwh.toStringAsFixed(2)} kWh\n'
        'Estimated arrival: ${result.arrivalSocPercent.toStringAsFixed(1)}%\n'
        '${result.feasible ? 'Above reserve' : 'Charging stop may be needed'}\n'
        'Not a navigation route. Confirm real-world range and charging.');
    } on ArgumentError {
      setState(() => output = 'Invalid trip inputs.');
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Plan trip', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Estimate energy before you travel',
        style: TextStyle(color: EvPalette.secondary)),
      const SizedBox(height: 18),
      TextField(controller: prompt, maxLines: 3, decoration: const InputDecoration(
        labelText: 'Describe your trip (optional)',
        hintText: 'from Kochi to Thrissur with 60% keep 20%')),
      const SizedBox(height: 10),
      TextField(controller: distance, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Distance (km)')),
      const SizedBox(height: 10),
      TextField(controller: capacity, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Usable battery capacity (kWh)')),
      const SizedBox(height: 10),
      TextField(controller: efficiency, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Consumption (Wh/km)')),
      const SizedBox(height: 10),
      TextField(controller: soc, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Departure battery %')),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: calculate, icon: const Icon(Icons.route),
        label: const Text('Estimate journey')),
      if (output.isNotEmpty) Card(child: Padding(
        padding: const EdgeInsets.all(18), child: Text(output))),
      const EvEmptyState(icon: Icons.info_outline, title: 'Conservative planning',
        message: 'Routing, terrain, traffic, charger selection and live station data '
          'will be added after provider integration and validation.'),
    ],
  );
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      Text('More', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      EvSectionTitle('Vehicle health'),
      EvEmptyState(icon: Icons.health_and_safety_outlined,
        title: 'Service and fault history',
        message: 'Structured maintenance, warranty, issue reports and battery trends are planned. '
          'A diagnostic health score is not shown without validated vehicle data.'),
      EvSectionTitle('Ownership insights'),
      EvEmptyState(icon: Icons.insights_outlined,
        title: 'Understand your running costs',
        message: 'Monthly spending, energy efficiency and total cost of ownership '
          'will use your recorded data, never sample values.'),
      EvSectionTitle('Community'),
      EvEmptyState(icon: Icons.groups_outlined,
        title: 'Open-source and community-driven',
        message: 'Community charger reports and vehicle integrations are planned '
          'as optional opt-in modules.'),
    ],
  );
}
