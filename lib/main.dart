import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const UrbanScoreApp());
}

class UrbanScoreApp extends StatelessWidget {
  const UrbanScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UrbanScore',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F5EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5B52),
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF10231E),
          displayColor: const Color(0xFF10231E),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Color(0xFFE1E7DD)),
          ),
        ),
      ),
      home: const UrbanScoreHomePage(),
    );
  }
}

enum UrbanCategory {
  mobility('Mobility', Icons.route_rounded, Color(0xFF2F7AF8)),
  environment('Environment', Icons.eco_rounded, Color(0xFF27966B)),
  resources('Resources', Icons.water_drop_rounded, Color(0xFF1593A5)),
  transparency('Transparency', Icons.construction_rounded, Color(0xFFD97A20)),
  inclusivity(
    'Inclusivity',
    Icons.accessible_forward_rounded,
    Color(0xFF8F62E8),
  ),
  safety('Safety', Icons.shield_moon_rounded, Color(0xFFCC4B4B));

  const UrbanCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

enum MapLayer {
  overall('UrbanScore'),
  mobility('Traffic'),
  environment('Ecology'),
  transparency('Construction'),
  inclusivity('Accessibility'),
  safety('Safety');

  const MapLayer(this.label);

  final String label;
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
    this.verifiedInclusivity = false,
  });

  final String author;
  final String message;
  final UrbanCategory category;
  final int sentiment;
  final int daysAgo;
  final bool verifiedInclusivity;
}

class UrbanZone {
  UrbanZone({
    required this.name,
    required this.kind,
    required this.subtitle,
    required this.position,
    required this.size,
    required this.baseScores,
    required this.trafficRisk,
    required this.co2Footprint,
    required this.greenCoverage,
    required this.developer,
    required this.issues,
    required this.reviews,
  });

  final String name;
  final String kind;
  final String subtitle;
  final Offset position;
  final Size size;
  final Map<UrbanCategory, double> baseScores;
  final int trafficRisk;
  final int co2Footprint;
  final int greenCoverage;
  final String developer;
  final List<UrbanIssue> issues;
  final List<UrbanReview> reviews;
}

class UrbanScoreHomePage extends StatefulWidget {
  const UrbanScoreHomePage({super.key});

  @override
  State<UrbanScoreHomePage> createState() => _UrbanScoreHomePageState();
}

class _UrbanScoreHomePageState extends State<UrbanScoreHomePage> {
  static const Map<UrbanCategory, double> _weights = {
    UrbanCategory.mobility: 0.20,
    UrbanCategory.environment: 0.20,
    UrbanCategory.resources: 0.15,
    UrbanCategory.transparency: 0.15,
    UrbanCategory.inclusivity: 0.15,
    UrbanCategory.safety: 0.15,
  };

