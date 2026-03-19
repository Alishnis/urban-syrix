import 'dart:convert';

import 'package:hackathon_net/core/config/openai_config.dart';
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
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${OpenAiConfig.apiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'input': [
          {
            'role': 'system',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'You analyze citizen feedback for urban projects. '
                    'Return a structured sentiment and numeric score impact for these categories: '
                    'mobility, environment, resources, transparency, inclusivity, safety. '
                    'Each impact must be an integer between -12 and 12, where negative lowers the score and positive raises it. '
                    'Stay realistic and conservative. Only reflect concerns actually present in the comment.',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'Project: ${place.name}\n'
                    'Type: ${place.type.label}\n'
                    'Address: ${place.address}\n'
                    'Current description: ${place.description}\n'
                    'User selected category: ${selectedCategory.label}\n'
                    'Comment: $message',
              },
            ],
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'urban_review_impact',
            'strict': true,
            'schema': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'sentiment': {'type': 'integer'},
                'mobility': {'type': 'integer'},
                'environment': {'type': 'integer'},
                'resources': {'type': 'integer'},
                'transparency': {'type': 'integer'},
                'inclusivity': {'type': 'integer'},
                'safety': {'type': 'integer'},
              },
              'required': [
                'sentiment',
                'mobility',
                'environment',
                'resources',
                'transparency',
                'inclusivity',
                'safety',
              ],
            },
          },
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'OpenAI review analysis failed with ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText =
        payload['output_text'] as String? ?? _extractOutputText(payload);
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

  String _extractOutputText(Map<String, dynamic> payload) {
    final output = payload['output'] as List<dynamic>? ?? const [];
    for (final item in output) {
      final itemMap = item as Map<String, dynamic>;
      final content = itemMap['content'] as List<dynamic>? ?? const [];
      for (final part in content) {
        final partMap = part as Map<String, dynamic>;
        if (partMap['type'] == 'output_text') {
          return partMap['text'] as String? ?? '{}';
        }
      }
    }
    return '{}';
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
