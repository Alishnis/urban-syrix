import 'package:hackathon_net/core/config/runtime_env.dart';

/// Thrown instead of calling a backend that this build deliberately lacks
/// (the frontend-only GitHub Pages demo).
class BackendUnavailableException implements Exception {
  const BackendUnavailableException();

  @override
  String toString() =>
      'This service is not hosted in this demo. Run the backend locally to '
      'enable detection, safe routing and AI scoring (see docs/DEPLOY.md).';
}

class DetectionApiConfig {
  const DetectionApiConfig._();

  /// Set `--dart-define=DETECTION_API_DISABLED=true` for builds that ship
  /// without the FastAPI backend. Unset (the default) keeps the existing
  /// behaviour, including the localhost fallback for local development.
  static const _disabledFromDefine = bool.fromEnvironment(
    'DETECTION_API_DISABLED',
  );

  static bool get isAvailable => !_disabledFromDefine;

  static const _baseUrlFromDefine = String.fromEnvironment(
    'DETECTION_API_BASE_URL',
  );
  static const localFallbackBaseUrl = 'http://localhost:8002';

  static String get baseUrl => _baseUrlFromDefine.trim().isNotEmpty
      ? _baseUrlFromDefine
      : RuntimeEnv.value('DETECTION_API_BASE_URL');

  static String endpoint(String path) {
    if (!isAvailable) {
      throw const BackendUnavailableException();
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final trimmedBase = baseUrl.trim().isEmpty
        ? localFallbackBaseUrl
        : baseUrl.trim();
    if (trimmedBase.isEmpty) {
      return normalizedPath;
    }
    return '${trimmedBase.replaceAll(RegExp(r'/$'), '')}$normalizedPath';
  }

  static String previewUrl(String path) => endpoint(path);
}
