import 'routing_provider.dart';

class ChargingStation {
  const ChargingStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.connectorTypes,
    this.powerKw,
    this.lastVerifiedAt,
  });
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> connectorTypes;
  final double? powerKw;
  final DateTime? lastVerifiedAt;
  GeoPoint get point => GeoPoint(latitude, longitude);
}

abstract interface class ChargingStationProvider {
  Future<List<ChargingStation>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  });
}

/// Explicit no-network provider: never fabricates charger listings.
class OfflineChargingStationProvider implements ChargingStationProvider {
  const OfflineChargingStationProvider();

  @override
  Future<List<ChargingStation>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) async => const [];
}
