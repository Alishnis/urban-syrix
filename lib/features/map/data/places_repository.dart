import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/data/openai_review_impact_service.dart';
import 'package:hackathon_net/features/map/models/review_ai_assessment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PlacesRepository {
  Future<List<UrbanPlace>> fetchPlaces();
  Future<Map<String, List<UrbanReview>>> fetchReviewsByPlaceId();
  Future<UrbanPlace> createPlace(UrbanPlace place);
  Future<UrbanReview> addReview({
    required UrbanPlace place,
    required String message,
    required UrbanCategory category,
  });
}

class SupabasePlacesRepository implements PlacesRepository {
  SupabasePlacesRepository(this._client);

  final SupabaseClient _client;
  final OpenAiReviewImpactService _reviewImpactService =
      const OpenAiReviewImpactService();

  @override
  Future<List<UrbanPlace>> fetchPlaces() async {
    final response = await _client
        .from('urban_places')
        .select(
          'id, name, type, incident_subtype, detection_model, detection_preview_url, address, description, latitude, longitude, developer, '
          'traffic_risk, co2_footprint, green_coverage, base_scores, issues',
        )
        .order('created_at', ascending: false);

    return response
        .map<UrbanPlace>((row) => _placeFromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<Map<String, List<UrbanReview>>> fetchReviewsByPlaceId() async {
    final response = await _client
        .from('urban_place_reviews')
        .select(
          'place_id, author_name, message, category, sentiment, '
          'verified_inclusivity, created_at, score_impact',
        )
        .order('created_at', ascending: false);

    final reviewsByPlace = <String, List<UrbanReview>>{};
    for (final row in response) {
      final map = Map<String, dynamic>.from(row);
      final placeId = map['place_id'] as String? ?? '';
      if (placeId.isEmpty) {
        continue;
      }
      reviewsByPlace
          .putIfAbsent(placeId, () => <UrbanReview>[])
          .add(_reviewFromMap(map));
    }
    return reviewsByPlace;
  }

  @override
  Future<UrbanPlace> createPlace(UrbanPlace place) async {
    final user = _requireUser();
    await _ensureCreateAccess(user.id, place.type);

    final response = await _client
        .from('urban_places')
        .insert({
          'id': place.id,
          'created_by': user.id,
          'name': place.name,
          'type': place.type.key,
          'incident_subtype': place.incidentSubtype?.key,
          'detection_model': place.detectionModel,
          'detection_preview_url': place.detectionPreviewUrl,
          'address': place.address,
          'description': place.description,
          'latitude': place.location.latitude,
          'longitude': place.location.longitude,
          'developer': place.developer,
          'traffic_risk': place.trafficRisk,
          'co2_footprint': place.co2Footprint,
          'green_coverage': place.greenCoverage,
          'base_scores': _serializeScores(place.baseScores),
          'issues': place.issues.map(_serializeIssue).toList(growable: false),
        })
        .select(
          'id, name, type, incident_subtype, detection_model, detection_preview_url, address, description, latitude, longitude, developer, '
          'traffic_risk, co2_footprint, green_coverage, base_scores, issues',
        )
        .single();

    return _placeFromMap(
      Map<String, dynamic>.from(response),
    ).copyWith(reviews: place.reviews);
  }

  @override
  Future<UrbanReview> addReview({
    required UrbanPlace place,
    required String message,
    required UrbanCategory category,
  }) async {
    final user = _requireUser();
    final authorName = _authorNameFor(user);
    final timestamp = DateTime.now().toUtc();
    final assessment = await _buildReviewAssessment(
      place: place,
      message: message,
      category: category,
    );

    await _ensurePlaceExists(place, user.id);

    final response = await _client
        .from('urban_place_reviews')
        .insert({
          'id': 'review_${DateTime.now().microsecondsSinceEpoch}',
          'place_id': place.id,
          'author_id': user.id,
          'author_name': authorName,
          'message': message,
          'category': category.key,
          'sentiment': assessment.sentiment,
          'verified_inclusivity': false,
          'created_at': timestamp.toIso8601String(),
          'score_impact': _serializeScores(assessment.scoreImpact),
        })
        .select(
          'author_name, message, category, sentiment, '
          'verified_inclusivity, created_at, score_impact',
        )
        .single();

    return _reviewFromMap(Map<String, dynamic>.from(response));
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('You must be signed in to save data.');
    }
    return user;
  }

  Future<void> _ensurePlaceExists(UrbanPlace place, String userId) async {
    final existing = await _client
        .from('urban_places')
        .select('id')
        .eq('id', place.id)
        .maybeSingle();
    if (existing != null) {
      return;
    }

    await _client.from('urban_places').insert({
      'id': place.id,
      'created_by': userId,
      'name': place.name,
      'type': place.type.key,
      'incident_subtype': place.incidentSubtype?.key,
      'detection_model': place.detectionModel,
      'detection_preview_url': place.detectionPreviewUrl,
      'address': place.address,
      'description': place.description,
      'latitude': place.location.latitude,
      'longitude': place.location.longitude,
      'developer': place.developer,
      'traffic_risk': place.trafficRisk,
      'co2_footprint': place.co2Footprint,
      'green_coverage': place.greenCoverage,
      'base_scores': _serializeScores(place.baseScores),
      'issues': place.issues.map(_serializeIssue).toList(growable: false),
    });
  }

  UrbanPlace _placeFromMap(Map<String, dynamic> map) {
    return UrbanPlace(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      type: UrbanPlaceType.fromKey(map['type'] as String?),
      incidentSubtype: map['incident_subtype'] == null
          ? null
          : IncidentSubtype.fromKey(map['incident_subtype'] as String?),
      detectionModel: map['detection_model'] as String?,
      detectionPreviewUrl: map['detection_preview_url'] as String?,
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: GeoPoint(
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      ),
      developer: map['developer'] as String? ?? '',
      trafficRisk: (map['traffic_risk'] as num?)?.toInt() ?? 0,
      co2Footprint: (map['co2_footprint'] as num?)?.toInt() ?? 0,
      greenCoverage: (map['green_coverage'] as num?)?.toInt() ?? 0,
      baseScores: _scoresFromMap(map['base_scores']),
      issues: _issuesFromList(map['issues']),
      reviews: const [],
    );
  }

  UrbanReview _reviewFromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.tryParse(map['created_at'] as String? ?? '');
    final now = DateTime.now().toUtc();
    final daysAgo = createdAt == null ? 0 : now.difference(createdAt).inDays;

    return UrbanReview(
      author: map['author_name'] as String? ?? '',
      message: map['message'] as String? ?? '',
      category: UrbanCategory.fromKey(map['category'] as String?),
      sentiment: (map['sentiment'] as num?)?.toInt() ?? 0,
      daysAgo: daysAgo,
      scoreImpact: _scoresFromMap(map['score_impact']),
      verifiedInclusivity: map['verified_inclusivity'] as bool? ?? false,
    );
  }

