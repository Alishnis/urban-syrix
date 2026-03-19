import 'package:flutter/material.dart';

enum UrbanCategory {
  mobility('mobility', 'Mobility', Icons.route_rounded, Color(0xFF2F7AF8)),
  environment(
    'environment',
    'Environment',
    Icons.eco_rounded,
    Color(0xFF27966B),
  ),
  resources(
    'resources',
    'Resources',
    Icons.water_drop_rounded,
    Color(0xFF1593A5),
  ),
  transparency(
    'transparency',
    'Transparency',
    Icons.construction_rounded,
    Color(0xFFD97A20),
  ),
  inclusivity(
    'inclusivity',
    'Inclusivity',
    Icons.accessible_forward_rounded,
    Color(0xFF8F62E8),
  ),
  safety('safety', 'Safety', Icons.shield_moon_rounded, Color(0xFFCC4B4B));

  const UrbanCategory(this.key, this.label, this.icon, this.color);

  final String key;
  final String label;
  final IconData icon;
  final Color color;

  static UrbanCategory fromKey(String? key) {
    return UrbanCategory.values.firstWhere(
      (category) => category.key == key,
      orElse: () => UrbanCategory.safety,
    );
  }
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
  building('building', 'Building', Icons.apartment_rounded),
  construction('construction', 'Construction', Icons.construction_rounded),
  road('road', 'Road', Icons.alt_route_rounded),
  incident('incident', 'Incident', Icons.warning_amber_rounded);

  const UrbanPlaceType(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;

  static UrbanPlaceType fromKey(String? key) {
    return UrbanPlaceType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => UrbanPlaceType.incident,
    );
  }
}

enum IncidentSubtype {
  fire(
    'fire',
    'Fire',
    Icons.local_fire_department_rounded,
    'YOLOv8 Fire Detection',
  ),
  carAccident(
    'car_accident',
    'Car accident',
    Icons.car_crash_rounded,
    'YOLOv8 Traffic Accident Detection',
  ),
  other('other', 'Other', Icons.edit_note_rounded, 'Manual Incident Report');

  const IncidentSubtype(this.key, this.label, this.icon, this.modelLabel);

  final String key;
  final String label;
  final IconData icon;
  final String modelLabel;

  static IncidentSubtype fromKey(String? key) {
    return IncidentSubtype.values.firstWhere(
      (type) => type.key == key,
      orElse: () => IncidentSubtype.other,
    );
  }
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
    this.scoreImpact = const {},
    this.verifiedInclusivity = false,
  });

  final String author;
  final String message;
  final UrbanCategory category;
  final int sentiment;
  final int daysAgo;
  final Map<UrbanCategory, double> scoreImpact;
  final bool verifiedInclusivity;
}

class UrbanPlace {
  UrbanPlace({
    required this.id,
    required this.name,
    required this.type,
    this.incidentSubtype,
    this.detectionModel,
    this.detectionPreviewUrl,
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
  final IncidentSubtype? incidentSubtype;
  final String? detectionModel;
  final String? detectionPreviewUrl;
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

  UrbanPlace copyWith({
    String? id,
    String? name,
    UrbanPlaceType? type,
    IncidentSubtype? incidentSubtype,
    String? detectionModel,
    String? detectionPreviewUrl,
    String? address,
    String? description,
    GeoPoint? location,
    String? developer,
    int? trafficRisk,
    int? co2Footprint,
    int? greenCoverage,
    Map<UrbanCategory, double>? baseScores,
    List<UrbanIssue>? issues,
    List<UrbanReview>? reviews,
  }) {
    return UrbanPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      incidentSubtype: incidentSubtype ?? this.incidentSubtype,
      detectionModel: detectionModel ?? this.detectionModel,
      detectionPreviewUrl: detectionPreviewUrl ?? this.detectionPreviewUrl,
      address: address ?? this.address,
      description: description ?? this.description,
      location: location ?? this.location,
      developer: developer ?? this.developer,
      trafficRisk: trafficRisk ?? this.trafficRisk,
      co2Footprint: co2Footprint ?? this.co2Footprint,
      greenCoverage: greenCoverage ?? this.greenCoverage,
      baseScores: baseScores ?? this.baseScores,
      issues: issues ?? this.issues,
      reviews: reviews ?? this.reviews,
    );
  }
}
