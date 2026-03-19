import 'package:flutter/material.dart';
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
    final titles = [
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
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: const Color(0xFFEAF0E6),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
