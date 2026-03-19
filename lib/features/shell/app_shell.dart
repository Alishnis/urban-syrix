import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/data/mock/mock_urban_repository.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/account/account_tab.dart';
import 'package:hackathon_net/features/dashboard/dashboard_tab.dart';
import 'package:hackathon_net/features/map/map_tab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<UrbanPlace> _places = MockUrbanRepository().getPlaces();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const titles = [
      'UrbanScore Dashboard',
      'UrbanScore Map',
      'UrbanScore Account',
    ];
    final pages = [
      DashboardTab(places: _places),
      MapTab(places: _places),
      const AccountTab(),
    ];

    return Scaffold(
      body: CityBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GlassPanel(
                  borderRadius: 28,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Text(
                              'city',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'mgr+',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accent,
                              ),
                            ),
                            SizedBox(width: 12),
                            _LiveDot(),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          titles[_selectedIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'STRUCTURAL GLASS MODE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_customize_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Map'),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Account',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppTheme.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGlow,
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
