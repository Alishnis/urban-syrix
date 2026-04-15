import 'package:hackathon_net/core/config/runtime_env.dart';

class GoogleMapsConfig {
  const GoogleMapsConfig._();

  static const _apiKeyFromDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyA1I9NaQcg6zbj2iVXsmqjKK0E4bYYpNuY',
  );

  static String get apiKey =>
      _apiKeyFromDefine.trim().isNotEmpty &&
          _apiKeyFromDefine != 'AIzaSyA1I9NaQcg6zbj2iVXsmqjKK0E4bYYpNuY'
      ? _apiKeyFromDefine
      : RuntimeEnv.value(
          'GOOGLE_MAPS_API_KEY',
          fallback: _apiKeyFromDefine,
        );
}
