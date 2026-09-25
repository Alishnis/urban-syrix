import 'dart:convert';

import 'package:hackathon_net/core/config/detection_api_config.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/models/place_ai_assessment.dart';
import 'package:http/http.dart' as http;

class OpenAiPlaceAnalysisService {
  const OpenAiPlaceAnalysisService();

  Future<PlaceAiAssessment> analyze({
    required String name,
    required UrbanPlaceType type,
    IncidentSubtype? incidentSubtype,
    required String description,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse(DetectionApiConfig.endpoint('/api/ai/place-analysis')),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'type_label': type.label,
        'incident_subtype_label': incidentSubtype?.label,
        'address': address,
        'description': description,
      }),
    );

    if (response.statusCode >= 400) {
      throw Exception('OpenAI analysis failed with ${response.statusCode}.');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final outputText = payload['output_text'] as String? ?? '{}';
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

  double _score(dynamic value) {
    if (value is num) {
      return value.clamp(0, 100).toDouble();
    }
    return 50;
  }
}
