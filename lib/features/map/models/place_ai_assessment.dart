import 'package:hackathon_net/domain/models/urban_models.dart';

class PlaceAiAssessment {
  const PlaceAiAssessment({
    required this.description,
    required this.baseScores,
    required this.trafficRisk,
    required this.co2Footprint,
    required this.greenCoverage,
  });

  final String description;
  final Map<UrbanCategory, double> baseScores;
  final int trafficRisk;
  final int co2Footprint;
  final int greenCoverage;
}
