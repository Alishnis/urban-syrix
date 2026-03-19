import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/domain/services/urban_score_service.dart';
import 'package:hackathon_net/features/map/widgets/place_details_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key, required this.places});

  final List<UrbanPlace> places;

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  ScoreCriterion _criterion = ScoreCriterion.overall;

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final startPoint = widget.places.first.location;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(startPoint.latitude, startPoint.longitude),
            zoom: 11.6,
          ),
          markers: markers,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined),
                  const SizedBox(width: 10),
                  const Text('Marker score:'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<ScoreCriterion>(
                      isExpanded: true,
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
        ),
      ],
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
        heightFactor: 0.86,
        child: PlaceDetailsSheet(place: place),
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
