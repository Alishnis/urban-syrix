import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class PlaceDetailsSheet extends StatefulWidget {
  const PlaceDetailsSheet({
    super.key,
    required this.place,
    required this.onAddReview,
  });

  final UrbanPlace place;
  final Future<UrbanReview> Function({
    required String message,
    required UrbanCategory category,
  })
  onAddReview;

  @override
  State<PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends State<PlaceDetailsSheet> {
  final _reviewController = TextEditingController();
  final _reviewFormKey = GlobalKey<FormState>();
  late UrbanPlace _place;
  UrbanCategory _selectedCategory = UrbanCategory.safety;
  bool _isSavingReview = false;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isIncident = _place.type == UrbanPlaceType.incident;
    final showMetaChips =
        !isIncident &&
        (_place.incidentSubtype != null || _place.detectionModel != null);
    final total = UrbanScoreService.overallScore(_place).round();
    final breakdown = UrbanScoreService.breakdown(_place);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PointerInterceptor(
          child: GlassPanel(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _place.type.icon,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _place.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isIncident)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.danger.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            _place.incidentSubtype != null
                                ? loc.incidentDetectionLabel(
                                    _place.incidentSubtype!,
                                  )
                                : loc.tr('live_incident'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.danger,
                            ),
                          ),
                        )
                      else
                        Text(
                          '$total/100',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: UrbanScoreService.scoreColor(
                              total.toDouble(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${loc.placeTypeLabel(_place.type)} | ${_place.address}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  if (showMetaChips) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_place.incidentSubtype != null)
                          Chip(
                            avatar: Icon(
                              _place.incidentSubtype!.icon,
                              size: 18,
                            ),
                            label: Text(
                              loc.incidentSubtypeLabel(_place.incidentSubtype!),
                            ),
                          ),
                        if (_place.detectionModel != null)
                          Chip(
                            avatar: const Icon(Icons.memory_rounded, size: 18),
                            label: Text(_place.detectionModel!),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_place.photoUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          _place.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppTheme.bgTertiary,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Text(
                    _place.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isIncident) ...[
                    SectionEyebrow(label: loc.tr('incident_summary')),
                    const SizedBox(height: 10),
                    GlassPanel(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(16),
                      blur: false,
                      backgroundColor: const Color(0xFF161D29),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IncidentMetaRow(
                            label: loc.tr('detected_event'),
                            value: _place.incidentSubtype != null
                                ? loc.incidentDetectionLabel(
                                    _place.incidentSubtype!,
                                  )
                                : loc.tr('live_incident'),
                            icon:
                                _place.incidentSubtype?.icon ??
                                Icons.warning_amber_rounded,
                          ),
                          if (_place.detectionModel != null) ...[
                            const SizedBox(height: 12),
                            _IncidentMetaRow(
                              label: loc.tr('detection_model'),
                              value: _place.detectionModel!,
                              icon: Icons.memory_rounded,
                            ),
                          ],
                          if (_place.detectionPreviewUrl != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              loc.tr('detection_preview'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _place.detectionPreviewUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgTertiary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    loc.tr('preview_unavailable'),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            loc.tr('incident_description_only'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SectionEyebrow(label: loc.tr('score_breakdown')),
                    const SizedBox(height: 10),
                    for (final category in UrbanCategory.values) ...[
                      _CategoryRow(
                        category: category,
                        value: (breakdown[category] ?? 0).round(),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                    SectionEyebrow(label: loc.tr('open_issues')),
                    const SizedBox(height: 8),
                    if (_place.issues.isEmpty)
                      Text(loc.tr('no_open_issues'))
                    else
                      for (final issue in _place.issues)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassPanel(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.error_outline_rounded),
                              title: Text(issue.title),
                              subtitle: Text(
                                '${loc.categoryLabel(issue.category)} | ${issue.daysOpen} ${loc.tr('days_open')}',
                              ),
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 14),
                  SectionEyebrow(label: loc.tr('citizen_comments')),
                  const SizedBox(height: 12),
                  GlassPanel(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(16),
                    blur: false,
                    backgroundColor: const Color(0xFF161D29),
                    child: Form(
                      key: _reviewFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _reviewController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: loc.tr('leave_comment'),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return loc.tr('enter_comment');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<UrbanCategory>(
                            initialValue: _selectedCategory,
                            dropdownColor: AppTheme.bgTertiary,
                            decoration: InputDecoration(
                              labelText: loc.tr('comment_category'),
                            ),
                            items: UrbanCategory.values
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(loc.categoryLabel(category)),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          if (_reviewError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _reviewError!,
                              style: const TextStyle(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _isSavingReview ? null : _submitReview,
                              icon: const Icon(Icons.send_rounded),
                              label: Text(
                                _isSavingReview
                                    ? loc.tr('adding')
                                    : loc.tr('post_comment'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_place.reviews.isEmpty)
                    Text(loc.tr('no_comments'))
                  else
                    for (final review in _place.reviews)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassPanel(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(14),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(review.author),
                            subtitle: Text(
                              '${loc.categoryLabel(review.category)}\n${review.message}',
                            ),
                            isThreeLine: true,
                            trailing: Text('${review.daysAgo}d'),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_reviewFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSavingReview = true;
      _reviewError = null;
    });

    try {
      final review = await widget.onAddReview(
        message: _reviewController.text.trim(),
        category: _selectedCategory,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _place = _place.copyWith(reviews: [review, ..._place.reviews]);
        _reviewController.clear();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _reviewError = AppLocalizations.of(context).tr('comment_save_failed');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSavingReview = false;
        });
      }
    }
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.value});

  final UrbanCategory category;
  final int value;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Icon(category.icon, size: 16, color: category.color),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.categoryLabel(category))),
            Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          minHeight: 8,
          value: value / 100,
          borderRadius: BorderRadius.circular(999),
          valueColor: AlwaysStoppedAnimation(category.color),
          backgroundColor: AppTheme.glassMedium,
        ),
      ],
    );
  }
}

class _IncidentMetaRow extends StatelessWidget {
  const _IncidentMetaRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.glassLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
