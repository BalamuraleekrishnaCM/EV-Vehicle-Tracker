import 'package:flutter/material.dart';
import '../../data/local_store.dart';
import '../../domain/vehicle.dart';
import '../../domain/ownership_record.dart';
import '../../domain/energy_estimator.dart';
import '../../domain/trip_prompt.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key, required this.store});
  final LocalStore store;
  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  List<EvVehicle> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final vehicles = await widget.store.vehicles();
    if (mounted) setState(() { _vehicles = vehicles; _loading = false; });
  }

  Future<void> _addVehicle() async {
    final brand = TextEditingController();
    final model = TextEditingController();
    final capacity = TextEditingController();
    var type = VehicleType.scooter;
    final result = await showDialog<EvVehicle>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add electric vehicle'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<VehicleType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Vehicle type'),
                items: VehicleType.values.map((value) => DropdownMenuItem(
                  value: value, child: Text(value.name))).toList(),
                onChanged: (value) => setDialogState(() => type = value ?? type),
              ),
              TextField(controller: brand, decoration: const InputDecoration(labelText: 'Brand')),
              TextField(controller: model, decoration: const InputDecoration(labelText: 'Model')),
              TextField(controller: capacity, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Battery capacity (kWh)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final kwh = double.tryParse(capacity.text.trim());
              if (brand.text.trim().isEmpty || model.text.trim().isEmpty ||
                  kwh == null || !kwh.isFinite || kwh <= 0) return;
              Navigator.pop(context, EvVehicle(type: type, brand: brand.text.trim(),
                model: model.text.trim(), batteryKwh: kwh));
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
    brand.dispose();
    model.dispose();
    capacity.dispose();
    if (result == null) return;
    await widget.store.addVehicle(result);
    await _refresh();
  }

  void _openVehicle(EvVehicle vehicle) {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => VehicleRecordsScreen(vehicle: vehicle, store: widget.store),
    ));
  }

  void _openTripPlanner() {
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => const TripEstimateScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('EV Vehicle Tracker')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _addVehicle, icon: const Icon(Icons.add), label: const Text('Add EV')),
    body: _loading ? const Center(child: CircularProgressIndicator()) :
      ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: ListTile(
          leading: const Icon(Icons.route),
          title: const Text('Trip energy estimator'),
          subtitle: const Text('Offline estimate; no live charging stations yet'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openTripPlanner,
        )),
        const SizedBox(height: 8),
        if (_vehicles.isEmpty)
          const Padding(padding: EdgeInsets.all(24), child: Text('No EVs yet. Add an electric car or scooter.')),
        for (final vehicle in _vehicles)
          Card(child: ListTile(
            leading: Icon(vehicle.type == VehicleType.car ? Icons.directions_car : Icons.two_wheeler),
            title: Text('${vehicle.brand} ${vehicle.model}'),
            subtitle: Text('${vehicle.batteryKwh} kWh · ${vehicle.type.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openVehicle(vehicle),
          )),
      ]),
  );
}

class VehicleRecordsScreen extends StatefulWidget {
  const VehicleRecordsScreen({super.key, required this.vehicle, required this.store});
  final EvVehicle vehicle;
  final LocalStore store;
  @override
  State<VehicleRecordsScreen> createState() => _VehicleRecordsScreenState();
}

