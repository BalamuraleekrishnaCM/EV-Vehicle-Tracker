/// A read-only, capability-gated vehicle integration boundary.
///
/// No transport or manufacturer implementation is implied by this interface.
enum VehicleTelemetryField {
  stateOfCharge,
  odometerKm,
  rangeKm,
  batteryTemperatureC,
}

class VehicleObservation {
  const VehicleObservation({
    required this.field,
    required this.value,
    required this.source,
    required this.observedAt,
  });
  final VehicleTelemetryField field;
  final double value;
  final String source;
  final DateTime observedAt;
}

class VehicleSnapshot {
  const VehicleSnapshot({required this.observations});
  final List<VehicleObservation> observations;
}

abstract interface class VehicleDataProvider {
  String get providerId;
  Set<VehicleTelemetryField> get supportedFields;
  Future<VehicleSnapshot> readSnapshot();
  Future<void> disconnect();
}

class UnsupportedVehicleDataProvider implements VehicleDataProvider {
  const UnsupportedVehicleDataProvider();
  @override
  String get providerId => 'unconnected';
  @override
  Set<VehicleTelemetryField> get supportedFields => const {};
  @override
  Future<VehicleSnapshot> readSnapshot() async =>
      const VehicleSnapshot(observations: []);
  @override
  Future<void> disconnect() async {}
}
