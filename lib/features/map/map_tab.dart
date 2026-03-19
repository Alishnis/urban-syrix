import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/map/data/reverse_geocoding_service.dart';
import 'package:hackathon_net/features/map/map_styles.dart';
import 'package:hackathon_net/features/map/widgets/accident_report_sheet.dart';
import 'package:hackathon_net/features/map/widgets/create_place_sheet.dart';
import 'package:hackathon_net/features/map/widgets/place_details_sheet.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class MapTab extends StatefulWidget {
  const MapTab({
    super.key,
    required this.places,
    required this.currentRole,
    required this.onCreatePlace,
    required this.onAddReview,
  });

  final List<UrbanPlace> places;
  final AppRole currentRole;
  final Future<void> Function(UrbanPlace place) onCreatePlace;
  final Future<UrbanReview> Function({
    required UrbanPlace place,
    required String message,
    required UrbanCategory category,
  })
  onAddReview;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final ReverseGeocodingService _reverseGeocodingService =
      const ReverseGeocodingService();
  ScoreCriterion _criterion = ScoreCriterion.overall;
  bool _isSheetOpen = false;
  LatLng? _draftMarkerTarget;
  DateTime? _ignoreMapTapUntil;
  _MapCreateMode _createMode = _MapCreateMode.none;

  bool get _canCreateMapPoint =>
      widget.currentRole == AppRole.builder ||
      widget.currentRole == AppRole.admin;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
              onTap: _canCreateMapPoint ? _handleMapTap : null,
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Listener(
              onPointerDown: (_) => _suppressNextMapTap(),
              child: PointerInterceptor(
                child: GlassPanel(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.radar_rounded,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('live_city_map'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _createMode == _MapCreateMode.accident
                                      ? loc.tr('tap_to_add_accident')
                                      : _createMode == _MapCreateMode.place
                                      ? loc.tr('tap_to_add_place')
                                      : loc.tr('map_metric_hint'),
                                  style: const TextStyle(
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
                                      child: Text(
                                        loc.criterionLabel(criterion),
                                      ),
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
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ModeButton(
                            label: loc.tr('add_place'),
                            isActive: _createMode == _MapCreateMode.place,
                            icon: Icons.apartment_rounded,
                            enabled: _canCreateMapPoint,
                            onTap: () {
                              setState(() {
                                _createMode =
                                    _createMode == _MapCreateMode.place
                                    ? _MapCreateMode.none
                                    : _MapCreateMode.place;
                              });
                            },
                          ),
                          _ModeButton(
                            label: loc.tr('add_accident'),
                            isActive: _createMode == _MapCreateMode.accident,
                            icon: Icons.car_crash_rounded,
                            enabled: _canCreateMapPoint,
                            onTap: () {
                              setState(() {
                                _createMode =
                                    _createMode == _MapCreateMode.accident
                                    ? _MapCreateMode.none
                                    : _MapCreateMode.accident;
                              });
                            },
                          ),
                          if (!_canCreateMapPoint)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 10),
                              child: Text(
                                loc.tr('map_point_builder_only'),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Listener(
              onPointerDown: (_) => _suppressNextMapTap(),
              child: PointerInterceptor(
                child: SizedBox(
                  height: 126,
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
                      final color = UrbanScoreService.scoreColor(
                        score.toDouble(),
                      );
                      return SizedBox(
                        width: 228,
                        child: GlassPanel(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(12),
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
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        place.type.icon,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        place.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
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
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  place.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  place.address,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final loc = AppLocalizations.of(context);
    final markers = widget.places.map((place) {
      final score = UrbanScoreService.scoreByCriterion(place, _criterion);
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.location.latitude, place.location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(place, score)),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.type == UrbanPlaceType.incident
              ? (place.incidentSubtype != null
                    ? loc.incidentDetectionLabel(place.incidentSubtype!)
                    : loc.tr('live_incident'))
              : '${loc.placeTypeLabel(place.type)} | ${score.round()}',
        ),
        onTap: () => _openDetails(place),
      );
    }).toSet();

    final draftTarget = _draftMarkerTarget;
    if (draftTarget != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('draft_marker'),
          position: draftTarget,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: loc.tr('new_marker_location'),
            snippet: loc.tr('selected_point'),
          ),
        ),
      );
    }

    return markers;
  }

  void _openDetails(UrbanPlace place) {
    _isSheetOpen = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: PlaceDetailsSheet(
          place: place,
          onAddReview:
              ({required String message, required UrbanCategory category}) =>
                  widget.onAddReview(
                    place: place,
                    message: message,
                    category: category,
                  ),
        ),
      ),
    ).whenComplete(() {
      _isSheetOpen = false;
      _suppressNextMapTap();
    });
  }

  void _handleMapTap(LatLng target) {
    if (_isSheetOpen || _shouldIgnoreMapTap()) {
      return;
    }
    if (!_canCreateMapPoint) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).tr('map_point_builder_only'),
            ),
          ),
        );
      return;
    }
    if (_createMode == _MapCreateMode.none) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tr('pick_create_mode')),
          ),
        );
      return;
    }
    setState(() {
      _draftMarkerTarget = target;
    });
    if (_createMode == _MapCreateMode.accident) {
      _openAccidentSheet(target);
    } else {
      _openCreatePlaceSheet(target);
    }
  }

  Future<void> _openCreatePlaceSheet(LatLng target) async {
    if (_isSheetOpen) {
      return;
    }
    setState(() {
      _isSheetOpen = true;
      _draftMarkerTarget = target;
    });
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: CreatePlaceSheet(
          latitude: target.latitude,
          longitude: target.longitude,
          role: widget.currentRole,
          reverseGeocodingService: _reverseGeocodingService,
          onCreate: widget.onCreatePlace,
          initialType: UrbanPlaceType.building,
          allowedTypes: const [
            UrbanPlaceType.building,
            UrbanPlaceType.construction,
            UrbanPlaceType.road,
          ],
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSheetOpen = false;
      _draftMarkerTarget = null;
      _createMode = _MapCreateMode.none;
    });
    _suppressNextMapTap();
  }

  Future<void> _openAccidentSheet(LatLng target) async {
    if (_isSheetOpen) {
      return;
    }
    setState(() {
      _isSheetOpen = true;
      _draftMarkerTarget = target;
    });
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.94,
        child: AccidentReportSheet(
          latitude: target.latitude,
          longitude: target.longitude,
          reverseGeocodingService: _reverseGeocodingService,
          onCreate: widget.onCreatePlace,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSheetOpen = false;
      _draftMarkerTarget = null;
      _createMode = _MapCreateMode.none;
    });
    _suppressNextMapTap();
  }

  double _markerHue(UrbanPlace place, double score) {
    if (place.type == UrbanPlaceType.incident) {
      return switch (place.incidentSubtype) {
        IncidentSubtype.fire => BitmapDescriptor.hueRed,
        IncidentSubtype.carAccident => BitmapDescriptor.hueRose,
        IncidentSubtype.other || null => BitmapDescriptor.hueViolet,
      };
    }
    if (place.type == UrbanPlaceType.building) {
      return BitmapDescriptor.hueAzure;
    }
    if (place.type == UrbanPlaceType.construction) {
      return BitmapDescriptor.hueOrange;
    }
    if (place.type == UrbanPlaceType.road) {
      return BitmapDescriptor.hueGreen;
    }
    if (score >= 75) {
      return BitmapDescriptor.hueGreen;
    }
    if (score >= 55) {
      return BitmapDescriptor.hueOrange;
    }
    return BitmapDescriptor.hueRed;
  }

  void _suppressNextMapTap() {
    _ignoreMapTapUntil = DateTime.now().add(const Duration(milliseconds: 500));
  }

  bool _shouldIgnoreMapTap() {
    final until = _ignoreMapTapUntil;
    if (until == null) {
      return false;
    }
    final shouldIgnore = DateTime.now().isBefore(until);
    if (!shouldIgnore) {
      _ignoreMapTapUntil = null;
    }
    return shouldIgnore;
  }
}

enum _MapCreateMode { none, place, accident }

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isActive
        ? AppTheme.bgPrimary
        : enabled
        ? AppTheme.textPrimary
        : AppTheme.textMuted;
    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.accent
                : enabled
                ? AppTheme.glassLight
                : AppTheme.bgTertiary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled ? AppTheme.glassBorder : AppTheme.textMuted,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