  final List<UrbanZone> _zones = [
    UrbanZone(
      name: 'Alem Riverside',
      kind: 'Mixed-use district',
      subtitle: 'Transit-oriented housing and retail cluster',
      position: const Offset(0.12, 0.18),
      size: const Size(0.26, 0.22),
      trafficRisk: 28,
      co2Footprint: 54,
      greenCoverage: 61,
      developer: 'Nova Development',
      baseScores: const {
        UrbanCategory.mobility: 82,
        UrbanCategory.environment: 76,
        UrbanCategory.resources: 70,
        UrbanCategory.transparency: 68,
        UrbanCategory.inclusivity: 59,
        UrbanCategory.safety: 73,
      },
      issues: [
        const UrbanIssue(
          title: 'No tactile guidance near tram stop',
          category: UrbanCategory.inclusivity,
          daysOpen: 25,
          severity: 4,
        ),
        const UrbanIssue(
          title: 'Night construction noise',
          category: UrbanCategory.transparency,
          daysOpen: 12,
          severity: 3,
        ),
      ],
      reviews: [
        const UrbanReview(
          author: 'Aruzhan',
          message: 'Bike lane is smooth, but crossings still feel unsafe.',
          category: UrbanCategory.mobility,
          sentiment: 1,
          daysAgo: 2,
        ),
        const UrbanReview(
          author: 'Dias',
          message: 'Ramp exists, but navigation is poor for wheelchair users.',
          category: UrbanCategory.inclusivity,
          sentiment: -1,
          daysAgo: 1,
          verifiedInclusivity: true,
        ),
      ],
    ),
    UrbanZone(
      name: 'TechnoPark Hub',
      kind: 'Office and startup quarter',
      subtitle: 'High-density campus around BRT corridor',
      position: const Offset(0.46, 0.12),
      size: const Size(0.22, 0.18),
      trafficRisk: 36,
      co2Footprint: 62,
      greenCoverage: 44,
      developer: 'Qala Urban Lab',
      baseScores: const {
        UrbanCategory.mobility: 67,
        UrbanCategory.environment: 58,
        UrbanCategory.resources: 75,
        UrbanCategory.transparency: 80,
        UrbanCategory.inclusivity: 64,
        UrbanCategory.safety: 71,
      },
      issues: [
        const UrbanIssue(
          title: 'Heat island around parking deck',
          category: UrbanCategory.environment,
          daysOpen: 18,
          severity: 3,
        ),
      ],
      reviews: [
        const UrbanReview(
          author: 'Sanzhar',
          message: 'Great bus access, but lunchtime traffic is getting worse.',
          category: UrbanCategory.mobility,
          sentiment: -1,
          daysAgo: 3,
        ),
      ],
    ),
    UrbanZone(
      name: 'Old Town Gateway',
      kind: 'Historic neighborhood',
      subtitle: 'Tourist, residential, and public-service zone',
      position: const Offset(0.28, 0.52),
      size: const Size(0.24, 0.2),
      trafficRisk: 22,
      co2Footprint: 48,
      greenCoverage: 68,
      developer: 'Municipal District',
      baseScores: const {
        UrbanCategory.mobility: 74,
        UrbanCategory.environment: 81,
        UrbanCategory.resources: 66,
        UrbanCategory.transparency: 72,
        UrbanCategory.inclusivity: 47,
        UrbanCategory.safety: 62,
      },
      issues: [
        const UrbanIssue(
          title: 'Steep entrances without ramp',
          category: UrbanCategory.inclusivity,
          daysOpen: 32,
          severity: 5,
        ),
        const UrbanIssue(
          title: 'Low lighting on pedestrian street',
          category: UrbanCategory.safety,
          daysOpen: 16,
          severity: 3,
        ),
      ],
      reviews: [
        const UrbanReview(
          author: 'Mira',
          message: 'Beautiful and green, but evening route feels dark.',
          category: UrbanCategory.safety,
          sentiment: -1,
          daysAgo: 2,
        ),
      ],
    ),
    UrbanZone(
      name: 'South Construction Belt',
      kind: 'Active development area',
      subtitle: 'Three residential towers under phased delivery',
      position: const Offset(0.62, 0.44),
      size: const Size(0.23, 0.24),
      trafficRisk: 41,
      co2Footprint: 71,
      greenCoverage: 31,
      developer: 'Skyline Build Co.',
      baseScores: const {
        UrbanCategory.mobility: 52,
        UrbanCategory.environment: 43,
        UrbanCategory.resources: 57,
        UrbanCategory.transparency: 38,
        UrbanCategory.inclusivity: 55,
        UrbanCategory.safety: 49,
      },
      issues: [
        const UrbanIssue(
          title: 'Construction complaints unresolved',
          category: UrbanCategory.transparency,
          daysOpen: 29,
          severity: 5,
        ),
        const UrbanIssue(
          title: 'Dust levels rising near school',
          category: UrbanCategory.environment,
          daysOpen: 9,
          severity: 4,
        ),
        const UrbanIssue(
          title: 'Temporary crossing lacks lighting',
          category: UrbanCategory.safety,
          daysOpen: 14,
          severity: 4,
        ),
      ],
      reviews: [
        const UrbanReview(
          author: 'Timur',
          message:
              'Traffic will explode if all towers open without shuttle links.',
          category: UrbanCategory.mobility,
          sentiment: -1,
          daysAgo: 1,
        ),
        const UrbanReview(
          author: 'Alina',
          message: 'Noise after 10 PM keeps happening.',
          category: UrbanCategory.transparency,
          sentiment: -1,
          daysAgo: 1,
        ),
      ],
    ),
  ];

