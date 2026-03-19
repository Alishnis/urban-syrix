import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hackathon_net/core/config/detection_api_config.dart';
import 'package:hackathon_net/features/map/models/safe_route_result.dart';
import 'package:http/http.dart' as http;

class SafeRouteService {
  const SafeRouteService();

  Future<SafeRouteResult> buildRoute({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> avoidPoints,
  }) async {
    final response = await http.post(
      Uri.parse(DetectionApiConfig.endpoint('/api/route/safe-route')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'origin': {'latitude': origin.latitude, 'longitude': origin.longitude},
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'avoid_points': avoidPoints
            .map(
              (point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              },
            )
            .toList(growable: false),
      }),
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
        payload['detail'] as String? ??
            'Safe route request failed with status ${response.statusCode}.',
      );
    }

    final coordinates = (payload['coordinates'] as List<dynamic>? ?? const [])
        .map((item) => List<num>.from(item as List))
        .map((pair) => LatLng(pair[1].toDouble(), pair[0].toDouble()))
        .toList(growable: false);

    return SafeRouteResult(
      points: coordinates,
      distanceMeters: (payload['distance_m'] as num?)?.toDouble() ?? 0,
      durationSeconds: (payload['duration_s'] as num?)?.toDouble() ?? 0,
      avoidedPoints: (payload['avoided_points'] as num?)?.toInt() ?? 0,
    );
  }
}
