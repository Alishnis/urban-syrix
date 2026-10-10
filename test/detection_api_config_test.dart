import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_net/core/config/detection_api_config.dart';

void main() {
  test('backend is available by default and falls back to localhost', () {
    expect(DetectionApiConfig.isAvailable, isTrue);
    expect(
      DetectionApiConfig.endpoint('/api/health'),
      '${DetectionApiConfig.localFallbackBaseUrl}/api/health',
    );
  });

  test('BackendUnavailableException explains the demo limitation', () {
    expect(
      const BackendUnavailableException().toString(),
      contains('not hosted in this demo'),
    );
  });
}
