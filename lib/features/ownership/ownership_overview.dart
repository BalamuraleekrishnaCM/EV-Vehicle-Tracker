import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import '../../domain/ownership_record.dart';
import '../../domain/vehicle.dart';
import '../garage/garage_screen.dart';
import '../garage/record_editor.dart';

class OwnershipOverview extends StatefulWidget {
  const OwnershipOverview({super.key, required this.store});
  final LocalStore store;

  @override
  State<OwnershipOverview> createState() => _OwnershipOverviewState();
}

class _OwnershipOverviewState extends State<OwnershipOverview> {
  late Future<(List<EvVehicle>, List<OwnershipRecord>)> data = load();
  int? vehicleId;
  bool thisMonth = false;
  bool busy = false;

  Future<(List<EvVehicle>, List<OwnershipRecord>)> load() async =>
      widget.store.ownershipSnapshot();

  void refresh() => setState(() => data = load());

  Future<void> transfer({bool restore = false, bool csv = false}) async {
    setState(() => busy = true);
    try {
      if (restore) {
        final file = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
        );
        final bytes = file?.files.single.bytes;
        if (bytes == null || !mounted) return;
        if (!await confirmAction(
          context,
          'Replace local records?',
          'Restoring this backup replaces all vehicles and ownership records on this device.',
        )) {
          return;
        }
        await widget.store.restoreBackup(utf8.decode(bytes));
        if (mounted) {
          setState(() {
            vehicleId = null;
            data = load();
          });
          message('Backup restored.');
        }
      } else {
        final contents = csv
            ? await widget.store.exportCsv()
            : await widget.store.exportBackup();
        final path = await FilePicker.platform.saveFile(
          fileName: csv ? 'ev-ownership.csv' : 'ev-tracker-backup.json',
          bytes: Uint8List.fromList(utf8.encode(contents)),
        );
        if (path != null && mounted) message('File saved.');
      }
    } catch (failure) {
      if (mounted) {
        message(
          failure is FormatException
              ? failure.message
              : 'Could not complete file operation.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: data,
    builder: (context, snapshot) {
      final result = snapshot.data;
      if (result == null) {
        return Center(
          child: snapshot.hasError
              ? TextButton(
                  onPressed: refresh,
                  child: const Text('Could not load ownership data. Retry'),
                )
              : const CircularProgressIndicator(),
        );
      }
      final now = DateTime.now();
      final byId = {for (final vehicle in result.$1) vehicle.id!: vehicle};
      final filtered = result.$2.where(
        (record) => vehicleId == null || record.vehicleId == vehicleId,
      );
      final period = filtered.where((record) {
        final date = record.createdAt.toLocal();
        return !thisMonth || (date.year == now.year && date.month == now.month);
      });
      final totals = <RecordCategory, int>{};
      var distance = 0.0;
      var measuredDistance = 0.0;
      var tripEnergy = 0.0;
      var chargeEnergy = 0.0;
      for (final record in period) {
        if (record.paid) {
          totals.update(
            record.category,
            (value) => value + record.amountMinor,
            ifAbsent: () => record.amountMinor,
          );
        }
        if (record.category == RecordCategory.charging) {
          chargeEnergy += record.energyKwh ?? 0;
        }
        if (record.category == RecordCategory.trip) {
          distance += record.distanceKm ?? 0;
          if (record.whPerKm != null) {
            measuredDistance += record.distanceKm!;
            tripEnergy += record.energyKwh!;
          }
        }
      }
      final charging = totals[RecordCategory.charging] ?? 0;
      final reminders =
          filtered
              .where(
                (record) =>
                    record.dueDate != null &&
                    !(record.category == RecordCategory.finance && record.paid),
              )
              .toList()
            ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ownership', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey(vehicleId),
            initialValue: vehicleId ?? 0,
            decoration: const InputDecoration(labelText: 'Vehicle'),
            items: [
              const DropdownMenuItem(value: 0, child: Text('All vehicles')),
              for (final vehicle in result.$1)
                DropdownMenuItem(
                  value: vehicle.id,
                  child: Text(vehicleName(vehicle)),
                ),
            ],
            onChanged: (value) =>
                setState(() => vehicleId = value == 0 ? null : value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This month only'),
            value: thisMonth,
            onChanged: (value) => setState(() => thisMonth = value),
          ),
          Card(
            child: Column(
              children: [
                for (final entry in totals.entries.where(
                  (entry) => entry.value > 0,
                ))
                  ListTile(
                    title: Text(categoryLabel(entry.key)),
                    trailing: Text(money(entry.value)),
                  ),
                if (totals.values.every((value) => value == 0))
                  const ListTile(title: Text('No payments in this period')),
                ListTile(
                  title: const Text('Metered charging energy'),
                  trailing: Text('${chargeEnergy.toStringAsFixed(2)} kWh'),
                ),
                ListTile(
                  title: const Text('Logged trip distance'),
                  trailing: Text('${distance.toStringAsFixed(1)} km'),
                ),
                if (measuredDistance > 0)
                  ListTile(
                    title: const Text('Measured trip efficiency'),
                    trailing: Text(
                      '${(tripEnergy * 1000 / measuredDistance).toStringAsFixed(1)} Wh/km',
                    ),
                  ),
                if (distance > 0 && totals.containsKey(RecordCategory.charging))
                  ListTile(
                    title: const Text('Recorded charging spend / logged km'),
                    trailing: Text(
                      '₹${(charging / 100 / distance).toStringAsFixed(2)}',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Due dates', style: Theme.of(context).textTheme.titleLarge),
          if (reminders.isEmpty)
            const ListTile(title: Text('No recorded due dates')),
          for (final record in reminders)
            ListTile(
              title: Text(record.title),
              subtitle: Text(
                '${vehicleName(byId[record.vehicleId]!)} · ${dateLabel(record.dueDate!)}',
              ),
              trailing: dateLabel(record.dueDate!).compareTo(dateLabel(now)) < 0
                  ? const Text('Overdue')
                  : null,
              onTap: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecordEditor(
                      store: widget.store,
                      vehicle: byId[record.vehicleId]!,
                      record: record,
                    ),
                  ),
                );
                if (mounted && saved == true) refresh();
              },
            ),
          const SizedBox(height: 12),
          Text(
            'Backup and export',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ListTile(
            enabled: !busy,
            leading: const Icon(Icons.save_alt),
            title: const Text('Save JSON backup'),
            onTap: () => transfer(),
          ),
          ListTile(
            enabled: !busy,
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('Export records to CSV'),
            onTap: () => transfer(csv: true),
          ),
          ListTile(
            enabled: !busy,
            leading: const Icon(Icons.restore),
            title: const Text('Restore JSON backup'),
            onTap: () => transfer(restore: true),
          ),
        ],
      );
    },
  );
}
