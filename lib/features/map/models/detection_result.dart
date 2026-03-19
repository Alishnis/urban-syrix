class DetectionResult {
  const DetectionResult({
    required this.detected,
    required this.maxConfidence,
    required this.mode,
    required this.stats,
    this.previewUrl,
  });

  final bool detected;
  final double maxConfidence;
  final String mode;
  final Map<String, dynamic> stats;
  final String? previewUrl;
}