  MapLayer _activeLayer = MapLayer.overall;
  late UrbanZone _selectedZone = _zones.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            final content = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _HeroHeader(
                              score: _cityAverageScore.round(),
                              districtCount: _zones.length,
                              openIssues: _zones.fold<int>(
                                0,
                                (sum, zone) => sum + zone.issues.length,
                              ),
                              avgFixDays: _averageFixDays,
                            ),
                            const SizedBox(height: 20),
                            Expanded(child: _buildMapAndDashboard(context)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 390,
                        child: _ZoneDetailsPanel(
                          zone: _selectedZone,
                          overallScore: _overallScore(_selectedZone).round(),
                          categoryScores: {
                            for (final category in UrbanCategory.values)
                              category: _scoreForCategory(
                                _selectedZone,
                                category,
                              ),
                          },
                          aiSummary: _buildAiSummary(_selectedZone),
                          onAddReport: () => _showAddReportDialog(context),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        _HeroHeader(
                          score: _cityAverageScore.round(),
                          districtCount: _zones.length,
                          openIssues: _zones.fold<int>(
                            0,
                            (sum, zone) => sum + zone.issues.length,
                          ),
                          avgFixDays: _averageFixDays,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 1020,
                          child: _buildMapAndDashboard(context),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ZoneDetailsPanel(
                            zone: _selectedZone,
                            overallScore: _overallScore(_selectedZone).round(),
                            categoryScores: {
                              for (final category in UrbanCategory.values)
                                category: _scoreForCategory(
                                  _selectedZone,
                                  category,
                                ),
                            },
                            aiSummary: _buildAiSummary(_selectedZone),
                            onAddReport: () => _showAddReportDialog(context),
                          ),
                        ),
                      ],
                    ),
                  );

            return Padding(padding: const EdgeInsets.all(16), child: content);
          },
        ),
      ),
    );
  }

  Widget _buildMapAndDashboard(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: _MapPanel(
            activeLayer: _activeLayer,
            zones: _zones,
            selectedZone: _selectedZone,
            onLayerChanged: (layer) {
              setState(() {
                _activeLayer = layer;
              });
            },
            onZoneSelected: (zone) {
              setState(() {
                _selectedZone = zone;
              });
            },
            colorForZone: _colorForZone,
            scoreForZone: _scoreForLayer,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          flex: 4,
          child: _DashboardPanel(alerts: _aiAlerts, highlights: _highlights),
        ),
      ],
    );
  }

  double get _cityAverageScore =>
      _zones.fold<double>(0, (sum, zone) => sum + _overallScore(zone)) /
      _zones.length;

  int get _averageFixDays {
    final issues = _zones.expand((zone) => zone.issues).toList();
    if (issues.isEmpty) {
      return 0;
    }
    return (issues.fold<int>(0, (sum, issue) => sum + issue.daysOpen) /
            issues.length)
        .round();
  }

  List<String> get _aiAlerts {
    final alerts = <String>[];
    for (final zone in _zones) {
      final longIssue = zone.issues.where((issue) => issue.daysOpen >= 20);
      if (longIssue.isNotEmpty) {
        alerts.add(
          '${zone.name}: ${longIssue.first.title} is unresolved for ${longIssue.first.daysOpen} days.',
        );
      }
      if (_scoreForCategory(zone, UrbanCategory.mobility) < 60 &&
          zone.trafficRisk >= 30) {
        alerts.add(
          '${zone.name}: AI forecast predicts +${zone.trafficRisk}% traffic pressure after completion.',
        );
      }
      final recentNegativeReviews = zone.reviews
          .where((review) => review.sentiment < 0)
          .length;
      if (recentNegativeReviews >= 2) {
        alerts.add(
          '${zone.name}: complaint volume is spiking across citizen reports.',
        );
      }
    }
    return alerts.take(4).toList();
  }

  List<_HighlightMetric> get _highlights {
    final bestEnvironment = _zones.reduce(
      (a, b) =>
          _scoreForCategory(a, UrbanCategory.environment) >
              _scoreForCategory(b, UrbanCategory.environment)
          ? a
          : b,
    );
    final weakestInclusivity = _zones.reduce(
      (a, b) =>
          _scoreForCategory(a, UrbanCategory.inclusivity) <
              _scoreForCategory(b, UrbanCategory.inclusivity)
          ? a
          : b,
    );
    final riskiestConstruction = _zones.reduce(
      (a, b) =>
          _scoreForCategory(a, UrbanCategory.transparency) <
              _scoreForCategory(b, UrbanCategory.transparency)
          ? a
          : b,
    );

    return [
      _HighlightMetric(
        title: 'Top eco district',
        value: bestEnvironment.name,
        detail:
            'Environment ${_scoreForCategory(bestEnvironment, UrbanCategory.environment).round()}',
      ),
      _HighlightMetric(
        title: 'Critical accessibility gap',
        value: weakestInclusivity.name,
        detail:
            'Inclusivity ${_scoreForCategory(weakestInclusivity, UrbanCategory.inclusivity).round()}',
      ),
      _HighlightMetric(
        title: 'Developer accountability risk',
        value: riskiestConstruction.developer,
        detail:
            '${riskiestConstruction.name} transparency ${_scoreForCategory(riskiestConstruction, UrbanCategory.transparency).round()}',
      ),
    ];
  }

  String _buildAiSummary(UrbanZone zone) {
    final weakestCategory = UrbanCategory.values.reduce(
      (a, b) => _scoreForCategory(zone, a) < _scoreForCategory(zone, b) ? a : b,
    );
    switch (weakestCategory) {
      case UrbanCategory.mobility:
        return 'Add a shuttle stop and protected crossings to prevent forecasted congestion growth.';
      case UrbanCategory.environment:
        return 'Tree canopy and dust suppression should be prioritized to cool the area and reduce emissions.';
      case UrbanCategory.resources:
        return 'Smart meters and leak alerts can lift the resource score within one reporting cycle.';
      case UrbanCategory.transparency:
        return 'Publish construction milestones and SLA timers to rebuild trust and reduce unresolved complaints.';
      case UrbanCategory.inclusivity:
        return 'Verified accessibility audits and tactile route upgrades would deliver the fastest score recovery.';
      case UrbanCategory.safety:
        return 'Lighting improvements and safer temporary pedestrian paths should be treated as immediate fixes.';
    }
  }

  double _scoreForLayer(UrbanZone zone, MapLayer layer) {
    switch (layer) {
      case MapLayer.overall:
        return _overallScore(zone);
      case MapLayer.mobility:
        return _scoreForCategory(zone, UrbanCategory.mobility);
      case MapLayer.environment:
        return _scoreForCategory(zone, UrbanCategory.environment);
      case MapLayer.transparency:
        return _scoreForCategory(zone, UrbanCategory.transparency);
      case MapLayer.inclusivity:
        return _scoreForCategory(zone, UrbanCategory.inclusivity);
      case MapLayer.safety:
        return _scoreForCategory(zone, UrbanCategory.safety);
    }
  }

  double _overallScore(UrbanZone zone) {
    var total = 0.0;
    for (final entry in _weights.entries) {
      total += _scoreForCategory(zone, entry.key) * entry.value;
    }
    return total;
  }

  double _scoreForCategory(UrbanZone zone, UrbanCategory category) {
    final base = zone.baseScores[category] ?? 50;
    final issuePenalty = zone.issues
        .where((issue) => issue.category == category)
        .fold<double>(
          0,
          (sum, issue) =>
              sum + issue.severity * 3.4 + math.min(issue.daysOpen / 3, 10),
        );
    final reviewShift = zone.reviews
        .where((review) => review.category == category)
        .fold<double>(
          0,
          (sum, review) =>
              sum +
              (review.sentiment * 3.5) +
              (review.verifiedInclusivity ? 1.5 : 0),
        );
    return (base - issuePenalty + reviewShift).clamp(18, 96);
  }

  Color _colorForZone(UrbanZone zone, MapLayer layer) {
    final score = _scoreForLayer(zone, layer);
    if (score >= 75) {
      return const Color(0xFF299B63);
    }
    if (score >= 55) {
      return const Color(0xFFD8A52B);
    }
    return const Color(0xFFCC5448);
  }

  Future<void> _showAddReportDialog(BuildContext context) async {
    final messageController = TextEditingController();
    UrbanCategory selectedCategory = UrbanCategory.inclusivity;
    bool verified = false;
    bool negative = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add citizen report'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach a new report to ${_selectedZone.name}.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'What did the resident report?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UrbanCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: UrbanCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Negative signal'),
                      subtitle: const Text(
                        'Negative reports reduce score and raise alerts.',
                      ),
                      value: negative,
                      onChanged: (value) {
                        setModalState(() {
                          negative = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Verified accessibility report'),
                      subtitle: const Text(
                        'Use for inclusivity feedback from affected residents.',
                      ),
                      value: verified,
                      onChanged: (value) {
                        setModalState(() {
                          verified = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final message = messageController.text.trim();
                    if (message.isEmpty) {
                      return;
                    }

                    setState(() {
                      _selectedZone.reviews.insert(
                        0,
                        UrbanReview(
                          author: 'New report',
                          message: message,
                          category: selectedCategory,
                          sentiment: negative ? -1 : 1,
                          daysAgo: 0,
                          verifiedInclusivity: verified,
                        ),
                      );
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Save report'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.score,
    required this.districtCount,
    required this.openIssues,
    required this.avgFixDays,
  });

  final int score;
  final int districtCount;
  final int openIssues;
  final int avgFixDays;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF163A35), Color(0xFF2E6F63), Color(0xFF87A76A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Wrap(
        runSpacing: 18,
        spacing: 18,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Dynamic LEED for cities',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'UrbanScore',
                  style: textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A hackathon-ready urban intelligence platform that scores mobility, ecology, transparency, accessibility, and safety in real time.',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _HeroStat(label: 'City score', value: '$score/100'),
              _HeroStat(label: 'Monitored zones', value: '$districtCount'),
              _HeroStat(label: 'Open issues', value: '$openIssues'),
              _HeroStat(label: 'Avg time-to-fix', value: '$avgFixDays d'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({
    required this.activeLayer,
    required this.zones,
    required this.selectedZone,
    required this.onLayerChanged,
    required this.onZoneSelected,
    required this.colorForZone,
    required this.scoreForZone,
  });

  final MapLayer activeLayer;
  final List<UrbanZone> zones;
  final UrbanZone selectedZone;
  final ValueChanged<MapLayer> onLayerChanged;
  final ValueChanged<UrbanZone> onZoneSelected;
  final Color Function(UrbanZone, MapLayer) colorForZone;
  final double Function(UrbanZone, MapLayer) scoreForZone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City map',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Switch layers to reveal mobility, ecology, construction risk, and inclusivity hotspots.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF50625B),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MapLayer.values
                      .map(
                        (layer) => ChoiceChip(
                          label: Text(layer.label),
                          selected: layer == activeLayer,
                          onSelected: (_) => onLayerChanged(layer),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDCE8D3),
                      Color(0xFFF6EBD1),
                      Color(0xFFD8E4EE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      top: 30,
                      left: 70,
                      child: _RoadStroke(width: 250, angle: 0.25),
                    ),
                    const Positioned(
                      top: 180,
                      right: 80,
                      child: _RoadStroke(width: 220, angle: -0.52),
                    ),
                    const Positioned(
                      bottom: 110,
                      left: 150,
                      child: _RoadStroke(width: 300, angle: -0.05),
                    ),
                    Positioned(
                      right: 24,
                      top: 20,
                      child: _MapLegend(activeLayer: activeLayer),
                    ),
                    for (final zone in zones)
                      Positioned.fill(
                        child: FractionallySizedBox(
                          alignment: Alignment(
                            zone.position.dx * 2 - 1 + zone.size.width - 0.12,
                            zone.position.dy * 2 - 1 + zone.size.height - 0.12,
                          ),
                          widthFactor: zone.size.width,
                          heightFactor: zone.size.height,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () => onZoneSelected(zone),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  color: colorForZone(
                                    zone,
                                    activeLayer,
                                  ).withValues(alpha: 0.84),
                                  border: Border.all(
                                    color: zone == selectedZone
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    width: zone == selectedZone ? 3 : 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final tiny =
                                        constraints.maxHeight < 70 ||
                                        constraints.maxWidth < 130;
                                    final compact =
                                        tiny ||
                                        constraints.maxHeight < 120 ||
                                        constraints.maxWidth < 150;
                                    if (tiny) {
                                      return Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Text(
                                          '${scoreForZone(zone, activeLayer).round()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                            height: 1,
                                          ),
                                        ),
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          zone.name,
                                          maxLines: compact ? 2 : 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: compact ? 13 : 16,
                                            height: 1.1,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${scoreForZone(zone, activeLayer).round()}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: compact ? 22 : 32,
                                                height: 1,
                                              ),
                                            ),
                                            if (!compact) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                activeLayer.label,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadStroke extends StatelessWidget {
  const _RoadStroke({required this.width, required this.angle});

  final double width;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: 18,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.58),
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.activeLayer});

  final MapLayer activeLayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeLayer.label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const _LegendRow(color: Color(0xFF299B63), label: 'High score'),
          const SizedBox(height: 6),
          const _LegendRow(color: Color(0xFFD8A52B), label: 'Needs attention'),
          const SizedBox(height: 6),
          const _LegendRow(color: Color(0xFFCC5448), label: 'Critical'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.alerts, required this.highlights});

  final List<String> alerts;
  final List<_HighlightMetric> highlights;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical = constraints.maxWidth < 760;
        final alertsCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI alerts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) => Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F3E9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 18),
                          const SizedBox(width: 10),
                          Expanded(child: Text(alerts[index])),
                        ],
                      ),
                    ),
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                  ),
                ),
              ],
            ),
          ),
        );
        final dashboardCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public dashboard',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: highlights.length,
                    itemBuilder: (context, index) {
                      final highlight = highlights[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F0),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              highlight.title,
                              style: const TextStyle(
                                color: Color(0xFF577268),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              highlight.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(highlight.detail),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                  ),
                ),
              ],
            ),
          ),
        );

        if (vertical) {
          return Column(
            children: [
              Expanded(child: alertsCard),
              const SizedBox(height: 20),
              Expanded(child: dashboardCard),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: alertsCard),
            const SizedBox(width: 20),
            Expanded(child: dashboardCard),
          ],
        );
      },
    );
  }
}

