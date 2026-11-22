import 'package:flutter/material.dart';

import '../../data/local_store.dart';
import '../../domain/ownership_record.dart';
import '../../domain/vehicle.dart';

String money(int minor) => '₹${(minor / 100).toStringAsFixed(2)}';
String dateLabel(DateTime date) =>
    date.toLocal().toIso8601String().split('T').first;

String categoryLabel(RecordCategory category) => switch (category) {
  RecordCategory.charging => 'Charging',
  RecordCategory.trip => 'Trip',
  RecordCategory.expense => 'Expense',
  RecordCategory.service => 'Service',
  RecordCategory.finance => 'Finance / EMI',
  RecordCategory.issue => 'Fault / issue',
  RecordCategory.purchase => 'Purchase',
  RecordCategory.insurance => 'Insurance',
  RecordCategory.warranty => 'Warranty',
  RecordCategory.document => 'Document reference',
};

Widget editorField(
  TextEditingController controller,
  String label, {
  bool numeric = false,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 5),
  child: TextField(
    controller: controller,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : null,
    decoration: InputDecoration(labelText: label),
  ),
);

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.store,
    required this.vehicle,
    this.initialCategory,
    this.record,
  });
  final LocalStore store;
  final EvVehicle vehicle;
  final RecordCategory? initialCategory;
  final OwnershipRecord? record;

  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  late var category =
      widget.record?.category ??
      widget.initialCategory ??
      RecordCategory.charging;
  late var date = widget.record?.createdAt.toLocal() ?? DateTime.now();
  late var due = widget.record?.dueDate?.toLocal();
  late var paid = widget.record?.paid ?? true;
  late final title = TextEditingController(text: widget.record?.title);
  late final amount = TextEditingController(
    text: widget.record == null
        ? null
        : (widget.record!.amountMinor / 100).toStringAsFixed(2),
  );
  late final detail = TextEditingController(text: widget.record?.detail);
  late final notes = TextEditingController(text: widget.record?.notes);
  late final odometer = TextEditingController(
    text: widget.record?.odometerKm?.toString(),
  );
  late final energy = TextEditingController(
    text: widget.record?.energyKwh?.toString(),
  );
  late final distance = TextEditingController(
    text: widget.record?.distanceKm?.toString(),
  );
  late final start = TextEditingController(
    text: widget.record?.startSoc?.toString(),
  );
  late final end = TextEditingController(
    text: widget.record?.endSoc?.toString(),
  );
  late final tariff = TextEditingController(
    text: widget.record?.tariff?.toString(),
  );
  late final minutes = TextEditingController(
    text: widget.record?.minutes?.toString(),
  );
  final installments = TextEditingController();
  late final fields = [
    installments,
    title,
    amount,
    detail,
    notes,
    odometer,
    energy,
    distance,
    start,
    end,
    tariff,
    minutes,
  ];
  bool get isCharge => category == RecordCategory.charging;
  bool get isTrip => category == RecordCategory.trip;
  bool saving = false;
  String? error;

  double? number(TextEditingController field) => field.text.trim().isEmpty
      ? null
      : double.tryParse(field.text) ?? double.nan;

  @override
  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> chooseDate({bool deadline = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (deadline ? due : date) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (deadline) {
        due = picked;
      } else {
        date = picked;
      }
    });
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final measured = isCharge || isTrip ? number(energy) : null;
      final rate = isCharge ? number(tariff) : null;
      final price =
          number(amount) ??
          (measured != null && rate != null ? measured * rate : 0);
      if (!price.isFinite || price < 0 || price > 1000000000000) {
        throw const FormatException('Enter a nonnegative amount in rupees.');
      }
      final record = OwnershipRecord(
        id: widget.record?.id,
        vehicleId: widget.vehicle.id!,
        category: category,
        title: title.text.trim(),
        createdAt: date,
        dueDate: due,
        paid: paid,
        amountMinor: (price * 100).round(),
        odometerKm: number(odometer),
        detail: detail.text.trim(),
        notes: notes.text.trim(),
        energyKwh: measured,
        distanceKm: isTrip ? number(distance) : null,
        startSoc: isCharge ? number(start) : null,
        endSoc: isCharge ? number(end) : null,
        tariff: rate,
        minutes: isCharge ? number(minutes) : null,
      );
      if (record.id == null) {
        final count =
            category == RecordCategory.finance &&
                installments.text.trim().isNotEmpty
            ? int.tryParse(installments.text.trim()) ?? 0
            : 1;
        if (count == 1) {
          await widget.store.addRecord(record);
        } else {
          await widget.store.addInstallments(record, count);
        }
      } else {
        await widget.store.updateRecord(record);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (failure) {
      if (mounted) {
        setState(() {
          saving = false;
          error = failure is FormatException
              ? failure.message
              : 'Could not save record.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.record == null ? 'Add record' : 'Edit record'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<RecordCategory>(
          initialValue: category,
          decoration: const InputDecoration(labelText: 'Category'),
          items:
              (widget.initialCategory == null
                      ? RecordCategory.values
                      : [widget.initialCategory!])
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(categoryLabel(option)),
                    ),
                  )
                  .toList(),
          onChanged: saving
              ? null
              : (value) => setState(() => category = value ?? category),
        ),
        editorField(title, 'Title'),
        editorField(detail, switch (category) {
          RecordCategory.charging => 'Location / home or public / AC or DC',
          RecordCategory.document => 'Reference, issuer or file location',
          RecordCategory.finance => 'Lender / installment reference',
          _ => 'Details (optional)',
        }),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Record date · ${dateLabel(date)}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: chooseDate,
        ),
        if (isCharge || isTrip)
          editorField(energy, 'Measured energy (kWh)', numeric: true),
        if (isTrip) editorField(distance, 'Distance (km)', numeric: true),
        if (isCharge) ...[
          editorField(start, 'Start charge (%)', numeric: true),
          editorField(end, 'End charge (%)', numeric: true),
          editorField(tariff, 'Tariff (₹/kWh)', numeric: true),
          editorField(minutes, 'Duration (minutes)', numeric: true),
        ],
        editorField(
          amount,
          isCharge
              ? 'Amount (₹), auto if blank with energy and tariff'
              : 'Amount (₹)',
          numeric: true,
        ),
        if (category == RecordCategory.finance && widget.record == null)
          editorField(
            installments,
            'Monthly installments (optional)',
            numeric: true,
          ),
        editorField(odometer, 'Odometer (km)', numeric: true),
        editorField(notes, 'Notes'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            due == null
                ? 'Set a due or expiry date'
                : 'Due · ${dateLabel(due!)}',
          ),
          onTap: () => chooseDate(deadline: true),
          trailing: due == null
              ? const Icon(Icons.event)
              : IconButton(
                  tooltip: 'Clear due date',
                  onPressed: () => setState(() => due = null),
                  icon: const Icon(Icons.clear),
                ),
        ),
        if (category != RecordCategory.document &&
            category != RecordCategory.warranty)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Payment recorded'),
            value: paid,
            onChanged: (value) => setState(() => paid = value),
          ),
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
