import 'package:flutter/material.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.places});

  final List<UrbanPlace> places;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16),
      children: [
        _HeroStats(
          cityScore: cityScore,
          placesCount: places.length,
          openIssues: places.fold<int>(
            0,
            (sum, place) => sum + place.issues.length,
          ),
          avgFixDays: avgFixDays,
        ),
        const SizedBox(height: 16),
        const Text(
          'AI alerts',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(alert),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Top places by UrbanScore',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
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
    required this.cityScore,
    required this.placesCount,
    required this.openIssues,
    required this.avgFixDays,
  });

  final int cityScore;
  final int placesCount;
  final int openIssues;
  final int avgFixDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1C3F37), Color(0xFF2D6A5D), Color(0xFF88A96B)],
        ),
      ),
      child: Wrap(
        runSpacing: 12,
        spacing: 12,
        children: [
          _StatItem(label: 'City score', value: '$cityScore/100'),
          _StatItem(label: 'Monitored places', value: '$placesCount'),
          _StatItem(label: 'Open issues', value: '$openIssues'),
          _StatItem(label: 'Avg time-to-fix', value: '$avgFixDays d'),
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
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
    final score = UrbanScoreService.overallScore(place);
    final color = UrbanScoreService.scoreColor(score);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          child: Icon(place.type.icon, color: color),
        ),
        title: Text(place.name),
        subtitle: Text('${place.type.label} | ${place.address}'),
        trailing: Text(
          score.round().toString(),
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }
}
