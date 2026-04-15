import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/features/reviews/data/swipe_reviews_repository.dart';

class AdminModerationPanel extends StatefulWidget {
  const AdminModerationPanel({super.key, required this.repository});

  final SwipeReviewsRepository repository;

  @override
  State<AdminModerationPanel> createState() => _AdminModerationPanelState();
}

class _AdminModerationPanelState extends State<AdminModerationPanel> {
  bool _loading = true;
  bool _moderating = false;
  String? _error;
  List<ModerationReviewItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_loading) {
      return const GlassPanel(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        ),
      );
    }
    if (_error != null) {
      return GlassPanel(
        child: ListTile(
          leading: const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          title: Text(loc.tr('moderation_load_failed')),
          subtitle: Text(_error!),
          trailing: TextButton(onPressed: _load, child: Text(loc.tr('retry'))),
        ),
      );
    }
    if (_items.isEmpty) {
      return GlassPanel(
        child: ListTile(
          leading: const Icon(Icons.fact_check_outlined, color: AppTheme.accent),
          title: Text(loc.tr('moderation_queue_empty')),
          subtitle: Text(loc.tr('moderation_queue_empty_body')),
        ),
      );
    }

    return Column(
      children: _items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.organizationName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.authorName} | ${AppLocalizations.of(context).categoryLabel(item.category)} | ${item.rating}/5',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(item.summary, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(item.details, style: const TextStyle(color: AppTheme.textMuted, height: 1.45)),
                      if (item.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: item.mediaUrls
                              .map(
                                (url) => InkWell(
                                  onTap: () => _showMediaDialog(url),
                                  child: Chip(
                                    avatar: const Icon(Icons.perm_media_rounded, size: 16),
                                    label: Text(loc.tr('attached_media')),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _moderating
                                  ? null
                                  : () => _moderate(item, approved: false),
                              icon: const Icon(Icons.close_rounded),
                              label: Text(loc.tr('reject')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _moderating
                                  ? null
                                  : () => _moderate(item, approved: true),
                              icon: const Icon(Icons.check_rounded),
                              label: Text(loc.tr('approve')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.repository.fetchPendingReviews();
      if (!mounted) {
        return;
      }
      setState(() {
        _items = data;
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

  Future<void> _moderate(
    ModerationReviewItem item, {
    required bool approved,
  }) async {
    final reason = await _askReason(approved: approved);
    if (reason == null) {
      return;
    }
    setState(() {
      _moderating = true;
    });
    try {
      await widget.repository.moderateReview(
        reviewId: item.reviewId,
        approved: approved,
        reason: reason,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = _items.where((entry) => entry.reviewId != item.reviewId).toList(growable: false);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _moderating = false;
        });
      }
    }
  }

  Future<String?> _askReason({required bool approved}) async {
    final loc = AppLocalizations.of(context);
    final controller = TextEditingController();
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approved ? loc.tr('approve') : loc.tr('reject')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: loc.tr('moderation_reason')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.tr('cancel'))),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(loc.tr('save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (selected == null || selected.isEmpty) {
      return approved ? 'constructive_and_adequate' : 'not_constructive';
    }
    return selected;
  }

  Future<void> _showMediaDialog(String url) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Media'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).tr('close')),
          ),
        ],
      ),
    );
  }
}