  String _authorNameFor(User user) {
    final email = user.email ?? '';
    if (email.isEmpty) {
      return 'Urban resident';
    }
    return email.split('@').first;
  }

  Future<void> _ensureCreateAccess(String userId, UrbanPlaceType type) async {
    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    final role = profile == null ? null : profile['role'] as String?;
    if (type == UrbanPlaceType.incident) {
      if (role == 'resident' || role == 'builder' || role == 'admin') {
        return;
      }
      throw const AuthException(
        'Only resident, builder, or admin accounts can create accident points.',
      );
    }
    if (role != 'builder' && role != 'admin') {
      throw const AuthException(
        'Only builder or admin accounts can create map points.',
      );
    }
  }

  Future<ReviewAiAssessment> _buildReviewAssessment({
    required UrbanPlace place,
    required String message,
    required UrbanCategory category,
  }) async {
    try {
      return await _reviewImpactService.analyze(
        place: place,
        message: message,
        selectedCategory: category,
      );
    } catch (_) {
      return ReviewAiAssessment(
        sentiment: 0,
        scoreImpact: {for (final item in UrbanCategory.values) item: 0},
      );
    }
  }

  Map<String, double> _serializeScores(Map<UrbanCategory, double> scores) {
    return {for (final entry in scores.entries) entry.key.key: entry.value};
  }

  Map<String, dynamic> _serializeIssue(UrbanIssue issue) {
    return {
      'title': issue.title,
      'category': issue.category.key,
      'days_open': issue.daysOpen,
      'severity': issue.severity,
    };
  }

  Map<UrbanCategory, double> _scoresFromMap(dynamic value) {
    final map = value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
    return {
      for (final category in UrbanCategory.values)
        category: (map[category.key] as num?)?.toDouble() ?? 0,
    };
  }

  List<UrbanIssue> _issuesFromList(dynamic value) {
    final list = value as List<dynamic>? ?? const [];
    return list
        .map((item) {
          final map = item is Map
              ? Map<String, dynamic>.from(item)
              : const <String, dynamic>{};
          return UrbanIssue(
            title: map['title'] as String? ?? '',
            category: UrbanCategory.fromKey(map['category'] as String?),
            daysOpen: (map['days_open'] as num?)?.toInt() ?? 0,
            severity: (map['severity'] as num?)?.toInt() ?? 0,
          );
        })
        .toList(growable: false);
  }
}

class UnconfiguredPlacesRepository implements PlacesRepository {
  @override
  Future<UrbanReview> addReview({
    required UrbanPlace place,
    required String message,
    required UrbanCategory category,
  }) {
    throw const AuthException('Supabase is not configured.');
  }

  @override
  Future<UrbanPlace> createPlace(UrbanPlace place) {
    throw const AuthException('Supabase is not configured.');
  }

  @override
  Future<List<UrbanPlace>> fetchPlaces() async => const [];

  @override
  Future<Map<String, List<UrbanReview>>> fetchReviewsByPlaceId() async =>
      const {};
}
