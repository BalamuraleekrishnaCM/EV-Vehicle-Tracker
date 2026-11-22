import 'dart:convert';

import 'package:ev_vehicle_tracker/data/map_providers.dart';
import 'package:ev_vehicle_tracker/domain/routing_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('road route returns ordered leg lengths in kilometers', () async {
    final routing = OsrmRouting(
      MockClient((request) async {
        expect(
          request.url.path,
          '/route/v1/driving/76.0,9.0;76.1,9.1;76.2,9.2',
        );
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 10000,
                'duration': 1200,
                'geometry': {
                  'coordinates': [
                    [76.0, 9.0],
                    [76.2, 9.2],
                  ],
                },
                'legs': [
                  {'distance': 4800},
                  {'distance': 5200},
                ],
              },
            ],
          }),
          200,
        );
      }),
      baseUrl: 'https://routing.example.org',
    );
    final result = await routing.routeWithLegs(const [
      GeoPoint(9, 76),
      GeoPoint(9.1, 76.1),
      GeoPoint(9.2, 76.2),
    ]);
    expect(result!.$1.distanceKm, 10);
    expect(result.$1.points.first.latitude, 9);
    expect(result.$2, [4.8, 5.2]);
  });

  test(
    'nearby search filters private stations and uses exact connectors',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.bodyFields['data'], contains('(around:12000,9.0,76.0)'));
        Map<String, Object> station(int id, Map<String, String> tags) => {
          'type': 'node',
          'id': id,
          'lat': 9.01,
          'lon': 76.01,
          'tags': tags,
        };
        return http.Response(
          jsonEncode({
            'elements': [
              station(1, {
                'name': 'Town charger',
                'socket:type2_combo': '2',
                'socket:type2': '0',
              }),
              station(2, {'access': 'private', 'socket:type2': '2'}),
            ],
          }),
          200,
        );
      });
      final stations = await OsmChargingStations(
        client,
      ).nearby(latitude: 9, longitude: 76, radiusKm: 12);
      expect(stations.single.name, 'Town charger');
      expect(matchesConnector(stations.single, 'CCS2'), isTrue);
      expect(matchesConnector(stations.single, 'Type 2'), isFalse);
      expect(parseCoordinates('NaN, 76'), isNull);
    },
  );

  test(
    'directory timeout remarks are surfaced instead of showing an empty result',
    () async {
      final client = MockClient(
        (_) async => http.Response('{"remark":"timeout","elements":[]}', 200),
      );
      await expectLater(
        OsmChargingStations(client).nearby(latitude: 9, longitude: 76),
        throwsFormatException,
      );
    },
  );
}
