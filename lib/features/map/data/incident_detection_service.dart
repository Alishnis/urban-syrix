import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:hackathon_net/core/config/detection_api_config.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/models/detection_result.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class IncidentDetectionService {
  const IncidentDetectionService();

  Future<DetectionResult> analyze({
    required IncidentSubtype subtype,
    required PlatformFile file,
    required double sensitivity,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Selected file could not be read.');
    }

    final extension = (file.extension ?? '').toLowerCase();
    final isImage =
        extension == 'jpg' || extension == 'jpeg' || extension == 'png';
    final mode = isImage ? 'image' : 'video';

    final endpoint = switch (subtype) {
      IncidentSubtype.fire =>
        mode == 'image' ? '/api/fire/analyze-image' : '/api/fire/analyze',
      IncidentSubtype.carAccident =>
        mode == 'image'
            ? '/api/accident/analyze-image'
            : '/api/accident/analyze-video',
      IncidentSubtype.other => throw Exception(
        'Manual incidents do not require detection.',
      ),
    };

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(DetectionApiConfig.endpoint(endpoint)),
    );
    request.fields['sensitivity'] = sensitivity.toStringAsFixed(2);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
        contentType: _contentTypeForExtension(extension, isImage),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = _parseJsonResponse(response);
    if (response.statusCode >= 400) {
      throw Exception(
        payload?['detail'] as String? ??
            payload?['message'] as String? ??
            'Detection failed with status ${response.statusCode}.',
      );
    }

    if (payload == null) {
      throw Exception(
        'Detection API returned an empty response. Verify the backend endpoint is running and returns JSON.',
      );
    }
    final stats = Map<String, dynamic>.from(
      payload['stats'] as Map? ?? const {},
    );
    final detected = switch (subtype) {
      IncidentSubtype.fire =>
        payload['fire_detected'] as bool? ??
            stats['fire_detected'] as bool? ??
            false,
      IncidentSubtype.carAccident =>
        payload['accident_detected'] as bool? ??
            stats['accident_detected'] as bool? ??
            false,
      IncidentSubtype.other => false,
    };

    return DetectionResult(
      detected: detected,
      maxConfidence: (stats['max_confidence'] as num?)?.toDouble() ?? 0,
      mode: mode,
      stats: stats,
      previewUrl: _previewUrlFor(subtype, stats['preview_name'] as String?),
    );
  }

  Map<String, dynamic>? _parseJsonResponse(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return null;
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } on FormatException {
      final snippet = body.length > 140 ? '${body.substring(0, 140)}...' : body;
      throw Exception(
        'Detection API returned a non-JSON response (${response.statusCode}): $snippet',
      );
    }
  }

  MediaType _contentTypeForExtension(String extension, bool isImage) {
    return switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      'mp4' => MediaType('video', 'mp4'),
      'mov' => MediaType('video', 'quicktime'),
      'avi' => MediaType('video', 'x-msvideo'),
      _ => isImage ? MediaType('image', 'jpeg') : MediaType('video', 'mp4'),
    };
  }

  String? _previewUrlFor(IncidentSubtype subtype, String? previewName) {
    if (previewName == null || previewName.isEmpty) {
      return null;
    }

    final path = switch (subtype) {
      IncidentSubtype.fire => '/api/fire/preview/$previewName',
      IncidentSubtype.carAccident => '/api/accident/preview/$previewName',
      IncidentSubtype.other => null,
    };

    if (path == null) {
      return null;
    }

    return DetectionApiConfig.previewUrl(path);
  }
}
