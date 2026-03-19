import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hackathon_net/core/localization/app_localizations.dart';
import 'package:hackathon_net/core/theme/app_theme.dart';
import 'package:hackathon_net/core/widgets/city_background.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';
import 'package:hackathon_net/features/map/data/incident_detection_service.dart';
import 'package:hackathon_net/features/map/data/reverse_geocoding_service.dart';
import 'package:hackathon_net/features/map/models/detection_result.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class AccidentReportSheet extends StatefulWidget {
  const AccidentReportSheet({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.reverseGeocodingService,
    required this.onCreate,
  });

  final double latitude;
  final double longitude;
  final ReverseGeocodingService reverseGeocodingService;
  final Future<void> Function(UrbanPlace place) onCreate;

  @override
  State<AccidentReportSheet> createState() => _AccidentReportSheetState();
}

class _AccidentReportSheetState extends State<AccidentReportSheet> {
  final IncidentDetectionService _detectionService =
      const IncidentDetectionService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  IncidentSubtype _subtype = IncidentSubtype.carAccident;
  PlatformFile? _selectedFile;
  DetectionResult? _result;
  bool _isResolvingAddress = true;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  double _sensitivity = 0.2;
  String? _error;

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
    final loc = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PointerInterceptor(
          child: GlassPanel(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            blur: false,
            backgroundColor: const Color(0xFF161D29),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionEyebrow(label: loc.tr('add_accident')),
                    const SizedBox(height: 12),
                    Text(
                      loc.tr('incident_detection_title'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.tr('incident_detection_subtitle'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _IncidentModeSelector(
                      selectedSubtype: _subtype,
                      onChanged: (value) {
                        setState(() {
                          _subtype = value;
                          _selectedFile = null;
                          _result = null;
                          _error = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
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
                    ),
                    const SizedBox(height: 16),
                    if (_subtype != IncidentSubtype.other) ...[
                      FilledButton.tonalIcon(
                        onPressed: _isAnalyzing ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: Text(
                          _selectedFile == null
                              ? loc.tr('upload_media')
                              : _selectedFile!.name,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${loc.tr('sensitivity')}: ${_sensitivity.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Slider(
                        value: _sensitivity,
                        min: 0.1,
                        max: 0.9,
                        divisions: 16,
                        onChanged: _isAnalyzing
                            ? null
                            : (value) {
                                setState(() {
                                  _sensitivity = value;
                                });
                              },
                      ),
                      FilledButton.icon(
                        onPressed: _isAnalyzing || _selectedFile == null
                            ? null
                            : _analyze,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _isAnalyzing
                              ? loc.tr('analyzing')
                              : loc.tr('analyze_media'),
                        ),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 12),
                        GlassPanel(
                          borderRadius: 20,
                          padding: const EdgeInsets.all(14),
                          blur: false,
                          backgroundColor: const Color(0xFF101729),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _result!.detected
                                        ? Icons.warning_amber_rounded
                                        : Icons.verified_rounded,
                                    color: _result!.detected
                                        ? AppTheme.danger
                                        : AppTheme.accent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _result!.detected
                                          ? '${loc.tr('detection_found')} ${(100 * _result!.maxConfidence).toStringAsFixed(1)}%'
                                          : loc.tr('detection_not_found'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_result!.detected &&
                                  _detectionRegionLabel(_result!) != null) ...[
                                const SizedBox(height: 12),
                                _DetectionFactRow(
                                  label: loc.tr('detection_location'),
                                  value: _detectionRegionLabel(_result!)!,
                                ),
                              ],
                              if (_result!.detected &&
                                  _detectionBoxLabel(_result!) != null) ...[
                                const SizedBox(height: 8),
                                _DetectionFactRow(
                                  label: loc.tr('detection_coordinates'),
                                  value: _detectionBoxLabel(_result!)!,
                                ),
                              ],
                              if (_result!.previewUrl != null) ...[
                                const SizedBox(height: 14),
                                Text(
                                  loc.tr('detection_preview'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _result!.previewUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bgTertiary,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        loc.tr('preview_unavailable'),
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      GlassPanel(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(14),
                        blur: false,
                        backgroundColor: const Color(0xFF101729),
                        child: Text(
                          loc.tr('other_model_desc'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                                  : loc.tr('add_accident'),
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
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    setState(() {
      _selectedFile = result.files.single;
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    final file = _selectedFile;
    if (file == null) {
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _result = null;
    });

    try {
      final result = await _detectionService.analyze(
        subtype: _subtype,
        file: file,
        sensitivity: _sensitivity,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _resolveAddress() async {
    setState(() {
      _isResolvingAddress = true;
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
    if (_subtype != IncidentSubtype.other && _result?.detected != true) {
      setState(() {
        _error = AppLocalizations.of(context).tr('analyze_before_saving');
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final detectionModel = _subtype.modelLabel;
    final result = _result;
    final description = _subtype == IncidentSubtype.other
        ? _descriptionController.text.trim()
        : '${_descriptionController.text.trim()} '
              '(${result?.mode ?? 'image'} / ${(100 * (result?.maxConfidence ?? 0)).toStringAsFixed(1)}%)';

    final place = UrbanPlace(
      id: 'incident_${DateTime.now().microsecondsSinceEpoch}',
      name: _nameController.text.trim(),
      type: UrbanPlaceType.incident,
      incidentSubtype: _subtype,
      detectionModel: detectionModel,
      detectionPreviewUrl: result?.previewUrl,
      address: _addressController.text.trim(),
      description: description,
      location: GeoPoint(
        latitude: widget.latitude,
        longitude: widget.longitude,
      ),
      developer: 'Incident detection',
      trafficRisk: switch (_subtype) {
        IncidentSubtype.fire => 82,
        IncidentSubtype.carAccident => 74,
        IncidentSubtype.other => 48,
      },
      co2Footprint: switch (_subtype) {
        IncidentSubtype.fire => 85,
        IncidentSubtype.carAccident => 52,
        IncidentSubtype.other => 40,
      },
      greenCoverage: switch (_subtype) {
        IncidentSubtype.fire => 10,
        IncidentSubtype.carAccident => 20,
        IncidentSubtype.other => 24,
      },
      baseScores: switch (_subtype) {
        IncidentSubtype.fire => const {
          UrbanCategory.mobility: 28,
          UrbanCategory.environment: 16,
          UrbanCategory.resources: 34,
          UrbanCategory.transparency: 48,
          UrbanCategory.inclusivity: 32,
          UrbanCategory.safety: 14,
        },
        IncidentSubtype.carAccident => const {
          UrbanCategory.mobility: 22,
          UrbanCategory.environment: 38,
          UrbanCategory.resources: 50,
          UrbanCategory.transparency: 44,
          UrbanCategory.inclusivity: 35,
          UrbanCategory.safety: 18,
        },
        IncidentSubtype.other => const {
          UrbanCategory.mobility: 44,
          UrbanCategory.environment: 50,
          UrbanCategory.resources: 55,
          UrbanCategory.transparency: 52,
          UrbanCategory.inclusivity: 49,
          UrbanCategory.safety: 35,
        },
      },
      issues: [
        UrbanIssue(
          title: switch (_subtype) {
            IncidentSubtype.fire =>
              'AI fire incident requires emergency response',
            IncidentSubtype.carAccident =>
              'AI accident incident requires road response',
            IncidentSubtype.other =>
              'Manual incident requires municipal review',
          },
          category: UrbanCategory.safety,
          daysOpen: 1,
          severity: _subtype == IncidentSubtype.fire ? 5 : 4,
        ),
      ],
      reviews: const [],
    );

    try {
      await widget.onCreate(place);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _detectionRegionLabel(DetectionResult result) {
    final bestBox = result.stats['best_box'];
    if (bestBox is! Map) {
      return null;
    }
    final region = bestBox['region'] as String?;
    if (region == null || region.isEmpty) {
      return null;
    }

    return region
        .split('-')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String? _detectionBoxLabel(DetectionResult result) {
    final bestBox = result.stats['best_box'];
    if (bestBox is! Map) {
      return null;
    }

    final x1 = bestBox['x1'];
    final y1 = bestBox['y1'];
    final x2 = bestBox['x2'];
    final y2 = bestBox['y2'];
    if (x1 == null || y1 == null || x2 == null || y2 == null) {
      return null;
    }

    return '($x1, $y1) - ($x2, $y2)';
  }
}

class _DetectionFactRow extends StatelessWidget {
  const _DetectionFactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 148,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _IncidentModeSelector extends StatelessWidget {
  const _IncidentModeSelector({
    required this.selectedSubtype,
    required this.onChanged,
  });

  final IncidentSubtype selectedSubtype;
  final ValueChanged<IncidentSubtype> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children: IncidentSubtype.values
          .map((subtype) {
            final selected = selectedSubtype == subtype;
            return SizedBox(
              width: 220,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onChanged(subtype),
                child: GlassPanel(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(14),
                  blur: false,
                  backgroundColor: selected
                      ? const Color(0xFF1E3140)
                      : const Color(0xFF101729),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(subtype.icon, color: AppTheme.accent),
                      const SizedBox(height: 10),
                      Text(
                        loc.incidentSubtypeLabel(subtype),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtype.modelLabel,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
