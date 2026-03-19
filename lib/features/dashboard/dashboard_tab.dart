import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.places});

  final List<UrbanPlace> places;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final cityScore = UrbanScoreService.cityAverageScore(places);
    final avgFixDays = UrbanScoreService.averageFixDays(places);
    final alerts = UrbanScoreService.buildAlerts(places);
    final sorted = [...places]
      ..sort(
        (a, b) => UrbanScoreService.overallScore(
          b,
        ).compareTo(UrbanScoreService.overallScore(a)),
      );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        SectionEyebrow(label: loc.tr('city_operations')),
        const SizedBox(height: 14),
        Text(
          loc.tr('dashboard_title'),
          style: TextStyle(
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          loc.tr('dashboard_body'),
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
        _HeroStats(
          loc: loc,
          cityScore: cityScore,
          placesCount: places.length,
          openIssues: places.fold<int>(
            0,
            (sum, place) => sum + place.issues.length,
          ),
          avgFixDays: avgFixDays,
        ),
        const SizedBox(height: 16),
        SectionEyebrow(label: loc.tr('active_alerts')),
        const SizedBox(height: 10),
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        SectionEyebrow(label: loc.tr('top_places')),
        const SizedBox(height: 10),
        for (final place in sorted.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlaceScoreTile(place: place),
          ),
      ],
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({
    required this.loc,
    required this.cityScore,
    required this.placesCount,
    required this.openIssues,
    required this.avgFixDays,
  });

  final AppLocalizations loc;
  final int cityScore;
  final int placesCount;
  final int openIssues;
  final int avgFixDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.glassBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101827), Color(0xFF0E1625), Color(0xFF132B31)],
        ),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.accentGlow,
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Wrap(
        runSpacing: 12,
        spacing: 12,
        children: [
          _StatItem(label: loc.tr('city_score'), value: '$cityScore/100'),
          _StatItem(label: loc.tr('monitored_places'), value: '$placesCount'),
          _StatItem(label: loc.tr('open_issues'), value: '$openIssues'),
          _StatItem(label: loc.tr('avg_fix_time'), value: '$avgFixDays d'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: AppTheme.glassBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceScoreTile extends StatelessWidget {
  const _PlaceScoreTile({required this.place});

  final UrbanPlace place;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final score = UrbanScoreService.overallScore(place);
    final color = UrbanScoreService.scoreColor(score);

    return GlassPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(place.type.icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${loc.placeTypeLabel(place.type)} | ${place.address}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score.round().toString(),
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
