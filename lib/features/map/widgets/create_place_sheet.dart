import 'package:flutter/material.dart';
import 'package:hackathon_net/core/config/openai_config.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/auth/domain/app_role.dart';
import 'package:hackathon_net/features/map/data/openai_place_analysis_service.dart';
import 'package:hackathon_net/features/map/data/reverse_geocoding_service.dart';
import 'package:hackathon_net/features/map/models/place_ai_assessment.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class CreatePlaceSheet extends StatefulWidget {
  const CreatePlaceSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.role,
    required this.reverseGeocodingService,
    required this.onCreate,
    this.initialType,
    this.allowedTypes,
  });

  final double latitude;
  final double longitude;
  final AppRole role;
  final ReverseGeocodingService reverseGeocodingService;
  final Future<void> Function(UrbanPlace place) onCreate;
  final UrbanPlaceType? initialType;
  final List<UrbanPlaceType>? allowedTypes;

  @override
  State<CreatePlaceSheet> createState() => _CreatePlaceSheetState();
}

class _CreatePlaceSheetState extends State<CreatePlaceSheet> {
  final OpenAiPlaceAnalysisService _openAiPlaceAnalysisService =
      const OpenAiPlaceAnalysisService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  UrbanPlaceType _selectedType = UrbanPlaceType.incident;
  IncidentSubtype _incidentSubtype = IncidentSubtype.other;
  bool _isResolvingAddress = true;
  bool _isSaving = false;
  String? _addressError;
  String? _aiError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? UrbanPlaceType.incident;
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
    final loc = AppLocalizations.of(context);
    final allowedTypes = _allowedTypes;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PointerInterceptor(
          child: GlassPanel(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            blur: false,
            backgroundColor: const Color(0xFF161D29),
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: Theme.of(context).inputDecorationTheme
                    .copyWith(fillColor: const Color(0xFF232B39)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionEyebrow(label: loc.tr('create_map_point')),
                      const SizedBox(height: 12),
                      Text(
                        loc.tr('add_city_signal'),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${loc.tr('coordinates')}: ${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        OpenAiConfig.isConfigured
                            ? loc.tr('openai_enabled')
                            : loc.tr('openai_disabled'),
                        style: TextStyle(
                          color: OpenAiConfig.isConfigured
                              ? AppTheme.accent
                              : AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!_canCreateConstruction) ...[
                        Text(
                          loc.tr('construction_builder_only'),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: loc.tr('name')),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.tr('enter_name');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UrbanPlaceType>(
                        initialValue: _selectedType,
                        dropdownColor: AppTheme.bgTertiary,
                        decoration: InputDecoration(labelText: loc.tr('type')),
                        items: allowedTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(loc.placeTypeLabel(type)),
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
                      if (_selectedType == UrbanPlaceType.incident) ...[
                        const SizedBox(height: 16),
                        _IncidentSubtypeSection(
                          selectedSubtype: _incidentSubtype,
                          onChanged: (value) {
                            setState(() {
                              _incidentSubtype = value;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: loc.tr('description'),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return loc.tr('enter_description');
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
                          labelText: loc.tr('address'),
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
                            return loc.tr('enter_address');
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
                      if (_aiError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _aiError!,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_saveError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveError!,
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
                              child: Text(loc.tr('cancel')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSaving ? null : _save,
                              child: Text(
                                _isSaving
                                    ? loc.tr('adding')
                                    : loc.tr('add_point'),
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
      _addressError = AppLocalizations.of(context).tr('address_lookup_failed');
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
    if (!_canCreateMapPoint) {
      setState(() {
        _saveError = AppLocalizations.of(context).tr('map_point_builder_only');
      });
      return;
    }
    if (_selectedType == UrbanPlaceType.construction &&
        !_canCreateConstruction) {
      setState(() {
        _saveError = AppLocalizations.of(
          context,
        ).tr('construction_builder_only');
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _aiError = null;
      _saveError = null;
    });

    final rawDescription = _descriptionController.text.trim();
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final assessment = await _buildAssessment(
      name: name,
      description: rawDescription,
      address: address,
    );

    final incidentSubtype = _selectedType == UrbanPlaceType.incident
        ? _incidentSubtype
        : null;
    final detectionModel = incidentSubtype?.modelLabel;

    final place = UrbanPlace(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: _selectedType,
      incidentSubtype: incidentSubtype,
      detectionModel: detectionModel,
      address: address,
      description: assessment.description,
      location: GeoPoint(
        latitude: widget.latitude,
        longitude: widget.longitude,
      ),
      developer: 'Citizen report',
      trafficRisk: assessment.trafficRisk,
      co2Footprint: assessment.co2Footprint,
      greenCoverage: assessment.greenCoverage,
      baseScores: assessment.baseScores,
      issues: _defaultIssuesFor(_selectedType),
      reviews: const [],
    );

    try {
      await widget.onCreate(place);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveError = AppLocalizations.of(context).tr('save_point_failed');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<PlaceAiAssessment> _buildAssessment({
    required String name,
    required String description,
    required String address,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackAssessment(description);
    }

    try {
      return await _openAiPlaceAnalysisService.analyze(
        name: name,
        type: _selectedType,
        incidentSubtype: _selectedType == UrbanPlaceType.incident
            ? _incidentSubtype
            : null,
        description: description,
        address: address,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _aiError = AppLocalizations.of(context).tr('ai_failed');
        });
      }
      return _fallbackAssessment(description);
    }
  }

  PlaceAiAssessment _fallbackAssessment(String description) {
    return PlaceAiAssessment(
      description: description,
      baseScores: _baseScoresFor(_selectedType, _incidentSubtype),
      trafficRisk: _trafficRiskFor(_selectedType, _incidentSubtype),
      co2Footprint: _co2FootprintFor(_selectedType, _incidentSubtype),
      greenCoverage: _greenCoverageFor(_selectedType, _incidentSubtype),
    );
  }

  Map<UrbanCategory, double> _baseScoresFor(
    UrbanPlaceType type,
    IncidentSubtype incidentSubtype,
  ) {
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
        return switch (incidentSubtype) {
          IncidentSubtype.fire => const {
            UrbanCategory.mobility: 31,
            UrbanCategory.environment: 22,
            UrbanCategory.resources: 38,
            UrbanCategory.transparency: 47,
            UrbanCategory.inclusivity: 34,
            UrbanCategory.safety: 18,
          },
          IncidentSubtype.carAccident => const {
            UrbanCategory.mobility: 27,
            UrbanCategory.environment: 42,
            UrbanCategory.resources: 49,
            UrbanCategory.transparency: 45,
            UrbanCategory.inclusivity: 37,
            UrbanCategory.safety: 24,
          },
          IncidentSubtype.other => const {
            UrbanCategory.mobility: 44,
            UrbanCategory.environment: 50,
            UrbanCategory.resources: 55,
            UrbanCategory.transparency: 52,
            UrbanCategory.inclusivity: 49,
            UrbanCategory.safety: 35,
          },
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
        return switch (_incidentSubtype) {
          IncidentSubtype.fire => const [
            UrbanIssue(
              title: 'Fire response requires urgent emergency follow-up',
              category: UrbanCategory.safety,
              daysOpen: 1,
              severity: 5,
            ),
          ],
          IncidentSubtype.carAccident => const [
            UrbanIssue(
              title: 'Traffic accident requires immediate road safety response',
              category: UrbanCategory.mobility,
              daysOpen: 1,
              severity: 4,
            ),
          ],
          IncidentSubtype.other => const [
            UrbanIssue(
              title: 'Incident requires urgent municipal follow-up',
              category: UrbanCategory.safety,
              daysOpen: 1,
              severity: 4,
            ),
          ],
        };
    }
  }

  int _trafficRiskFor(UrbanPlaceType type, IncidentSubtype incidentSubtype) {
    switch (type) {
      case UrbanPlaceType.building:
        return 26;
      case UrbanPlaceType.construction:
        return 42;
      case UrbanPlaceType.road:
        return 34;
      case UrbanPlaceType.incident:
        return switch (incidentSubtype) {
          IncidentSubtype.fire => 62,
          IncidentSubtype.carAccident => 71,
          IncidentSubtype.other => 38,
        };
    }
  }

  int _co2FootprintFor(UrbanPlaceType type, IncidentSubtype incidentSubtype) {
    switch (type) {
      case UrbanPlaceType.building:
        return 52;
      case UrbanPlaceType.construction:
        return 72;
      case UrbanPlaceType.road:
        return 48;
      case UrbanPlaceType.incident:
        return switch (incidentSubtype) {
          IncidentSubtype.fire => 78,
          IncidentSubtype.carAccident => 46,
          IncidentSubtype.other => 40,
        };
    }
  }

  int _greenCoverageFor(UrbanPlaceType type, IncidentSubtype incidentSubtype) {
    switch (type) {
      case UrbanPlaceType.building:
        return 56;
      case UrbanPlaceType.construction:
        return 28;
      case UrbanPlaceType.road:
        return 41;
      case UrbanPlaceType.incident:
        return switch (incidentSubtype) {
          IncidentSubtype.fire => 12,
          IncidentSubtype.carAccident => 20,
          IncidentSubtype.other => 24,
        };
    }
  }

  bool get _canCreateConstruction =>
      widget.role == AppRole.builder || widget.role == AppRole.admin;

  bool get _canCreateMapPoint => _canCreateConstruction;

  List<UrbanPlaceType> get _allowedTypes {
    final explicitAllowedTypes = widget.allowedTypes;
    if (explicitAllowedTypes != null) {
      return explicitAllowedTypes;
    }
    if (_canCreateConstruction) {
      return UrbanPlaceType.values;
    }
    return UrbanPlaceType.values
        .where((type) => type != UrbanPlaceType.construction)
        .toList(growable: false);
  }
}

class _CategoryPreview extends StatelessWidget {
  const _CategoryPreview({required this.type});

  final UrbanPlaceType type;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return GlassPanel(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF101729),
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('auto_start_metrics'),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${loc.tr('auto_start_metrics_body')} (${loc.placeTypeLabel(type).toLowerCase()})',
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _IncidentSubtypeSection extends StatelessWidget {
  const _IncidentSubtypeSection({
    required this.selectedSubtype,
    required this.onChanged,
  });

  final IncidentSubtype selectedSubtype;
  final ValueChanged<IncidentSubtype> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('incident_detection_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          loc.tr('incident_detection_subtitle'),
          style: const TextStyle(
            color: AppTheme.textSecondary,
            height: 1.5,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        for (final subtype in IncidentSubtype.values) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(subtype),
              child: GlassPanel(
                borderRadius: 20,
                padding: const EdgeInsets.all(14),
                blur: false,
                backgroundColor: selectedSubtype == subtype
                    ? const Color(0xFF1E3140)
                    : const Color(0xFF101729),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(subtype.icon, color: AppTheme.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.incidentSubtypeLabel(subtype),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtype.modelLabel,
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            switch (subtype) {
                              IncidentSubtype.fire => loc.tr('fire_model_desc'),
                              IncidentSubtype.carAccident => loc.tr(
                                'car_accident_model_desc',
                              ),
                              IncidentSubtype.other => loc.tr(
                                'other_model_desc',
                              ),
                            },
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedSubtype == subtype)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.accent,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
