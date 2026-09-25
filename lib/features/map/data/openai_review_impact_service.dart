import 'dart:convert';

import 'package:hackathon_net/core/config/detection_api_config.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/models/review_ai_assessment.dart';
import 'package:http/http.dart' as http;

class OpenAiReviewImpactService {
  const OpenAiReviewImpactService();

  Future<ReviewAiAssessment> analyze({
    required UrbanPlace place,
    required String message,
    required UrbanCategory selectedCategory,
  }) async {
    final response = await http.post(
      Uri.parse(DetectionApiConfig.endpoint('/api/ai/review-impact')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'place_name': place.name,
        'place_type_label': place.type.label,
        'place_address': place.address,
        'place_description': place.description,
        'selected_category_label': selectedCategory.label,
        'message': message,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'OpenAI review analysis failed with ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = payload['output_text'] as String? ?? '{}';
    final decoded = jsonDecode(outputText) as Map<String, dynamic>;

    return ReviewAiAssessment(
      sentiment: _sentiment(decoded['sentiment']),
      scoreImpact: {
        UrbanCategory.mobility: _impact(decoded['mobility']),
        UrbanCategory.environment: _impact(decoded['environment']),
        UrbanCategory.resources: _impact(decoded['resources']),
        UrbanCategory.transparency: _impact(decoded['transparency']),
        UrbanCategory.inclusivity: _impact(decoded['inclusivity']),
        UrbanCategory.safety: _impact(decoded['safety']),
      },
    );
  }

  int _sentiment(dynamic value) {
    if (value is num) {
      return value.clamp(-1, 1).toInt();
    }
    return 0;
  }

  double _impact(dynamic value) {
    if (value is num) {
      return value.clamp(-12, 12).toDouble();
    }
    return 0;
  }
}
