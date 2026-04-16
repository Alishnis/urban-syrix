import 'package:file_picker/file_picker.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SwipeDirection { right, left }

enum ReviewModerationStatus { pending, approved, rejected, published }

class SwipeReviewSubmission {
  const SwipeReviewSubmission({
    required this.organizationId,
    required this.direction,
    required this.summary,
    required this.details,
    required this.category,
    required this.rating,
    required this.mediaFiles,
  });

  final String organizationId;
  final SwipeDirection direction;
  final String summary;
  final String details;
  final UrbanCategory category;
  final int rating;
  final List<PlatformFile> mediaFiles;
}

class ModerationReviewItem {
  const ModerationReviewItem({
    required this.reviewId,
    required this.organizationId,
    required this.organizationName,
    required this.authorName,
    required this.summary,
    required this.details,
    required this.category,
    required this.rating,
    required this.mediaUrls,
    required this.createdAt,
  });

  final String reviewId;
  final String organizationId;
  final String organizationName;
  final String authorName;
  final String summary;
  final String details;
  final UrbanCategory category;
  final int rating;
  final List<String> mediaUrls;
  final DateTime createdAt;
}

class RewardProgress {
  const RewardProgress({
    required this.approvedReviews,
    required this.currentMilestone,
    required this.reviewsUntilNextMilestone,
  });

  final int approvedReviews;
  final int currentMilestone;
  final int reviewsUntilNextMilestone;
}

abstract class SwipeReviewsRepository {
  Future<List<UrbanPlace>> fetchSwipeCandidates();
  Future<void> submitSwipeReview(SwipeReviewSubmission submission);
  Future<List<ModerationReviewItem>> fetchPendingReviews();
  Future<void> moderateReview({
    required String reviewId,
    required bool approved,
    required String reason,
    String? note,
  });
  Future<RewardProgress> fetchRewardProgress();
}

