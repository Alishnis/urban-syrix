import 'package:flutter/material.dart';

enum UrbanCategory {
  mobility('Mobility', Icons.route_rounded, Color(0xFF2F7AF8)),
  environment('Environment', Icons.eco_rounded, Color(0xFF27966B)),
  resources('Resources', Icons.water_drop_rounded, Color(0xFF1593A5)),
  transparency('Transparency', Icons.construction_rounded, Color(0xFFD97A20)),
  inclusivity(
    'Inclusivity',
    Icons.accessible_forward_rounded,
    Color(0xFF8F62E8),
  ),
  safety('Safety', Icons.shield_moon_rounded, Color(0xFFCC4B4B));

  const UrbanCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum ScoreCriterion {
  overall('Overall score', null),
  mobility('Mobility', UrbanCategory.mobility),
  environment('Environment', UrbanCategory.environment),
  resources('Resources', UrbanCategory.resources),
  transparency('Transparency', UrbanCategory.transparency),
  inclusivity('Inclusivity', UrbanCategory.inclusivity),
  safety('Safety', UrbanCategory.safety);

  const ScoreCriterion(this.label, this.category);

  final String label;
  final UrbanCategory? category;
}

enum UrbanPlaceType {
  building('Building', Icons.apartment_rounded),
  construction('Construction', Icons.construction_rounded),
  road('Road', Icons.alt_route_rounded),
  incident('Incident', Icons.warning_amber_rounded);

  const UrbanPlaceType(this.label, this.icon);

  final String label;
  final IconData icon;
}

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class UrbanIssue {
  const UrbanIssue({
    required this.title,
    required this.category,
    required this.daysOpen,
    required this.severity,
  });

  final String title;
  final UrbanCategory category;
  final int daysOpen;
  final int severity;
}

class UrbanReview {
  const UrbanReview({
    required this.author,
    required this.message,
    required this.category,
    required this.sentiment,
    required this.daysAgo,
    this.verifiedInclusivity = false,
  });

  final String author;
  final String message;
  final UrbanCategory category;
  final int sentiment;
  final int daysAgo;
  final bool verifiedInclusivity;
}

class UrbanPlace {
  UrbanPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.description,
    required this.location,
    required this.developer,
    required this.trafficRisk,
    required this.co2Footprint,
    required this.greenCoverage,
    required this.baseScores,
    required this.issues,
    required this.reviews,
  });

  final String id;
  final String name;
  final UrbanPlaceType type;
  final String address;
  final String description;
  final GeoPoint location;
  final String developer;
  final int trafficRisk;
  final int co2Footprint;
  final int greenCoverage;
  final Map<UrbanCategory, double> baseScores;
  final List<UrbanIssue> issues;
  final List<UrbanReview> reviews;
}