class _VehicleRecordsScreenState extends State<VehicleRecordsScreen> {
  List<OwnershipRecord> _records = [];

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    final items = await widget.store.recordsFor(widget.vehicle.id!);
    if (mounted) setState(() => _records = items);
  }

  Future<void> _addRecord() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    var category = RecordCategory.charging;
    final result = await showDialog<OwnershipRecord>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add ownership record'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<RecordCategory>(
              initialValue: category,
              items: RecordCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (value) => setDialogState(() => category = value ?? category),
            ),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (₹)')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () {
              final parsed = double.tryParse(amount.text.trim().isEmpty ? '0' : amount.text.trim());
              if (title.text.trim().isEmpty || parsed == null || !parsed.isFinite || parsed < 0) return;
              Navigator.pop(context, OwnershipRecord(
                vehicleId: widget.vehicle.id!, category: category,
                title: title.text.trim(), amountMinor: (parsed * 100).round(),
                createdAt: DateTime.now(), notes: notes.text.trim(),
              ));
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
    title.dispose(); amount.dispose(); notes.dispose();
    if (result != null) {
      await widget.store.addRecord(result);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sum = _records.fold<int>(0, (total, item) => total + item.amountMinor);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.vehicle.brand} ${widget.vehicle.model}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord, icon: const Icon(Icons.add), label: const Text('Add record')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: ListTile(title: const Text('Recorded costs'),
          subtitle: Text('₹${(sum / 100).toStringAsFixed(2)} · ${_records.length} entries'))),
        for (final record in _records)
          Card(child: ListTile(
            title: Text(record.title),
            subtitle: Text('${record.category.name} · ${record.createdAt.toLocal().toString().split(' ').first}'),
            trailing: Text('₹${(record.amountMinor / 100).toStringAsFixed(2)}'),
          )),
      ]),
    );
  }
}

class TripEstimateScreen extends StatefulWidget {
  const TripEstimateScreen({super.key});
  @override
  State<TripEstimateScreen> createState() => _TripEstimateScreenState();
}

class _TripEstimateScreenState extends State<TripEstimateScreen> {
  final prompt = TextEditingController();
  final distance = TextEditingController();
  final battery = TextEditingController();
  final efficiency = TextEditingController();
  final charge = TextEditingController();
  String feedback = '';

  @override
  void dispose() {
    prompt.dispose(); distance.dispose(); battery.dispose();
    efficiency.dispose(); charge.dispose(); super.dispose();
  }

  void _estimate() {
    final parsed = parseTripPrompt(prompt.text);
    final km = double.tryParse(distance.text);
    final kwh = double.tryParse(battery.text);
    final wh = double.tryParse(efficiency.text);
    final soc = double.tryParse(charge.text) ?? parsed?.socPercent;
    if (km == null || kwh == null || wh == null || soc == null ||
        !km.isFinite || !kwh.isFinite || !wh.isFinite || !soc.isFinite) {
      setState(() => feedback = 'Enter valid distance, battery, efficiency and charge values.');
      return;
    }
    try {
      final result = estimateJourney(distanceKm: km, batteryKwh: kwh,
        whPerKm: wh, departureSocPercent: soc,
        reservePercent: parsed?.reservePercent ?? 20);
      setState(() => feedback = '${parsed == null ? 'Manual estimate' : '${parsed.origin} → ${parsed.destination}'}\n'
        'Energy: ${result.energyKwh.toStringAsFixed(2)} kWh\n'
        'Arrival SOC: ${result.arrivalSocPercent.toStringAsFixed(1)}%\n'
        '${result.feasible ? 'Within selected reserve' : 'Below reserve: charging stop needed'}\n'
        'Estimate only; no routing, terrain or charger verification.');
    } on ArgumentError {
      setState(() => feedback = 'Invalid values. Check battery, range and reserve.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trip energy estimator')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: prompt, decoration: const InputDecoration(
        labelText: 'Optional prompt', hintText: 'from Kochi to Thrissur with 60% keep 20%')),
      TextField(controller: distance, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Route distance (km)')),
      TextField(controller: battery, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Usable battery capacity (kWh)')),
      TextField(controller: efficiency, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Observed efficiency (Wh/km)')),
      TextField(controller: charge, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Departure charge % (optional if prompt includes it)')),
      const SizedBox(height: 16),
      FilledButton(onPressed: _estimate, child: const Text('Estimate')),
      if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16),
        child: Text(feedback)),
    ]),
  );
}
