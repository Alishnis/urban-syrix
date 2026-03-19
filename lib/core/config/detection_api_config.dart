class DetectionApiConfig {
  const DetectionApiConfig._();

  static const baseUrl = String.fromEnvironment('DETECTION_API_BASE_URL');
  static const localFallbackBaseUrl = 'http://localhost:8001';

  static String endpoint(String path) {
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
