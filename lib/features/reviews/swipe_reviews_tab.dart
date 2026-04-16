import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/data/place_photo_service.dart';
import 'package:hackathon_net/features/reviews/data/swipe_reviews_repository.dart';

class SwipeReviewsTab extends StatefulWidget {
  const SwipeReviewsTab({
    super.key,
    required this.repository,
    required this.seedPlaces,
  });

  final SwipeReviewsRepository repository;
  final List<UrbanPlace> seedPlaces;

  @override
  State<SwipeReviewsTab> createState() => _SwipeReviewsTabState();
}

class _SwipeReviewsTabState extends State<SwipeReviewsTab> {
  List<UrbanPlace> _deck = const [];
  int _index = 0;
  bool _loading = true;
  bool _sending = false;
  bool _swipeAnimating = false;
  String? _error;
  RewardProgress? _rewardProgress;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final remaining = _deck.length - _index;
    final current = _index < _deck.length ? _deck[_index] : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        SectionEyebrow(label: loc.tr('swipe_reviews')),
        const SizedBox(height: 14),
        Text(
          loc.tr('swipe_reviews_title'),
          style: const TextStyle(
            fontSize: 30,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          loc.tr('swipe_reviews_body'),
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _RewardProgressPanel(progress: _rewardProgress),
        const SizedBox(height: 16),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        else if (_error != null)
          GlassPanel(
            child: ListTile(
              leading: const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
              title: Text(loc.tr('swipe_load_failed')),
              subtitle: Text(_error!),
              trailing: TextButton(onPressed: _loadDeck, child: Text(loc.tr('retry'))),
            ),
          )
        else if (current == null)
          GlassPanel(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.accent),
              title: Text(loc.tr('swipe_done_title')),
              subtitle: Text(loc.tr('swipe_done_subtitle')),
              trailing: TextButton(onPressed: _loadDeck, child: Text(loc.tr('reload_deck'))),
            ),
          )
        else ...[
          Text(
            '${loc.tr('remaining_places')}: $remaining',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final threshold = math.max(110.0, width * 0.22);
              final swipeFraction = (_dragOffset.dx / threshold).clamp(-1.4, 1.4);
              final leftActive = swipeFraction < -0.35;
              final rightActive = swipeFraction > 0.35;

              return Column(
                children: [
                  SizedBox(
                    height: 470,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _SwipeCue(
                                icon: Icons.close_rounded,
                                label: loc.tr('swipe_left'),
                                alignment: Alignment.centerLeft,
                                active: leftActive,
                                color: AppTheme.danger,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _SwipeCue(
                                icon: Icons.favorite_rounded,
                                label: loc.tr('swipe_right'),
                                alignment: Alignment.centerRight,
                                active: rightActive,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onPanUpdate: _sending || _swipeAnimating
                              ? null
                              : (details) {
                                  setState(() {
                                    _dragOffset += Offset(details.delta.dx, 0);
                                  });
                                },
                          onPanEnd: _sending || _swipeAnimating
                              ? null
                              : (_) => _handleSwipeRelease(
                                  threshold: threshold,
                                  width: width,
                                ),
                          onPanCancel: _sending || _swipeAnimating
                              ? null
                              : () {
                                  setState(() {
                                    _dragOffset = Offset.zero;
                                  });
                                },
                          child: AnimatedContainer(
                            duration: Duration(
                              milliseconds: _swipeAnimating ? 180 : 220,
                            ),
                            curve: Curves.easeOutCubic,
                            transform: Matrix4.identity()
                              ..translate(_dragOffset.dx, 0.0)
                              ..rotateZ((_dragOffset.dx / width) * 0.08),
                            child: SizedBox(
                              width: width,
                              child: _SwipePlaceCard(
                                place: current,
                                swipeFraction: swipeFraction.toDouble(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Drag the card left or right with your mouse to submit a swipe.',
                    style: TextStyle(color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _loadDeck() async {
    setState(() {
      _loading = true;
      _error = null;
      _dragOffset = Offset.zero;
    });
    try {
      final fetched = await widget.repository.fetchSwipeCandidates();
      RewardProgress? reward = _rewardProgress;
      try {
        reward = await widget.repository.fetchRewardProgress();
      } catch (_) {
        // Keep the deck usable even if reward progress is temporarily unavailable.
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _rewardProgress = reward;
        _deck = fetched.isEmpty ? widget.seedPlaces : fetched;
        _index = 0;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<bool> _startReviewFlow(SwipeDirection direction) async {
    if (_index >= _deck.length) {
      return false;
    }
    final place = _deck[_index];
    final payload = await showDialog<_DialogReviewSubmission>(
      context: context,
      builder: (_) => _ReviewSubmissionDialog(place: place, direction: direction),
    );
    if (payload == null) {
      return false;
    }

    setState(() {
      _sending = true;
    });
    try {
      await widget.repository.submitSwipeReview(
        SwipeReviewSubmission(
          organizationId: place.id,
          direction: direction,
          summary: payload.summary,
          details: payload.details,
          category: payload.category,
          rating: payload.rating,
          mediaFiles: payload.mediaFiles,
        ),
      );
      final reward = await widget.repository.fetchRewardProgress();
      if (!mounted) {
        return false;
      }
      setState(() {
        _rewardProgress = reward;
        _index += 1;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).tr('review_submitted_admin'))),
        );
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).tr('review_submit_failed')} ${error.toString()}',
            ),
          ),
        );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _handleSwipeRelease({
    required double threshold,
    required double width,
  }) async {
    if (_dragOffset.dx.abs() < threshold) {
      setState(() {
        _dragOffset = Offset.zero;
      });
      return;
    }

    final direction = _dragOffset.dx >= 0
        ? SwipeDirection.right
        : SwipeDirection.left;
    final exitX = direction == SwipeDirection.right ? width * 1.25 : -width * 1.25;

    setState(() {
      _swipeAnimating = true;
      _dragOffset = Offset(exitX, 0);
    });

    await Future<void>.delayed(const Duration(milliseconds: 190));
    if (!mounted) {
      return;
    }

    final submitted = await _startReviewFlow(direction);
    if (!mounted) {
      return;
    }

    setState(() {
      _swipeAnimating = false;
      _dragOffset = Offset.zero;
      if (submitted && _index >= _deck.length) {
        _dragOffset = Offset.zero;
      }
    });
  }
}

class _SwipePlaceCard extends StatelessWidget {
  const _SwipePlaceCard({
    required this.place,
    required this.swipeFraction,
  });

  final UrbanPlace place;
  final double swipeFraction;

  @override
  Widget build(BuildContext context) {
    final tintColor = swipeFraction >= 0
        ? AppTheme.accent
        : AppTheme.danger;
    final overlayOpacity = swipeFraction.abs().clamp(0.0, 1.0) * 0.18;

    return GlassPanel(
      borderRadius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: _PlaceCardImage(place: place),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.54),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              if (overlayOpacity > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tintColor.withValues(alpha: overlayOpacity),
                    ),
                  ),
                ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.accent.withValues(alpha: 0.22),
                      child: Icon(place.type.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.address,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Text(
                  place.description,
                  style: const TextStyle(height: 1.5, color: AppTheme.textMuted),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniPill(
                      icon: Icons.location_city_rounded,
                      label: place.type.label,
                    ),
                    if (place.photoUrl != null)
                      const _MiniPill(
                        icon: Icons.photo_camera_back_rounded,
                        label: 'Place photo',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceCardImage extends StatefulWidget {
  const _PlaceCardImage({required this.place});

  final UrbanPlace place;

  @override
  State<_PlaceCardImage> createState() => _PlaceCardImageState();
}

class _PlaceCardImageState extends State<_PlaceCardImage> {
  final PlacePhotoService _placePhotoService = const PlacePhotoService();
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    _resolvedUrl = widget.place.photoUrl ?? widget.place.detectionPreviewUrl;
    if (_resolvedUrl == null && widget.place.type != UrbanPlaceType.incident) {
      _lookupPhoto();
    }
  }

  @override
  void didUpdateWidget(covariant _PlaceCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.id != widget.place.id ||
        oldWidget.place.photoUrl != widget.place.photoUrl) {
      _resolvedUrl = widget.place.photoUrl ?? widget.place.detectionPreviewUrl;
      if (_resolvedUrl == null && widget.place.type != UrbanPlaceType.incident) {
        _lookupPhoto();
      }
    }
  }

  Future<void> _lookupPhoto() async {
    final url = await _placePhotoService.lookupPhotoUrl(
      name: widget.place.name,
      address: widget.place.address,
      latitude: widget.place.location.latitude,
      longitude: widget.place.location.longitude,
    );
    if (!mounted || url == null || url.isEmpty) {
      return;
    }
    setState(() {
      _resolvedUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolvedUrl;
    if (imageUrl == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF173545),
              const Color(0xFF24485B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            widget.place.type.icon,
            color: Colors.white.withValues(alpha: 0.88),
            size: 72,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF173545), Color(0xFF24485B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white70,
            size: 56,
          ),
        ),
      ),
    );
  }
}

class _SwipeCue extends StatelessWidget {
  const _SwipeCue({
    required this.icon,
    required this.label,
    required this.alignment,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: active ? color.withValues(alpha: 0.16) : AppTheme.glassLight,
        border: Border.all(
          color: active ? color.withValues(alpha: 0.55) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: active ? color : AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? color : AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.glassLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardProgressPanel extends StatelessWidget {
  const _RewardProgressPanel({required this.progress});

  final RewardProgress? progress;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final data =
        progress ??
        const RewardProgress(
          approvedReviews: 0,
          currentMilestone: 0,
          reviewsUntilNextMilestone: 1000,
        );

    final nextMilestone = (data.currentMilestone + 1) * 1000;
    final consumed = data.approvedReviews % 1000;
    final progressValue = consumed / 1000;

    return GlassPanel(
      borderRadius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('reward_progress'), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '${loc.tr('approved_reviews')}: ${data.approvedReviews} | ${loc.tr('current_milestone')}: ${data.currentMilestone}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppTheme.glassLight,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
          ),
          const SizedBox(height: 8),
          Text(
            '${loc.tr('next_reward_at')} $nextMilestone | ${loc.tr('reviews_left')}: ${data.reviewsUntilNextMilestone}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _DialogReviewSubmission {
  const _DialogReviewSubmission({
    required this.summary,
    required this.details,
    required this.category,
    required this.rating,
    required this.mediaFiles,
  });

  final String summary;
  final String details;
  final UrbanCategory category;
  final int rating;
  final List<PlatformFile> mediaFiles;
}

class _ReviewSubmissionDialog extends StatefulWidget {
  const _ReviewSubmissionDialog({required this.place, required this.direction});

  final UrbanPlace place;
  final SwipeDirection direction;

  @override
  State<_ReviewSubmissionDialog> createState() => _ReviewSubmissionDialogState();
}

class _ReviewSubmissionDialogState extends State<_ReviewSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();
  final List<PlatformFile> _mediaFiles = <PlatformFile>[];
  UrbanCategory _category = UrbanCategory.safety;
  int _rating = 3;

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: AppTheme.bgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.direction == SwipeDirection.right
                      ? loc.tr('review_dialog_like_title')
                      : loc.tr('review_dialog_dislike_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _summaryController,
                  decoration: InputDecoration(labelText: loc.tr('experience_summary')),
                  validator: (value) {
                    if (value == null || value.trim().length < 8) {
                      return loc.tr('summary_validation');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailsController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: loc.tr('experience_details')),
                  validator: (value) {
                    if (value == null || value.trim().length < 16) {
                      return loc.tr('details_validation');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UrbanCategory>(
                  initialValue: _category,
                  dropdownColor: AppTheme.bgSecondary,
                  items: UrbanCategory.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(AppLocalizations.of(context).categoryLabel(item)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _category = value;
                    });
                  },
                  decoration: InputDecoration(labelText: loc.tr('comment_category')),
                ),
                const SizedBox(height: 16),
                Text(
                  '${loc.tr('rating')}: $_rating/5',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starIndex;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          starIndex <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: starIndex <= _rating
                              ? AppTheme.accent
                              : AppTheme.textMuted,
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _pickMedia,
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(loc.tr('attach_media')),
                ),
                if (_mediaFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _mediaFiles
                          .map((file) => Chip(
                                label: Text(file.name, overflow: TextOverflow.ellipsis),
                                backgroundColor: AppTheme.glassLight,
                                side: const BorderSide(color: AppTheme.glassBorder),
                              ))
                          .toList(growable: false),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(loc.tr('cancel')),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(loc.tr('submit_review')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia() async {
    final selected = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'mp4', 'mov'],
    );
    if (selected == null || selected.files.isEmpty) {
      return;
    }
    setState(() {
      for (final file in selected.files) {
        if (_mediaFiles.length >= 5) {
          break;
        }
        _mediaFiles.add(file);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _DialogReviewSubmission(
        summary: _summaryController.text.trim(),
        details: _detailsController.text.trim(),
        category: _category,
        rating: _rating,
        mediaFiles: List<PlatformFile>.unmodifiable(_mediaFiles),
      ),
    );
  }
}
