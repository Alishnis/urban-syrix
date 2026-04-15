import 'dart:convert';

import 'package:hackathon_net/core/config/google_maps_config.dart';
import 'package:http/http.dart' as http;

class PlacePhotoService {
  const PlacePhotoService();

  static final Map<String, String?> _cache = <String, String?>{};

  Future<String?> lookupPhotoUrl({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = '${name.trim()}|${address.trim()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final apiKey = GoogleMapsConfig.apiKey.trim();
    if (apiKey.isEmpty) {
      _cache[cacheKey] = null;
      return null;
    }

    final photoName = await _lookupPhotoName(
      apiKey: apiKey,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    if (photoName == null || photoName.isEmpty) {
      _cache[cacheKey] = null;
      return null;
    }

    final photoUri = Uri.https(
      'places.googleapis.com',
      '/v1/$photoName/media',
      {
        'key': apiKey,
        'maxWidthPx': '1400',
        'skipHttpRedirect': 'true',
      },
    );

    final response = await http.get(photoUri);
    if (response.statusCode != 200) {
      _cache[cacheKey] = null;
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final directUrl = payload['photoUri'] as String?;
    if (directUrl == null || directUrl.trim().isEmpty) {
      _cache[cacheKey] = null;
      return null;
    }
    _cache[cacheKey] = directUrl;
    return directUrl;
  }

  Future<String?> _lookupPhotoName({
    required String apiKey,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final searchUri = Uri.https(
      'places.googleapis.com',
      '/v1/places:searchText',
    );

    final query = [
      name.trim(),
      address.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    final response = await http.post(
      searchUri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.photos',
      },
      body: jsonEncode({
        'textQuery': query,
        'languageCode': 'en',
        'maxResultCount': 5,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': latitude,
              'longitude': longitude,
            },
            'radius': 500.0,
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final places = payload['places'] as List<dynamic>? ?? const [];
    for (final place in places) {
      final map = place is Map
          ? Map<String, dynamic>.from(place)
          : const <String, dynamic>{};
      final photos = map['photos'] as List<dynamic>? ?? const [];
      if (photos.isEmpty) {
        continue;
      }
      final firstPhoto = photos.first is Map
          ? Map<String, dynamic>.from(photos.first as Map)
          : const <String, dynamic>{};
      final photoName = firstPhoto['name'] as String?;
      if (photoName != null && photoName.trim().isNotEmpty) {
        return photoName;
      }
    }

    return null;
  }
}
