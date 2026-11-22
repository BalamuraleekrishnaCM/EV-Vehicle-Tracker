import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import '../../domain/ownership_record.dart';
import '../../domain/vehicle.dart';
import 'record_editor.dart';

String vehicleName(EvVehicle vehicle) => [
  vehicle.brand,
  vehicle.model,
  vehicle.variant,
].where((part) => part.isNotEmpty).join(' ');

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key, required this.store});
  final LocalStore store;

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late Future<List<EvVehicle>> vehicles = widget.store.vehicles();

  void refresh() => setState(() => vehicles = widget.store.vehicles());

  Future<void> edit([EvVehicle? vehicle]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleEditor(store: widget.store, vehicle: vehicle),
      ),
    );
    if (mounted && saved == true) refresh();
  }

  Future<void> manage(String action, EvVehicle vehicle) async {
    if (action == 'Edit') {
      await edit(vehicle);
      return;
    }
    if (action == 'Delete') {
      if (!await confirmAction(
        context,
        'Delete vehicle?',
        'This also deletes all its local records.',
      )) {
        return;
      }
    }
    try {
      if (action == 'Delete') {
        await widget.store.deleteVehicle(vehicle.id!);
      } else {
        await widget.store.archiveVehicle(vehicle.id!, !vehicle.archived);
      }
      if (mounted) refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update this vehicle.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Garage')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: edit,
      icon: const Icon(Icons.add),
      label: const Text('Add EV'),
    ),
    body: FutureBuilder<List<EvVehicle>>(
      future: vehicles,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: refresh,
              child: const Text('Could not load garage. Retry'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            if (snapshot.data!.isEmpty)
              const ListTile(
                title: Text('Add your first electric car or scooter'),
              ),
            for (final vehicle in snapshot.data!)
              Card(
                child: ListTile(
                  leading: Icon(
                    vehicle.type == VehicleType.car
                        ? Icons.directions_car
                        : Icons.two_wheeler,
                  ),
                  title: Text(vehicleName(vehicle)),
                  subtitle: Text(
                    '${vehicle.batteryKwh} kWh · ${vehicle.odometerKm} km${vehicle.archived ? ' · Archived' : ''}',
                  ),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleRecordsScreen(
                        store: widget.store,
                        vehicle: vehicle,
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => manage(action, vehicle),
                    itemBuilder: (_) => [
                      for (final action in [
                        'Edit',
                        vehicle.archived ? 'Unarchive' : 'Archive',
                        'Delete',
                      ])
                        PopupMenuItem(value: action, child: Text(action)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class VehicleEditor extends StatefulWidget {
  const VehicleEditor({super.key, required this.store, this.vehicle});
  final LocalStore store;
  final EvVehicle? vehicle;

  @override
  State<VehicleEditor> createState() => _VehicleEditorState();
}

class _VehicleEditorState extends State<VehicleEditor> {
  late var type = widget.vehicle?.type ?? VehicleType.scooter;
  late final brand = TextEditingController(text: widget.vehicle?.brand);
  late final model = TextEditingController(text: widget.vehicle?.model);
  late final variant = TextEditingController(text: widget.vehicle?.variant);
  late final connector = TextEditingController(text: widget.vehicle?.connector);
  late final battery = TextEditingController(
    text: widget.vehicle?.batteryKwh.toString(),
  );
  late final odometer = TextEditingController(
    text: (widget.vehicle?.odometerKm ?? 0).toString(),
  );
  bool saving = false;
  String? error;

  @override
  void dispose() {
    for (final field in [brand, model, variant, connector, battery, odometer]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final vehicle = EvVehicle(
      id: widget.vehicle?.id,
      type: type,
      brand: brand.text.trim(),
      model: model.text.trim(),
      variant: variant.text.trim(),
      connector: connector.text.trim(),
      batteryKwh: double.tryParse(battery.text) ?? double.nan,
      odometerKm: double.tryParse(odometer.text) ?? double.nan,
      archived: widget.vehicle?.archived ?? false,
    );
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (vehicle.id == null) {
        await widget.store.addVehicle(vehicle);
      } else {
        await widget.store.updateVehicle(vehicle);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          saving = false;
          error = failure is FormatException
              ? failure.message
              : 'Could not save vehicle.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.vehicle == null ? 'Add EV' : 'Edit vehicle'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<VehicleType>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Vehicle type'),
          items: VehicleType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.name)),
              )
              .toList(),
          onChanged: saving
              ? null
              : (value) => setState(() => type = value ?? type),
        ),
        editorField(brand, 'Brand'),
        editorField(model, 'Model'),
        editorField(variant, 'Variant (optional)'),
        editorField(battery, 'Usable battery capacity (kWh)', numeric: true),
        editorField(odometer, 'Odometer (km)', numeric: true),
        editorField(connector, 'Connector (optional, e.g. Type 2 or CCS2)'),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}

class VehicleRecordsScreen extends StatefulWidget {
  const VehicleRecordsScreen({
    super.key,
    required this.store,
    required this.vehicle,
    this.category,
  });
  final LocalStore store;
  final EvVehicle vehicle;
  final RecordCategory? category;

  @override
  State<VehicleRecordsScreen> createState() => _VehicleRecordsScreenState();
}

class _VehicleRecordsScreenState extends State<VehicleRecordsScreen> {
  late Future<List<OwnershipRecord>> records = widget.store.recordsFor(
    widget.vehicle.id!,
  );
  void refresh() =>
      setState(() => records = widget.store.recordsFor(widget.vehicle.id!));

  Future<void> edit([OwnershipRecord? record]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RecordEditor(
          store: widget.store,
          vehicle: widget.vehicle,
          initialCategory: widget.category,
          record: record,
        ),
      ),
    );
    if (mounted && saved == true) refresh();
  }

  Future<void> delete(OwnershipRecord record) async {
    if (!await confirmAction(context, 'Delete record?', record.title)) return;
    try {
      await widget.store.deleteRecord(record.id!, record.vehicleId);
      if (mounted) refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete record.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(vehicleName(widget.vehicle))),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: edit,
      icon: const Icon(Icons.add),
      label: const Text('Add record'),
    ),
    body: FutureBuilder<List<OwnershipRecord>>(
      future: records,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: refresh,
              child: const Text('Could not load records. Retry'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final visible = snapshot.data!.where(
          (record) =>
              widget.category == null || record.category == widget.category,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          children: [
            if (visible.isEmpty) const ListTile(title: Text('No entries yet')),
            for (final record in visible)
              Card(
                child: ListTile(
                  title: Text(record.title),
                  subtitle: Text(
                    [
                      categoryLabel(record.category),
                      dateLabel(record.createdAt),
                      if (record.detail.isNotEmpty) record.detail,
                      if (record.amountMinor > 0)
                        '${money(record.amountMinor)}${record.paid ? '' : ' due'}',
                      if (record.energyKwh != null) '${record.energyKwh} kWh',
                      if (record.distanceKm != null) '${record.distanceKm} km',
                      if (record.whPerKm != null)
                        '${record.whPerKm!.toStringAsFixed(1)} Wh/km',
                      if (record.dueDate != null)
                        'Due ${dateLabel(record.dueDate!)}',
                    ].join(' · '),
                  ),
                  onTap: () => edit(record),
                  trailing: IconButton(
                    tooltip: 'Delete ${record.title}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => delete(record),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
