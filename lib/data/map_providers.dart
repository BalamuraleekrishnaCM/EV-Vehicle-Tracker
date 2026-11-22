import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../domain/charging_station.dart';
import '../domain/routing_provider.dart';

GeoPoint? parseCoordinates(String text) {
  final parts = text.split(',');
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lon = double.tryParse(parts[1].trim());
  if (lat == null ||
      lon == null ||
      !lat.isFinite ||
      !lon.isFinite ||
      lat.abs() > 90 ||
      lon.abs() > 180) {
    return null;
  }
  return GeoPoint(lat, lon);
}

double straightLineKm(GeoPoint a, GeoPoint b) {
  const radians = math.pi / 180;
  final lat = (b.latitude - a.latitude) * radians;
  final lon = (b.longitude - a.longitude) * radians;
  final h =
      math.pow(math.sin(lat / 2), 2) +
      math.cos(a.latitude * radians) *
          math.cos(b.latitude * radians) *
          math.pow(math.sin(lon / 2), 2);
  return 12742 * math.asin(math.sqrt(h.clamp(0, 1)));
}

class OsmChargingStations implements ChargingStationProvider {
  const OsmChargingStations(this.client);
  final http.Client client;
  static const endpoint = String.fromEnvironment(
    'EV_OVERPASS_URL',
    defaultValue: 'https://overpass.private.coffee/api/interpreter',
  );

  @override
  Future<List<ChargingStation>> nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) => _query('(around:${(radiusKm * 1000).round()},$latitude,$longitude)');

  Future<List<ChargingStation>> corridor(List<GeoPoint> points) async {
    if (points.length < 2) return [];
    final stride = (points.length / 100).ceil();
    final sampled = [
      for (var i = 0; i < points.length - 1; i += stride) points[i],
      points.last,
    ];
    final geometry = sampled
        .map((point) => '${point.latitude},${point.longitude}')
        .join(',');
    return _query('(around:5000,$geometry)');
  }

  Future<List<ChargingStation>> _query(String area) async {
    final response = await client
        .post(
          Uri.parse(endpoint),
          body: {
            'data':
                '[out:json][timeout:20];nwr["amenity"="charging_station"]$area;out center 300;',
          },
        )
        .timeout(const Duration(seconds: 28));
    if (response.statusCode != 200) {
      throw const FormatException(
        'The charger directory is temporarily unavailable.',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['remark'] != null) {
      throw const FormatException(
        'The charger search was incomplete. Try a smaller area.',
      );
    }
    final stations = <ChargingStation>[];
    for (final element in body['elements'] as List) {
      final tags = element['tags'] as Map<String, dynamic>? ?? {};
      final coordinate = element['center'] ?? element;
      final lat = coordinate['lat'] as num?;
      final lon = coordinate['lon'] as num?;
      if (lat == null ||
          lon == null ||
          tags['access'] == 'no' ||
          tags['access'] == 'private') {
        continue;
      }
      final connectors = <String>[];
      for (final tag in tags.entries) {
        if (!tag.key.startsWith('socket:') || tag.key.split(':').length != 2) {
          continue;
        }
        final count = tag.value.toString();
        if (count == 'no' || count == '0' || count == 'unknown') continue;
        connectors.add(tag.key.substring(7));
      }
      stations.add(
        ChargingStation(
          id: '${element['type']}/${element['id']}',
          name: (tags['name'] ?? tags['operator'] ?? 'Charging station')
              .toString(),
          latitude: lat.toDouble(),
          longitude: lon.toDouble(),
          connectorTypes: connectors,
        ),
      );
    }
    return stations;
  }
}

bool matchesConnector(ChargingStation station, String connector) {
  String normalize(String value) {
    final key = value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return switch (key) {
      'ccs2' => 'type2combo',
      'ccs1' => 'type1combo',
      _ => key,
    };
  }

  final wanted = normalize(connector);
  return wanted.isNotEmpty &&
      station.connectorTypes.any((type) => normalize(type) == wanted);
}

class OsrmRouting implements RoutingProvider {
  const OsrmRouting(this.client, {this.baseUrl = endpoint});
  final http.Client client;
  static const endpoint = String.fromEnvironment('EV_OSRM_URL');
  final String baseUrl;

  @override
  Future<List<RouteOption>> route({
    required GeoPoint origin,
    required GeoPoint destination,
    List<GeoPoint> waypoints = const [],
  }) async {
    final result = await routeWithLegs([origin, ...waypoints, destination]);
    return result == null ? [] : [result.$1];
  }

  Future<(RouteOption, List<double>)?> routeWithLegs(
    List<GeoPoint> points,
  ) async {
    if (baseUrl.isEmpty) {
      throw const FormatException(
        'Road routing requires a configured OSRM service. You can enter distance manually.',
      );
    }
    final coordinates = points
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$base/route/v1/driving/$coordinates').replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'generate_hints': 'false',
      },
    );
    final response = await client.get(uri).timeout(const Duration(seconds: 20));
    final body = jsonDecode(response.body) as Map;
    if (body['code'] == 'NoRoute' || body['code'] == 'NoSegment') return null;
    if (response.statusCode != 200 || body['code'] != 'Ok') {
      throw const FormatException(
        'The road routing service is temporarily unavailable.',
      );
    }
    final route = (body['routes'] as List).first as Map;
    return (
      RouteOption(
        points: [
          for (final pair in route['geometry']['coordinates'] as List)
            GeoPoint((pair[1] as num).toDouble(), (pair[0] as num).toDouble()),
        ],
        distanceKm: (route['distance'] as num) / 1000,
        durationMinutes: (route['duration'] as num) / 60,
        source: 'OSRM / OpenStreetMap',
      ),
      [
        for (final leg in route['legs'] as List)
          (leg['distance'] as num) / 1000,
      ],
    );
  }
}
