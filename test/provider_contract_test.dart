import 'package:flutter_test/flutter_test.dart';
import 'package:ev_vehicle_tracker/domain/vehicle_data_provider.dart';
import 'package:ev_vehicle_tracker/domain/routing_provider.dart';

void main() {
  test('disconnected vehicle provider does not fabricate telemetry', () async {
    const provider = UnsupportedVehicleDataProvider();
    expect(provider.supportedFields, isEmpty);
    expect((await provider.readSnapshot()).observations, isEmpty);
  });

  test('offline routing does not invent a route', () async {
    const provider = OfflineRoutingProvider();
    final routes = await provider.route(
      origin: const GeoPoint(9.9, 76.3),
      destination: const GeoPoint(10.5, 76.2),
    );
    expect(routes, isEmpty);
  });
}
