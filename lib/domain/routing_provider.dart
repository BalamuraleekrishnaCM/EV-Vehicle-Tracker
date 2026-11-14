class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

class RouteOption {
  const RouteOption({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.source,
  });
  final List<GeoPoint> points;
  final double distanceKm;
  final double durationMinutes;
  final String source;
}

abstract interface class RoutingProvider {
  Future<List<RouteOption>> route({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint> waypoints = const [],
  });
}

class OfflineRoutingProvider implements RoutingProvider {
  const OfflineRoutingProvider();
  @override
  Future<List<RouteOption>> route({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint> waypoints = const [],
  }) async => const [];
}
