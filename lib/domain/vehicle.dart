enum VehicleType { car, scooter }

class EvVehicle {
  const EvVehicle({
    this.id,
    required this.type,
    required this.brand,
    required this.model,
    required this.batteryKwh,
    this.odometerKm = 0,
  });

  final int? id;
  final VehicleType type;
  final String brand;
  final String model;
  final double batteryKwh;
  final double odometerKm;

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'brand': brand,
        'model': model,
        'battery_kwh': batteryKwh,
        'odometer_km': odometerKm,
      };

  factory EvVehicle.fromMap(Map<String, Object?> map) => EvVehicle(
        id: map['id'] as int?,
        type: VehicleType.values.byName(map['type'] as String),
        brand: map['brand'] as String,
        model: map['model'] as String,
        batteryKwh: (map['battery_kwh'] as num).toDouble(),
        odometerKm: (map['odometer_km'] as num).toDouble(),
      );
}
