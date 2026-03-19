import 'dart:convert';

import 'package:hackathon_net/core/config/openai_config.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/models/place_ai_assessment.dart';
import 'package:http/http.dart' as http;

class OpenAiPlaceAnalysisService {
  const OpenAiPlaceAnalysisService();

  Future<PlaceAiAssessment> analyze({
    required String name,
    required UrbanPlaceType type,
    required String description,
    required String address,
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
                    'You are an urban planning analyst. Return concise, realistic ratings for city locations. '
                    'Assess the location using these criteria: mobility, environment, resources, transparency, inclusivity, safety. '
                    'Every score must be an integer from 0 to 100. '
                    'Rewrite the description into one polished sentence in English for a product demo. '
                    'Be realistic for the place type and avoid hype.',
              },
            ],
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text':
                    'Analyze this place.\n'
                    'Name: $name\n'
                    'Type: ${type.label}\n'
                    'Address: $address\n'
                    'Description: $description',
              },
            ],
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'urban_place_assessment',
            'strict': true,
            'schema': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'description': {'type': 'string'},
                'mobility': {'type': 'integer'},
                'environment': {'type': 'integer'},
                'resources': {'type': 'integer'},
                'transparency': {'type': 'integer'},
                'inclusivity': {'type': 'integer'},
                'safety': {'type': 'integer'},
                'traffic_risk': {'type': 'integer'},
                'co2_footprint': {'type': 'integer'},
                'green_coverage': {'type': 'integer'},
              },
              'required': [
                'description',
                'mobility',
                'environment',
                'resources',
                'transparency',
                'inclusivity',
                'safety',
                'traffic_risk',
                'co2_footprint',
                'green_coverage',
              ],
            },
          },
        },
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('OpenAI analysis failed with ${response.statusCode}.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText =
        payload['output_text'] as String? ?? _extractOutputText(payload);
    final decoded = jsonDecode(outputText) as Map<String, dynamic>;

    return PlaceAiAssessment(
      description: decoded['description'] as String,
      baseScores: {
        UrbanCategory.mobility: _score(decoded['mobility']),
        UrbanCategory.environment: _score(decoded['environment']),
        UrbanCategory.resources: _score(decoded['resources']),
        UrbanCategory.transparency: _score(decoded['transparency']),
        UrbanCategory.inclusivity: _score(decoded['inclusivity']),
        UrbanCategory.safety: _score(decoded['safety']),
      },
      trafficRisk: _score(decoded['traffic_risk']).round(),
      co2Footprint: _score(decoded['co2_footprint']).round(),
      greenCoverage: _score(decoded['green_coverage']).round(),
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

  double _score(dynamic value) {
    if (value is num) {
      return value.clamp(0, 100).toDouble();
    }
    return 50;
  }
}
