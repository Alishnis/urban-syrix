import 'package:flutter/material.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/data/reverse_geocoding_service.dart';

class CreatePlaceSheet extends StatefulWidget {
  const CreatePlaceSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.reverseGeocodingService,
    required this.onCreate,
  });

  final double latitude;
  final double longitude;
  final ReverseGeocodingService reverseGeocodingService;
  final ValueChanged<UrbanPlace> onCreate;

  @override
  State<CreatePlaceSheet> createState() => _CreatePlaceSheetState();
}

class _CreatePlaceSheetState extends State<CreatePlaceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  UrbanPlaceType _selectedType = UrbanPlaceType.incident;
  bool _isResolvingAddress = true;
  bool _isSaving = false;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GlassPanel(
          borderRadius: 28,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionEyebrow(label: 'Create map point'),
                  const SizedBox(height: 12),
                  const Text(
                    'Add a new city signal directly from the map.',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Coordinates: ${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UrbanPlaceType>(
                    initialValue: _selectedType,
                    dropdownColor: AppTheme.bgTertiary,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: UrbanPlaceType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter a description.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      suffixIcon: _isResolvingAddress
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accent,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _resolveAddress,
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter an address.';
                      }
                      return null;
                    },
                  ),
                  if (_addressError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _addressError!,
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _CategoryPreview(type: _selectedType),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          child: Text(
                            _isSaving ? 'Adding...' : 'Add point',
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
    );
  }

  Future<void> _resolveAddress() async {
    setState(() {
      _isResolvingAddress = true;
      _addressError = null;
    });

    try {
      final address = await widget.reverseGeocodingService.lookupAddress(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
      if (!mounted) {
        return;
      }
      _addressController.text = address;
    } catch (_) {
      if (!mounted) {
        return;
      }
      _addressController.text =
          '${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}';
      _addressError = 'Address lookup failed. You can edit it manually.';
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final place = UrbanPlace(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: _selectedType,
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      location: GeoPoint(
        latitude: widget.latitude,
        longitude: widget.longitude,
      ),
      developer: 'Citizen report',
      trafficRisk: _trafficRiskFor(_selectedType),
      co2Footprint: _co2FootprintFor(_selectedType),
      greenCoverage: _greenCoverageFor(_selectedType),
      baseScores: _baseScoresFor(_selectedType),
      issues: _defaultIssuesFor(_selectedType),
      reviews: const [],
    );

    widget.onCreate(place);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Map<UrbanCategory, double> _baseScoresFor(UrbanPlaceType type) {
    switch (type) {
      case UrbanPlaceType.building:
        return const {
          UrbanCategory.mobility: 68,
          UrbanCategory.environment: 63,
          UrbanCategory.resources: 66,
          UrbanCategory.transparency: 61,
          UrbanCategory.inclusivity: 64,
          UrbanCategory.safety: 65,
        };
      case UrbanPlaceType.construction:
        return const {
          UrbanCategory.mobility: 48,
          UrbanCategory.environment: 42,
          UrbanCategory.resources: 58,
          UrbanCategory.transparency: 40,
          UrbanCategory.inclusivity: 50,
          UrbanCategory.safety: 46,
        };
      case UrbanPlaceType.road:
        return const {
          UrbanCategory.mobility: 62,
          UrbanCategory.environment: 57,
          UrbanCategory.resources: 60,
          UrbanCategory.transparency: 59,
          UrbanCategory.inclusivity: 54,
          UrbanCategory.safety: 55,
        };
      case UrbanPlaceType.incident:
        return const {
          UrbanCategory.mobility: 44,
          UrbanCategory.environment: 50,
          UrbanCategory.resources: 55,
          UrbanCategory.transparency: 52,
          UrbanCategory.inclusivity: 49,
          UrbanCategory.safety: 35,
        };
    }
  }

  List<UrbanIssue> _defaultIssuesFor(UrbanPlaceType type) {
    switch (type) {
      case UrbanPlaceType.building:
        return const [
          UrbanIssue(
            title: 'Newly reported access and operations review pending',
            category: UrbanCategory.transparency,
            daysOpen: 1,
            severity: 2,
          ),
        ];
      case UrbanPlaceType.construction:
        return const [
          UrbanIssue(
            title: 'Fresh construction impact review opened',
            category: UrbanCategory.environment,
            daysOpen: 1,
            severity: 3,
          ),
        ];
      case UrbanPlaceType.road:
        return const [
          UrbanIssue(
            title: 'Road condition verification requested',
            category: UrbanCategory.safety,
            daysOpen: 1,
            severity: 2,
          ),
        ];
      case UrbanPlaceType.incident:
        return const [
          UrbanIssue(
            title: 'Incident requires urgent municipal follow-up',
            category: UrbanCategory.safety,
            daysOpen: 1,
            severity: 4,
          ),
        ];
    }
  }

  int _trafficRiskFor(UrbanPlaceType type) {
    switch (type) {
      case UrbanPlaceType.building:
        return 26;
      case UrbanPlaceType.construction:
        return 42;
      case UrbanPlaceType.road:
        return 34;
      case UrbanPlaceType.incident:
        return 38;
    }
  }

  int _co2FootprintFor(UrbanPlaceType type) {
    switch (type) {
      case UrbanPlaceType.building:
        return 52;
      case UrbanPlaceType.construction:
        return 72;
      case UrbanPlaceType.road:
        return 48;
      case UrbanPlaceType.incident:
        return 40;
    }
  }

  int _greenCoverageFor(UrbanPlaceType type) {
    switch (type) {
      case UrbanPlaceType.building:
        return 56;
      case UrbanPlaceType.construction:
        return 28;
      case UrbanPlaceType.road:
        return 41;
      case UrbanPlaceType.incident:
        return 24;
    }
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.type});

  final UrbanPlaceType type;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      backgroundColor: AppTheme.bgTertiary.withValues(alpha: 0.9),
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Auto-start metrics',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This new ${type.label.toLowerCase()} will start with default score bands and join district scoring immediately.',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
