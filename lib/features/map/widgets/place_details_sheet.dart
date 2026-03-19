import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';

class PlaceDetailsSheet extends StatelessWidget {
  const PlaceDetailsSheet({super.key, required this.place});

  final UrbanPlace place;

  @override
  Widget build(BuildContext context) {
    final total = UrbanScoreService.overallScore(place).round();
    final breakdown = UrbanScoreService.breakdown(place);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      child: Icon(place.type.icon, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$total/100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: UrbanScoreService.scoreColor(total.toDouble()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${place.type.label} | ${place.address}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  place.description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                const SectionEyebrow(label: 'Score breakdown'),
                const SizedBox(height: 10),
                for (final category in UrbanCategory.values) ...[
                  _CategoryRow(
                    category: category,
                    value: (breakdown[category] ?? 0).round(),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 14),
                const SectionEyebrow(label: 'Open issues'),
                const SizedBox(height: 8),
                if (place.issues.isEmpty)
                  const Text('No open issues.')
                else
                  for (final issue in place.issues)
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
                            '${issue.category.label} | ${issue.daysOpen} days open',
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 14),
                const SectionEyebrow(label: 'Citizen comments'),
                const SizedBox(height: 8),
                if (place.reviews.isEmpty)
                  const Text('No comments yet.')
                else
                  for (final review in place.reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassPanel(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(14),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(review.author),
                          subtitle: Text(review.message),
                          trailing: Text('${review.daysAgo}d'),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.value});

  final UrbanCategory category;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(category.icon, size: 16, color: category.color),
            const SizedBox(width: 8),
            Expanded(child: Text(category.label)),
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
