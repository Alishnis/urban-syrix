import 'package:flutter/material.dart';
import 'package:hackathon_net/core/config/supabase_config.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/data/mock/mock_urban_repository.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/auth/presentation/auth_screen.dart';
import 'package:hackathon_net/features/map/data/places_repository.dart';
import 'package:hackathon_net/features/map/map_tab.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Landing page for signed-out visitors: general product info plus a
/// read-only view of the live map. Adding a marker or a comment routes to
/// [AuthScreen] instead of the guest being blocked outright.
class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key});

  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  late final List<UrbanPlace> _places;
  late final PlacesRepository _placesRepository;

  @override
  void initState() {
    super.initState();
    _placesRepository = SupabaseConfig.isConfigured
        ? SupabasePlacesRepository(Supabase.instance.client)
        : UnconfiguredPlacesRepository();
    _places = [...MockUrbanRepository().getPlaces()];
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    try {
      final persistedPlaces = await _placesRepository.fetchPlaces();
      final reviewsByPlace = await _placesRepository.fetchReviewsByPlaceId();
      if (!mounted || persistedPlaces.isEmpty) {
        return;
      }
      setState(() {
        _places
          ..clear()
          ..addAll(
            persistedPlaces.map((place) {
              final reviews = reviewsByPlace[place.id];
              return reviews == null ? place : place.copyWith(reviews: reviews);
            }),
          );
      });
    } catch (_) {
      // Guest browsing shouldn't hard-fail; keep the mock seed on error.
    }
  }

  void _goToAuth() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 640;
    // Give the map a generous, fixed height instead of squeezing it into
    // whatever vertical space is left — that's what caused its internal
    // overlay buttons to overlap the hero text on short/wide viewports.
    final mapHeight = (size.height * 0.85).clamp(520.0, 900.0);

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
                      const Expanded(child: _BrandRow()),
                      FilledButton(
                        onPressed: _goToAuth,
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: size.height - 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SectionEyebrow(
                              label: 'urban syrix control layer',
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Your city,\ndecoded\nin real time.',
                              style: TextStyle(
                                fontSize: compact ? 40 : 60,
                                height: 0.98,
                                fontWeight: FontWeight.w900,
                                letterSpacing: compact ? -1.4 : -2.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Browse resident signals, builder work and '
                              'incident reports on the live map. Sign in to '
                              'add your own marker or leave a comment.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: compact ? 16 : 18,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Scroll to explore the live map',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: mapHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: MapTab(
                            places: _places,
                            currentRole: AppRole.resident,
                            isAuthenticated: false,
                            onRequireAuth: _goToAuth,
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
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'urban',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 6),
        const Text(
          'syrix',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.accent,
          ),
        ),
      ],
    );
  }
}
