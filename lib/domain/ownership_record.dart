enum RecordCategory { charging, trip, expense, service, finance, issue }

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
  });

  final int? id;
  final int vehicleId;
  final RecordCategory category;
  final String title;
  final int amountMinor;
  final DateTime createdAt;
  final double? odometerKm;
  final String notes;

  Map<String, Object?> toMap() => {
        'id': id,
        'vehicle_id': vehicleId,
        'category': category.name,
        'title': title,
        'amount_minor': amountMinor,
        'created_at': createdAt.toUtc().toIso8601String(),
        'odometer_km': odometerKm,
        'notes': notes,
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
      );
}
