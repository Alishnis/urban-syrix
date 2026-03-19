import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/data/reverse_geocoding_service.dart';
import 'package:hackathon_net/features/map/map_styles.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';
import 'package:hackathon_net/features/map/widgets/create_place_sheet.dart';
import 'package:hackathon_net/features/map/widgets/place_details_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({
    super.key,
    required this.places,
    required this.onCreatePlace,
  });

  final List<UrbanPlace> places;
  final ValueChanged<UrbanPlace> onCreatePlace;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final ReverseGeocodingService _reverseGeocodingService =
      const ReverseGeocodingService();
  ScoreCriterion _criterion = ScoreCriterion.overall;

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final startPoint = widget.places.first.location;
    final topPlaces = [...widget.places]
      ..sort(
        (a, b) => UrbanScoreService.scoreByCriterion(
          b,
          _criterion,
        ).compareTo(UrbanScoreService.scoreByCriterion(a, _criterion)),
      );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: GoogleMap(
              style: kDarkMapStyle,
              initialCameraPosition: CameraPosition(
                target: LatLng(startPoint.latitude, startPoint.longitude),
                zoom: 11.6,
              ),
              markers: markers,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onLongPress: _openCreatePlaceSheet,
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live city map',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Marker score color follows the selected metric.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 220,
                    child: DropdownButton<ScoreCriterion>(
                      isExpanded: true,
                      dropdownColor: AppTheme.bgTertiary,
                      value: _criterion,
                      underline: const SizedBox.shrink(),
                      items: ScoreCriterion.values
                          .map(
                            (criterion) => DropdownMenuItem(
                              value: criterion,
                              child: Text(criterion.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _criterion = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topPlaces.take(4).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final place = topPlaces[index];
                  final score = UrbanScoreService.scoreByCriterion(
                    place,
                    _criterion,
                  ).round();
                  final color = UrbanScoreService.scoreColor(score.toDouble());
                  return SizedBox(
                    width: 280,
                    child: GlassPanel(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(16),
                      blur: false,
                      backgroundColor: const Color(0xFF1A2434),
                      child: InkWell(
                        onTap: () => _openDetails(place),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(place.type.icon, color: color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    place.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              place.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              place.address,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return widget.places.map((place) {
      final score = UrbanScoreService.scoreByCriterion(place, _criterion);
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.location.latitude, place.location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(score)),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: '${place.type.label} | ${score.round()}',
        ),
        onTap: () => _openDetails(place),
      );
    }).toSet();
  }

  void _openDetails(UrbanPlace place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: PlaceDetailsSheet(place: place),
      ),
    );
  }

  void _openCreatePlaceSheet(LatLng target) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CreatePlaceSheet(
          latitude: target.latitude,
          longitude: target.longitude,
          reverseGeocodingService: _reverseGeocodingService,
          onCreate: widget.onCreatePlace,
        ),
      ),
    );
  }

  double _markerHue(double score) {
    if (score >= 75) {
      return BitmapDescriptor.hueGreen;
    }
    if (score >= 55) {
      return BitmapDescriptor.hueOrange;
    }
    return BitmapDescriptor.hueRed;
  }
}
