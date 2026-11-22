enum RecordCategory {
  charging,
  trip,
  expense,
  service,
  finance,
  issue,
  purchase,
  insurance,
  warranty,
  document,
}

class OwnershipRecord {
  const OwnershipRecord({
    this.id,
    required this.vehicleId,
    required this.category,
    required this.title,
    required this.amountMinor,
    required this.createdAt,
    this.odometerKm,
    this.notes = '',
    this.energyKwh,
    this.distanceKm,
    this.startSoc,
    this.endSoc,
    this.tariff,
    this.minutes,
    this.detail = '',
    this.dueDate,
    this.paid = true,
  });

  final int? id;
  final int vehicleId;
  final RecordCategory category;
  final String title;
  final int amountMinor;
  final DateTime createdAt;
  final double? odometerKm;
  final String notes;
  final double? energyKwh;
  final double? distanceKm;
  final double? startSoc;
  final double? endSoc;
  final double? tariff;
  final double? minutes;
  final String detail;
  final DateTime? dueDate;
  final bool paid;

  double? get whPerKm {
    if (distanceKm == null || distanceKm! <= 0 || energyKwh == null) {
      return null;
    }
    return 1000 * energyKwh! / distanceKm!;
  }

  void validate() {
    final numbers = [
      odometerKm,
      energyKwh,
      distanceKm,
      startSoc,
      endSoc,
      tariff,
      minutes,
    ];
    if (vehicleId <= 0 ||
        title.trim().isEmpty ||
        amountMinor < 0 ||
        numbers.whereType<double>().any(
          (value) => !value.isFinite || value < 0,
        )) {
      throw const FormatException('Check the title, amount and measurements.');
    }
    if ((startSoc ?? 0) > 100 ||
        (endSoc ?? 0) > 100 ||
        (startSoc != null && endSoc != null && endSoc! < startSoc!)) {
      throw const FormatException(
        'Charge percentages must increase and stay within 0–100%.',
      );
    }
    if (category == RecordCategory.trip && distanceKm == 0) {
      throw const FormatException('Trip distance must be greater than zero.');
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicle_id': vehicleId,
    'category': category.name,
    'title': title,
    'amount_minor': amountMinor,
    'created_at': createdAt.toUtc().toIso8601String(),
    'odometer_km': odometerKm,
    'notes': notes,
    'energy_kwh': energyKwh,
    'distance_km': distanceKm,
    'start_soc': startSoc,
    'end_soc': endSoc,
    'tariff': tariff,
    'minutes': minutes,
    'detail': detail,
    'due_date': dueDate?.toUtc().toIso8601String(),
    'paid': paid ? 1 : 0,
  };

  factory OwnershipRecord.fromMap(Map<String, Object?> map) => OwnershipRecord(
    id: map['id'] as int?,
    vehicleId: map['vehicle_id'] as int,
    category: RecordCategory.values.byName(map['category'] as String),
    title: map['title'] as String,
    amountMinor: map['amount_minor'] as int,
    createdAt: DateTime.parse(map['created_at'] as String),
    odometerKm: (map['odometer_km'] as num?)?.toDouble(),
    notes: map['notes'] as String? ?? '',
    energyKwh: (map['energy_kwh'] as num?)?.toDouble(),
    distanceKm: (map['distance_km'] as num?)?.toDouble(),
    startSoc: (map['start_soc'] as num?)?.toDouble(),
    endSoc: (map['end_soc'] as num?)?.toDouble(),
    tariff: (map['tariff'] as num?)?.toDouble(),
    minutes: (map['minutes'] as num?)?.toDouble(),
    detail: map['detail'] as String? ?? '',
    dueDate: DateTime.tryParse(map['due_date'] as String? ?? ''),
    paid: (map['paid'] as int? ?? 1) == 1,
  );
}
