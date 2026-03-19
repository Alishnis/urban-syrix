import 'package:flutter/material.dart';
import 'package:hackathon_net/core/config/supabase_config.dart';
import 'package:hackathon_net/core/localization/app_language.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/localization/language_controller.dart';
import 'package:hackathon_net/core/localization/language_scope.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/data/mock/mock_urban_repository.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/account/account_tab.dart';
import 'package:hackathon_net/features/auth/presentation/auth_scope.dart';
import 'package:hackathon_net/features/dashboard/dashboard_tab.dart';
import 'package:hackathon_net/features/map/data/places_repository.dart';
import 'package:hackathon_net/features/map/map_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final List<UrbanPlace> _places;
  late final PlacesRepository _placesRepository;
  int _selectedIndex = 0;
  bool _isSyncingPlaces = false;
  String? _placesError;

  @override
  void initState() {
    super.initState();
    _placesRepository = SupabaseConfig.isConfigured
        ? SupabasePlacesRepository(Supabase.instance.client)
        : UnconfiguredPlacesRepository();
    _places = [...MockUrbanRepository().getPlaces()];
    _loadPersistedPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final loc = AppLocalizations.of(context);
    final languageController = LanguageScope.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactHeader = screenWidth < 860;
    final titles = [
      'urban syrix ${loc.tr('dashboard')}',
      'urban syrix ${loc.tr('map')}',
      'urban syrix ${loc.tr('account')}',
    ];
    final pages = [
      DashboardTab(places: _places),
      MapTab(
        places: _places,
        currentRole: auth.role,
        onCreatePlace: _addPlace,
        onAddReview: _addReview,
      ),
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
                  child: compactHeader
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(child: _BrandRow()),
                                _LanguagePicker(
                                  languageController: languageController,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Expanded(child: _BrandRow()),
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
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _LanguagePicker(
                                      languageController: languageController,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_isSyncingPlaces || _placesError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: GlassPanel(
                    borderRadius: 22,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    blur: false,
                    backgroundColor: _placesError == null
                        ? const Color(0xFF172131)
                        : const Color(0xFF2B1820),
                    child: Row(
                      children: [
                        Icon(
                          _placesError == null
                              ? Icons.cloud_sync_rounded
                              : Icons.error_outline_rounded,
                          color: _placesError == null
                              ? AppTheme.accent
                              : AppTheme.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _placesError == null
                                ? loc.tr('cloud_syncing')
                                : loc.tr('cloud_sync_failed'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
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
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.dashboard_customize_rounded),
                label: loc.tr('dashboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_rounded),
                label: loc.tr('map'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline_rounded),
                label: loc.tr('account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPersistedPlaces() async {
    setState(() {
      _isSyncingPlaces = true;
      _placesError = null;
    });

    try {
      final persistedPlaces = await _placesRepository.fetchPlaces();
      final reviewsByPlace = await _placesRepository.fetchReviewsByPlaceId();
      if (!mounted) {
        return;
      }
      setState(() {
        _mergePlaces(persistedPlaces);
        _applyReviews(reviewsByPlace);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _placesError = 'cloud_sync_failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingPlaces = false;
        });
      }
    }
  }

  Future<void> _addPlace(UrbanPlace place) async {
    final savedPlace = await _placesRepository.createPlace(place);
    if (!mounted) {
      return;
    }
    setState(() {
      _placesError = null;
      final existingIndex = _places.indexWhere(
        (item) => item.id == savedPlace.id,
      );
      if (existingIndex >= 0) {
        _places[existingIndex] = savedPlace;
      } else {
        _places.insert(0, savedPlace);
      }
    });
  }

  Future<UrbanReview> _addReview({
    required UrbanPlace place,
    required String message,
    required UrbanCategory category,
  }) async {
    final review = await _placesRepository.addReview(
      place: place,
      message: message,
      category: category,
    );
    if (!mounted) {
      return review;
    }

    setState(() {
      _placesError = null;
      final index = _places.indexWhere((item) => item.id == place.id);
      if (index >= 0) {
        _places[index] = _places[index].copyWith(
          reviews: [review, ..._places[index].reviews],
        );
      }
    });
    return review;
  }

  void _mergePlaces(List<UrbanPlace> persistedPlaces) {
    final persistedIds = persistedPlaces.map((place) => place.id).toSet();
    final mockOnlyPlaces = _places
        .where((place) => !persistedIds.contains(place.id))
        .toList(growable: false);

    _places
      ..clear()
      ..addAll(persistedPlaces)
      ..addAll(mockOnlyPlaces);
  }

  void _applyReviews(Map<String, List<UrbanReview>> reviewsByPlace) {
    for (var index = 0; index < _places.length; index++) {
      final reviews = reviewsByPlace[_places[index].id];
      if (reviews == null) {
        continue;
      }
      _places[index] = _places[index].copyWith(reviews: reviews);
    }
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Flexible(
          child: Text(
            'urban',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'syrix',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
            ),
          ),
        ),
        SizedBox(width: 12),
        _LiveDot(),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.languageController});

  final LanguageController languageController;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppLanguage>(
      initialValue: languageController.language,
      onSelected: languageController.setLanguage,
      color: AppTheme.bgTertiary,
      itemBuilder: (context) {
        return AppLanguage.values
            .map(
              (language) =>
                  PopupMenuItem(value: language, child: Text(language.label)),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.glassLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Text(
          languageController.language.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
