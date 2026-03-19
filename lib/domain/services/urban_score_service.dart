import 'package:flutter/material.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';

class UrbanScoreService {
  static const Map<UrbanCategory, double> _weights = {
    UrbanCategory.mobility: 0.20,
    UrbanCategory.environment: 0.20,
    UrbanCategory.resources: 0.15,
    UrbanCategory.transparency: 0.15,
    UrbanCategory.inclusivity: 0.15,
    UrbanCategory.safety: 0.15,
  };

  static double categoryScore(UrbanPlace place, UrbanCategory category) {
    final base = place.baseScores[category] ?? 50;

    final issuePenalty = place.issues
        .where((issue) => issue.category == category)
        .fold<double>(
          0,
          (sum, issue) => sum + issue.severity * 3.4 + (issue.daysOpen / 3),
        );

    final reviewShift = place.reviews
        .where((review) => review.category == category)
        .fold<double>(
          0,
          (sum, review) =>
              sum +
              (review.scoreImpact[category] ??
                  (review.sentiment * 3.5) +
                      (review.verifiedInclusivity ? 1.5 : 0)),
        );

    final crossCategoryReviewShift = place.reviews
        .where(
          (review) =>
              review.category != category &&
              review.scoreImpact.containsKey(category),
        )
        .fold<double>(
          0,
          (sum, review) => sum + (review.scoreImpact[category] ?? 0),
        );

    return (base - issuePenalty + reviewShift + crossCategoryReviewShift).clamp(
      18,
      96,
    );
  }

  static double overallScore(UrbanPlace place) {
    return _weights.entries.fold<double>(
      0,
      (sum, entry) => sum + categoryScore(place, entry.key) * entry.value,
    );
  }

  static double scoreByCriterion(UrbanPlace place, ScoreCriterion criterion) {
    final category = criterion.category;
    if (category == null) {
      return overallScore(place);
    }
    return categoryScore(place, category);
  }

  static Map<UrbanCategory, double> breakdown(UrbanPlace place) {
    return {
      for (final category in UrbanCategory.values)
        category: categoryScore(place, category),
    };
  }

  static int cityAverageScore(List<UrbanPlace> places) {
    if (places.isEmpty) {
      return 0;
    }
    final total = places.fold<double>(
      0,
      (sum, place) => sum + overallScore(place),
    );
    return (total / places.length).round();
  }

  static int averageFixDays(List<UrbanPlace> places) {
    final allIssues = places.expand((place) => place.issues).toList();
    if (allIssues.isEmpty) {
      return 0;
    }
    return (allIssues.fold<int>(0, (sum, issue) => sum + issue.daysOpen) /
            allIssues.length)
        .round();
  }

  static Color scoreColor(double score) {
    if (score >= 75) {
      return const Color(0xFF299B63);
    }
    if (score >= 55) {
      return const Color(0xFFD8A52B);
    }
    return const Color(0xFFCC5448);
  }

  static List<String> buildAlerts(List<UrbanPlace> places) {
    final alerts = <String>[];

    for (final place in places) {
      final unresolved = place.issues.where((issue) => issue.daysOpen >= 20);
      if (unresolved.isNotEmpty) {
        final issue = unresolved.first;
        alerts.add(
          '${place.name}: ${issue.title} unresolved for ${issue.daysOpen} days.',
        );
      }

      final mobilityScore = categoryScore(place, UrbanCategory.mobility);
      if (mobilityScore < 60 && place.trafficRisk >= 30) {
        alerts.add(
          '${place.name}: forecasted traffic pressure +${place.trafficRisk}%.',
        );
      }
    }

    return alerts.take(4).toList();
  }
}