class SupabaseSwipeReviewsRepository implements SwipeReviewsRepository {
  SupabaseSwipeReviewsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<UrbanPlace>> fetchSwipeCandidates() async {
    final response = await _client
        .from('urban_places')
        .select(
          'id, name, type, incident_subtype, photo_url, detection_model, detection_preview_url, address, description, latitude, longitude, developer, '
          'traffic_risk, co2_footprint, green_coverage, base_scores, issues',
        )
        .neq('type', 'incident')
        .order('created_at', ascending: false)
        .limit(40);

    return response
        .map<UrbanPlace>((row) => _placeFromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<void> submitSwipeReview(SwipeReviewSubmission submission) async {
    final mediaUrls = await _uploadMedia(submission.mediaFiles);

    await _client.rpc(
      'submit_swipe_review',
      params: {
        'p_organization_id': submission.organizationId,
        'p_direction': submission.direction == SwipeDirection.right
            ? 'right'
            : 'left',
        'p_summary': submission.summary,
        'p_details': submission.details,
        'p_category': submission.category.key,
        'p_rating': submission.rating,
        'p_media_urls': mediaUrls,
      },
    );
  }

  @override
  Future<List<ModerationReviewItem>> fetchPendingReviews() async {
    final response = await _client
        .from('swipe_reviews')
        .select('''
          id,
          organization_id,
          user_id,
          summary,
          details,
          category,
          rating,
          media_urls,
          created_at,
          urban_places(name)
        ''')
        .eq('moderation_status', 'pending')
        .order('created_at', ascending: true);

    // Collect unique user IDs to resolve author names from profiles table.
    final userIds = <String>{};
    for (final row in response) {
      final uid = row['user_id'] as String?;
      if (uid != null && uid.isNotEmpty) {
        userIds.add(uid);
      }
    }

    // Fetch profile emails in one go (if any users exist).
    final Map<String, String> emailByUserId = {};
    if (userIds.isNotEmpty) {
      try {
        final profiles = await _client
            .from('profiles')
            .select('id, email')
            .inFilter('id', userIds.toList());
        for (final p in profiles) {
          final id = p['id'] as String?;
          final email = p['email'] as String?;
          if (id != null && email != null) {
            emailByUserId[id] = email;
          }
        }
      } catch (_) {
        // Profiles lookup is best-effort; fall back to user ID prefix.
      }
    }

    return response.map<ModerationReviewItem>((row) {
      final map = Map<String, dynamic>.from(row);
      final placeMap = map['urban_places'] is Map
          ? Map<String, dynamic>.from(map['urban_places'] as Map)
          : const <String, dynamic>{};
      final userId = map['user_id'] as String? ?? '';
      final email = emailByUserId[userId] ?? 'user-${userId.substring(0, (userId.length < 8 ? userId.length : 8))}';
      final media = (map['media_urls'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false);
      return ModerationReviewItem(
        reviewId: map['id'].toString(),
        organizationId: map['organization_id'].toString(),
        organizationName: placeMap['name'] as String? ?? 'Unknown place',
        authorName: email.contains('@') ? email.split('@').first : email,
        summary: map['summary'] as String? ?? '',
        details: map['details'] as String? ?? '',
        category: UrbanCategory.fromKey(map['category'] as String?),
        rating: (map['rating'] as num?)?.toInt() ?? 3,
        mediaUrls: media,
        createdAt:
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
            DateTime.now().toUtc(),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> moderateReview({
    required String reviewId,
    required bool approved,
    required String reason,
    String? note,
  }) async {
    await _client.rpc(
      'moderate_swipe_review',
      params: {
        'p_review_id': reviewId,
        'p_decision': approved ? 'approved' : 'rejected',
        'p_reason': reason,
        'p_note': note,
      },
    );
  }

  @override
  Future<RewardProgress> fetchRewardProgress() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const RewardProgress(
        approvedReviews: 0,
        currentMilestone: 0,
        reviewsUntilNextMilestone: 1000,
      );
    }

    final response = await _client
        .from('swipe_reviews')
        .select('id')
        .eq('user_id', user.id)
        .inFilter('moderation_status', ['approved', 'published']);

    final approvedReviews = response.length;
    final milestone = approvedReviews ~/ 1000;
    final remainder = approvedReviews % 1000;
    final remaining = remainder == 0 ? 1000 : 1000 - remainder;
    return RewardProgress(
      approvedReviews: approvedReviews,
      currentMilestone: milestone,
      reviewsUntilNextMilestone: remaining,
    );
  }

  Future<List<String>> _uploadMedia(List<PlatformFile> files) async {
    if (files.isEmpty) {
      return const <String>[];
    }
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication required');
    }

    final urls = <String>[];
    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }
      final ext = _fileExtension(file.name);
      final path =
          '${user.id}/${DateTime.now().microsecondsSinceEpoch}_${file.name}';
      await _client.storage.from('swipe-review-media').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeFromExt(ext),
          upsert: false,
        ),
      );
      urls.add(_client.storage.from('swipe-review-media').getPublicUrl(path));
    }
    return urls;
  }

  UrbanPlace _placeFromMap(Map<String, dynamic> map) {
    return UrbanPlace(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      type: UrbanPlaceType.fromKey(map['type'] as String?),
      incidentSubtype: map['incident_subtype'] == null
          ? null
          : IncidentSubtype.fromKey(map['incident_subtype'] as String?),
      photoUrl: map['photo_url'] as String?,
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

  String _fileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return '';
    }
    return parts.last.toLowerCase();
  }

  String _contentTypeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}

class UnconfiguredSwipeReviewsRepository implements SwipeReviewsRepository {
  @override
  Future<List<UrbanPlace>> fetchSwipeCandidates() async => const [];

  @override
  Future<List<ModerationReviewItem>> fetchPendingReviews() async => const [];

  @override
  Future<RewardProgress> fetchRewardProgress() async => const RewardProgress(
    approvedReviews: 0,
    currentMilestone: 0,
    reviewsUntilNextMilestone: 1000,
  );

  @override
  Future<void> moderateReview({
    required String reviewId,
    required bool approved,
    required String reason,
    String? note,
  }) {
    throw const AuthException('Supabase is not configured.');
  }

  @override
  Future<void> submitSwipeReview(SwipeReviewSubmission submission) {
    throw const AuthException('Supabase is not configured.');
  }
}
