import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
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
  String? _error;
  RewardProgress? _rewardProgress;

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
          _SwipePlaceCard(place: current),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sending ? null : () => _startReviewFlow(SwipeDirection.left),
                  icon: const Icon(Icons.close_rounded),
                  label: Text(loc.tr('swipe_left')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sending ? null : () => _startReviewFlow(SwipeDirection.right),
                  icon: const Icon(Icons.favorite_rounded),
                  label: Text(loc.tr('swipe_right')),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _loadDeck() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fetched = await widget.repository.fetchSwipeCandidates();
      final reward = await widget.repository.fetchRewardProgress();
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

  Future<void> _startReviewFlow(SwipeDirection direction) async {
    if (_index >= _deck.length) {
      return;
    }
    final place = _deck[_index];
    final payload = await showDialog<_DialogReviewSubmission>(
      context: context,
      builder: (_) => _ReviewSubmissionDialog(place: place, direction: direction),
    );
    if (payload == null) {
      return;
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
        return;
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
    } catch (error) {
      if (!mounted) {
        return;
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
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }
}

class _SwipePlaceCard extends StatelessWidget {
  const _SwipePlaceCard({required this.place});

  final UrbanPlace place;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                child: Icon(place.type.icon, color: AppTheme.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(place.address, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 10),
          Text(
            place.description,
            style: const TextStyle(height: 1.5, color: AppTheme.textMuted),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
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
    return AlertDialog(
      title: Text(
        widget.direction == SwipeDirection.right
            ? loc.tr('review_dialog_like_title')
            : loc.tr('review_dialog_dislike_title'),
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                DropdownButtonFormField<UrbanCategory>(
                  initialValue: _category,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text('${loc.tr('rating')}: $_rating/5')),
                    Expanded(
                      flex: 2,
                      child: Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: _rating.toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _rating = value.round();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickMedia,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(loc.tr('attach_media')),
                  ),
                ),
                if (_mediaFiles.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _mediaFiles
                          .map((file) => Chip(label: Text(file.name, overflow: TextOverflow.ellipsis)))
                          .toList(growable: false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.tr('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(loc.tr('submit_review')),
        ),
      ],
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