class _ZoneDetailsPanel extends StatelessWidget {
  const _ZoneDetailsPanel({
    required this.zone,
    required this.overallScore,
    required this.categoryScores,
    required this.aiSummary,
    required this.onAddReport,
  });

  final UrbanZone zone;
  final int overallScore;
  final Map<UrbanCategory, double> categoryScores;
  final String aiSummary;
  final VoidCallback onAddReport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.maxHeight != double.infinity;
        final reviewsList = boundedHeight
            ? Expanded(
                child: ListView.separated(
                  itemCount: zone.reviews.length,
                  itemBuilder: (context, index) =>
                      _ReviewTile(review: zone.reviews[index]),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                ),
              )
            : SizedBox(
                height: 280,
                child: ListView.separated(
                  itemCount: zone.reviews.length,
                  itemBuilder: (context, index) =>
                      _ReviewTile(review: zone.reviews[index]),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                ),
              );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            zone.kind,
                            style: const TextStyle(
                              color: Color(0xFF597067),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(zone.subtitle),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF163A35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'UrbanScore',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$overallScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _InfoPill(
                      icon: Icons.trending_up_rounded,
                      label: 'Traffic impact +${zone.trafficRisk}%',
                    ),
                    _InfoPill(
                      icon: Icons.co2_rounded,
                      label: 'CO2 footprint ${zone.co2Footprint}',
                    ),
                    _InfoPill(
                      icon: Icons.park_rounded,
                      label: 'Green cover ${zone.greenCoverage}%',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Weighted score breakdown',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 12),
                for (final category in UrbanCategory.values) ...[
                  _CategoryBar(
                    category: category,
                    value: categoryScores[category]!.round(),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F6ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology_alt_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI recommendation',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(aiSummary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Open problems',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onAddReport,
                      icon: const Icon(Icons.add_comment_rounded),
                      label: const Text('Add report'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...zone.issues.map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _IssueTile(issue: issue),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Citizen reviews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                reviewsList,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.category, required this.value});

  final UrbanCategory category;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(category.icon, size: 18, color: category.color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 10,
            backgroundColor: const Color(0xFFE4EADF),
            valueColor: AlwaysStoppedAnimation<Color>(category.color),
          ),
        ),
      ],
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final UrbanIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFCC5448)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  '${issue.category.label} • ${issue.daysOpen} days open • severity ${issue.severity}/5',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final UrbanReview review;

  @override
  Widget build(BuildContext context) {
    final positive = review.sentiment > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.author,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (review.verifiedInclusivity)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7DCF9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Verified accessibility',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              const Spacer(),
              Text(
                '${review.daysAgo}d ago',
                style: const TextStyle(color: Color(0xFF667A71)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.message),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_down_alt_rounded,
                size: 16,
                color: positive
                    ? const Color(0xFF299B63)
                    : const Color(0xFFCC5448),
              ),
              const SizedBox(width: 8),
              Text(
                review.category.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HighlightMetric {
  const _HighlightMetric({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;
}
