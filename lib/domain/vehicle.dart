enum VehicleType { car, scooter }

class EvVehicle {
  const EvVehicle({
    this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.batteryKwh,
    this.odometerKm = 0,
    this.variant = '',
    this.connector = '',
    this.archived = false,
  });

  final int? id;
  final VehicleType type;
  final String brand;
  final String model;
  final double batteryKwh;
  final double odometerKm;
  final String variant;
  final String connector;
  final bool archived;

  void validate() {
    if (brand.trim().isEmpty ||
        model.trim().isEmpty ||
        !batteryKwh.isFinite ||
        batteryKwh <= 0 ||
        !odometerKm.isFinite ||
        odometerKm < 0) {
      throw const FormatException(
        'Enter a brand, model, positive battery capacity and valid odometer.',
      );
    }
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'brand': brand,
    'model': model,
    'battery_kwh': batteryKwh,
    'odometer_km': odometerKm,
    'variant': variant,
    'connector': connector,
    'archived': archived ? 1 : 0,
  };

  factory EvVehicle.fromMap(Map<String, Object?> map) => EvVehicle(
    id: map['id'] as int?,
    type: VehicleType.values.byName(map['type'] as String),
    brand: map['brand'] as String,
    model: map['model'] as String,
    batteryKwh: (map['battery_kwh'] as num).toDouble(),
    odometerKm: (map['odometer_km'] as num).toDouble(),
    variant: map['variant'] as String? ?? '',
    connector: map['connector'] as String? ?? '',
    archived: (map['archived'] as int? ?? 0) == 1,
  );
}
