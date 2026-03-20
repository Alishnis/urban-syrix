import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/map/data/reverse_geocoding_service.dart';
import 'package:hackathon_net/features/map/data/safe_route_service.dart';
import 'package:hackathon_net/features/map/map_styles.dart';
import 'package:hackathon_net/features/map/models/safe_route_result.dart';
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
  final SafeRouteService _safeRouteService = const SafeRouteService();
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();
  ScoreCriterion _criterion = ScoreCriterion.overall;
  bool _isSheetOpen = false;
  LatLng? _draftMarkerTarget;
  DateTime? _ignoreMapTapUntil;
  _MapCreateMode _createMode = _MapCreateMode.none;
  _RouteSelectMode _routeSelectMode = _RouteSelectMode.none;
  LatLng? _routeStart;
  LatLng? _routeEnd;
  SafeRouteResult? _safeRoute;
  String? _routeError;
  bool _isBuildingRoute = false;

  bool get _canCreatePlace =>
      widget.currentRole == AppRole.builder ||
      widget.currentRole == AppRole.admin;
  bool get _canCreateAccident =>
      widget.currentRole == AppRole.resident ||
      widget.currentRole == AppRole.builder ||
      widget.currentRole == AppRole.admin;

  bool get _canCreateAnyPoint => _canCreatePlace || _canCreateAccident;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final circles = _buildCircles();
    final polylines = _buildPolylines();
    final startPoint = widget.places.first.location;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compactOverlay = screenWidth < 640;
    final mapHint = _createMode == _MapCreateMode.accident
        ? loc.tr('tap_to_add_accident')
        : _createMode == _MapCreateMode.place
        ? loc.tr('tap_to_add_place')
        : loc.tr('map_metric_hint');
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
              onMapCreated: (controller) {
                if (!_mapControllerCompleter.isCompleted) {
                  _mapControllerCompleter.complete(controller);
                }
              },
              markers: const <Marker>{},
              circles: circles,
              polylines: polylines,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onTap: _handleMapTap,
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
                                  mapHint,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!compactOverlay) ...[
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
                        ],
                      ),
                      if (compactOverlay) ...[
                        const SizedBox(height: 8),
                        DropdownButton<ScoreCriterion>(
                          isExpanded: true,
                          dropdownColor: AppTheme.bgTertiary,
                          value: _criterion,
                          underline: const SizedBox.shrink(),
                          items: ScoreCriterion.values
                              .map(
                                (criterion) => DropdownMenuItem(
                                  value: criterion,
                                  child: Text(loc.criterionLabel(criterion)),
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
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ModeButton(
                            label: loc.tr('set_start'),
                            isActive:
                                _routeSelectMode == _RouteSelectMode.start,
                            icon: Icons.trip_origin_rounded,
                            enabled: true,
                            onTap: () {
                              setState(() {
                                _createMode = _MapCreateMode.none;
                                _routeSelectMode =
                                    _routeSelectMode == _RouteSelectMode.start
                                    ? _RouteSelectMode.none
                                    : _RouteSelectMode.start;
                              });
                            },
                          ),
                          _ModeButton(
                            label: loc.tr('set_destination'),
                            isActive:
                                _routeSelectMode ==
                                _RouteSelectMode.destination,
                            icon: Icons.flag_rounded,
                            enabled: true,
                            onTap: () {
                              setState(() {
                                _createMode = _MapCreateMode.none;
                                _routeSelectMode =
                                    _routeSelectMode ==
                                        _RouteSelectMode.destination
                                    ? _RouteSelectMode.none
                                    : _RouteSelectMode.destination;
                              });
                            },
                          ),
                          _ModeButton(
                            label: _isBuildingRoute
                                ? loc.tr('building_route')
                                : loc.tr('build_safe_route'),
                            isActive: _safeRoute != null,
                            icon: Icons.alt_route_rounded,
                            enabled:
                                !_isBuildingRoute &&
                                _routeStart != null &&
                                _routeEnd != null,
                            onTap: _buildSafeRoute,
                          ),
                          _ModeButton(
                            label: loc.tr('clear_route'),
                            isActive: false,
                            icon: Icons.layers_clear_rounded,
                            enabled:
                                _routeStart != null ||
                                _routeEnd != null ||
                                _safeRoute != null,
                            onTap: _clearRoute,
                          ),
                          if (_canCreatePlace)
                            _ModeButton(
                              label: loc.tr('add_place'),
                              isActive: _createMode == _MapCreateMode.place,
                              icon: Icons.apartment_rounded,
                              enabled: _canCreatePlace,
                              onTap: () {
                                setState(() {
                                  _routeSelectMode = _RouteSelectMode.none;
                                  _createMode =
                                      _createMode == _MapCreateMode.place
                                      ? _MapCreateMode.none
                                      : _MapCreateMode.place;
                                });
                              },
                            ),
                          if (_canCreateAccident)
                            _ModeButton(
                              label: loc.tr('add_accident'),
                              isActive: _createMode == _MapCreateMode.accident,
                              icon: Icons.car_crash_rounded,
                              enabled: _canCreateAccident,
                              onTap: () {
                                setState(() {
                                  _routeSelectMode = _RouteSelectMode.none;
                                  _createMode =
                                      _createMode == _MapCreateMode.accident
                                      ? _MapCreateMode.none
                                      : _MapCreateMode.accident;
                                });
                              },
                            ),
                          if (!_canCreateAnyPoint)
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
                      if (_routeError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _routeError!,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_safeRoute != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${loc.tr('safe_route_ready')} ${(_safeRoute!.distanceMeters / 1000).toStringAsFixed(1)} km · ${(_safeRoute!.durationSeconds / 60).round()} min · ${_safeRoute!.avoidedPoints} ${loc.tr('accidents_avoided')}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                  height: compactOverlay ? 120 : 126,
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
                        width: compactOverlay ? 200 : 228,
                        child: GlassPanel(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(12),
                          blur: false,
                          backgroundColor: const Color(0xFF1A2434),
                          child: InkWell(
                            onTap: () => _focusPlace(place),
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

  Set<Circle> _buildCircles() {
    final circles = widget.places.map((place) {
      return Circle(
        circleId: CircleId(place.id),
        center: LatLng(place.location.latitude, place.location.longitude),
        radius: 120,
        fillColor: _circleColor(place),
        strokeColor: Colors.white,
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => _openDetails(place),
      );
    }).toSet();

    final draftTarget = _draftMarkerTarget;
    if (draftTarget != null) {
      circles.add(
        Circle(
          circleId: const CircleId('draft_marker'),
          center: draftTarget,
          radius: 105,
          fillColor: const Color(0xFF2F7AF8),
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (_routeStart != null) {
      circles.add(
        Circle(
          circleId: const CircleId('route_start'),
          center: _routeStart!,
          radius: 105,
          fillColor: const Color(0xFF2F7AF8),
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (_routeEnd != null) {
      circles.add(
        Circle(
          circleId: const CircleId('route_end'),
          center: _routeEnd!,
          radius: 105,
          fillColor: const Color(0xFFF0C419),
          strokeColor: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  Set<Polyline> _buildPolylines() {
    final route = _safeRoute;
    if (route == null || route.points.isEmpty) {
      return const <Polyline>{};
    }

    return {
      Polyline(
        polylineId: const PolylineId('safe_route'),
        points: route.points,
        color: AppTheme.accent,
        width: 6,
      ),
    };
  }

  Future<void> _focusPlace(UrbanPlace place) async {
    if (_mapControllerCompleter.isCompleted) {
      final controller = await _mapControllerCompleter.future;
      final update = CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(place.location.latitude, place.location.longitude),
          zoom: 15.4,
        ),
      );
      await controller.animateCamera(update);
      await controller.moveCamera(update);
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) {
      return;
    }
    _openDetails(place);
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
    if (_routeSelectMode == _RouteSelectMode.start) {
      setState(() {
        _routeStart = target;
        _routeSelectMode = _RouteSelectMode.none;
        _routeError = null;
      });
      return;
    }
    if (_routeSelectMode == _RouteSelectMode.destination) {
      setState(() {
        _routeEnd = target;
        _routeSelectMode = _RouteSelectMode.none;
        _routeError = null;
      });
      return;
    }
    if (_createMode == _MapCreateMode.accident && !_canCreateAccident) {
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
    if (_createMode == _MapCreateMode.place && !_canCreatePlace) {
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
      if (!_canCreateAccident) {
        return;
      }
      _openAccidentSheet(target);
    } else {
      if (!_canCreatePlace) {
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

  Future<void> _buildSafeRoute() async {
    final routeStart = _routeStart;
    final routeEnd = _routeEnd;
    if (routeStart == null || routeEnd == null) {
      return;
    }

    setState(() {
      _isBuildingRoute = true;
      _routeError = null;
    });

    try {
      final avoidPoints = widget.places
          .where((place) => place.type == UrbanPlaceType.incident)
          .map(
            (place) =>
                LatLng(place.location.latitude, place.location.longitude),
          )
          .toList(growable: false);

      final result = await _safeRouteService.buildRoute(
        origin: routeStart,
        destination: routeEnd,
        avoidPoints: avoidPoints,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _safeRoute = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _routeError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBuildingRoute = false;
        });
      }
    }
  }

  void _clearRoute() {
    setState(() {
      _routeStart = null;
      _routeEnd = null;
      _safeRoute = null;
      _routeError = null;
      _routeSelectMode = _RouteSelectMode.none;
    });
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

  Color _circleColor(UrbanPlace place) {
    if (place.type == UrbanPlaceType.incident) {
      return const Color(0xFFE64B3C);
    }
    if (place.type == UrbanPlaceType.building) {
      return const Color(0xFF22A06B);
    }
    if (place.type == UrbanPlaceType.construction) {
      return const Color(0xFF22A06B);
    }
    if (place.type == UrbanPlaceType.road) {
      return const Color(0xFF22A06B);
    }
    return const Color(0xFFE64B3C);
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

enum _RouteSelectMode { none, start, destination }

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
