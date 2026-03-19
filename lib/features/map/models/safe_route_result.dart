import 'package:google_maps_flutter/google_maps_flutter.dart';

class SafeRouteResult {
  const SafeRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.avoidedPoints,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final int avoidedPoints;
}
