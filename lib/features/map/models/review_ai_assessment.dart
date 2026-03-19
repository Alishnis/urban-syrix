import 'package:hackathon_net/domain/models/urban_models.dart';

class ReviewAiAssessment {
  const ReviewAiAssessment({
    required this.sentiment,
    required this.scoreImpact,
  });

  final int sentiment;
  final Map<UrbanCategory, double> scoreImpact;
}
