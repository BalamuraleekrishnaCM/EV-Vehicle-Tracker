import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import '../../domain/ownership_record.dart';
import '../garage/garage_screen.dart';

class VehicleLogButton extends StatelessWidget {
  const VehicleLogButton({
    super.key,
    required this.store,
    required this.category,
    required this.label,
  });
  final LocalStore store;
  final RecordCategory category;
  final String label;

  Future<void> open(BuildContext context) async {
    try {
      final vehicles = await store.vehicles();
      if (!context.mounted) return;
      if (vehicles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a vehicle in Garage first.')),
        );
        return;
      }
      final vehicle = vehicles.length == 1
          ? vehicles.first
          : await showDialog(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Choose vehicle'),
                children: [
                  for (final vehicle in vehicles)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, vehicle),
                      child: Text(vehicleName(vehicle)),
                    ),
                ],
              ),
            );
      if (vehicle == null || !context.mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => VehicleRecordsScreen(
            vehicle: vehicle,
            store: store,
            category: category,
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open logs.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => open(context),
    icon: const Icon(Icons.list_alt),
    label: Text(label),
  );
}
