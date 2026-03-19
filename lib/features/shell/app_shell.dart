import 'package:flutter/material.dart';
import 'package:hackathon_net/data/mock/mock_urban_repository.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
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
    final title = _selectedIndex == 0
        ? 'UrbanScore Dashboard'
        : 'UrbanScore Map';
    final body = _selectedIndex == 0
        ? DashboardTab(places: _places)
        : MapTab(places: _places);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFEAF0E6),
      ),
      body: body,
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
        ],
      ),
    );
  }
}
