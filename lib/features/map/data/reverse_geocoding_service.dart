import 'dart:convert';

import 'package:hackathon_net/core/config/google_maps_config.dart';
import 'package:http/http.dart' as http;

class ReverseGeocodingService {
  const ReverseGeocodingService();

  Future<String> lookupAddress({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'latlng': '$latitude,$longitude',
        'key': GoogleMapsConfig.apiKey,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Reverse geocoding failed with ${response.statusCode}.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (payload['results'] as List<dynamic>? ?? const []);
    if (results.isEmpty) {
      return _fallbackAddress(latitude, longitude);
    }

    final first = results.first as Map<String, dynamic>;
    final formatted = first['formatted_address'] as String?;
    if (formatted == null || formatted.trim().isEmpty) {
      return _fallbackAddress(latitude, longitude);
    }
    return formatted;
  }

  String _fallbackAddress(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }
}
