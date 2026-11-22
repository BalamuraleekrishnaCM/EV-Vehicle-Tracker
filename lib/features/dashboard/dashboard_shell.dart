import 'package:flutter/material.dart';
import '../../data/local_store.dart';
import '../../domain/vehicle.dart';
import '../../ui/ev_theme.dart';
import '../../ui/widgets/ev_widgets.dart';
import '../charging/charging_page.dart';
import '../garage/garage_screen.dart';
import '../ownership/ownership_overview.dart';
import '../trips/trip_planner_page.dart';

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
      OverviewPage(
        store: widget.store,
        onSelect: (i) => setState(() => selected = i),
      ),
      GarageScreen(store: widget.store),
      ChargingPage(store: widget.store),
      TripPlannerPage(store: widget.store),
      OwnershipOverview(store: widget.store),
    ];
    return Scaffold(
      body: SafeArea(child: pages[selected]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.electric_scooter_outlined),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            label: 'Charge',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            label: 'Ownership',
          ),
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
  void initState() {
    super.initState();
    vehicles = widget.store.vehicles();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      setState(() => vehicles = widget.store.vehicles());
      await vehicles;
    },
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'EV Vehicle Tracker',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: EvPalette.deepGreen,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your electric journey',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<EvVehicle>>(
          future: vehicles,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const EvEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load vehicles',
                message: 'Check local storage and try again.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data!
                .where((vehicle) => !vehicle.archived)
                .toList();
            if (all.isEmpty) {
              return EvEmptyState(
                icon: Icons.electric_car,
                title: 'Your garage is empty',
                message:
                    'Add a car or scooter to start recording ownership costs and trips.',
                action: FilledButton(
                  onPressed: () => widget.onSelect(1),
                  child: const Text('Open garage'),
                ),
              );
            }
            final v = all.first;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${v.brand} ${v.model}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${v.type.name.toUpperCase()} · ${v.batteryKwh} kWh battery',
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 8),
                    Text(
                      '${v.odometerKm.toStringAsFixed(0)} km',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text('Recorded odometer'),
                  ],
                ),
              ),
            );
          },
        ),
        const EvSectionTitle('Quick actions'),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                Icons.ev_station_outlined,
                'Find charge',
                () => widget.onSelect(2),
              ),
            ),
            Expanded(
              child: _QuickAction(
                Icons.route,
                'Plan trip',
                () => widget.onSelect(3),
              ),
            ),
            Expanded(
              child: _QuickAction(
                Icons.electric_scooter,
                'My garage',
                () => widget.onSelect(1),
              ),
            ),
          ],
        ),
        const EvSectionTitle('Privacy first'),
        const EvEmptyState(
          icon: Icons.shield_outlined,
          title: 'Local by default',
          message:
              'Vehicle records stay on your device. Live data requires an optional supported provider.',
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, color: EvPalette.deepGreen),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
