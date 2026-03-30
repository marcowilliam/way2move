import 'assessment.dart';

/// How frequently a compensation was observed across all analysed frames.
enum CompensationSeverity {
  /// Threshold exceeded in < 30 % of frames.
  mild,

  /// Threshold exceeded in 30–60 % of frames.
  moderate,

  /// Threshold exceeded in > 60 % of frames.
  significant;

  /// Derives severity from [ratio] (affectedFrames / totalFrames).
  static CompensationSeverity fromFrameRatio(double ratio) {
    if (ratio >= 0.60) return CompensationSeverity.significant;
    if (ratio >= 0.30) return CompensationSeverity.moderate;
    return CompensationSeverity.mild;
  }
}

/// A single compensation pattern that was detected during video analysis,
/// together with how often it appeared across the analysed frames.
class DetectedCompensation {
  final CompensationPattern pattern;

  /// Number of frames in which the compensation threshold was exceeded.
  final int affectedFrameCount;

  /// Total number of frames that were evaluated.
  final int totalFrameCount;

  const DetectedCompensation({
    required this.pattern,
    required this.affectedFrameCount,
    required this.totalFrameCount,
  });

  /// Fraction of frames in which the compensation was detected (0.0–1.0).
  double get frameRatio =>
      totalFrameCount == 0 ? 0.0 : affectedFrameCount / totalFrameCount;

  /// Severity derived from [frameRatio].
  CompensationSeverity get severity =>
      CompensationSeverity.fromFrameRatio(frameRatio);

  DetectedCompensation copyWith({
    CompensationPattern? pattern,
    int? affectedFrameCount,
    int? totalFrameCount,
  }) =>
      DetectedCompensation(
        pattern: pattern ?? this.pattern,
        affectedFrameCount: affectedFrameCount ?? this.affectedFrameCount,
        totalFrameCount: totalFrameCount ?? this.totalFrameCount,
      );

  @override
  bool operator ==(Object other) =>
      other is DetectedCompensation && other.pattern == pattern;

  @override
  int get hashCode => pattern.hashCode;

  @override
  String toString() =>
      'DetectedCompensation(${pattern.name}, '
      'affected=$affectedFrameCount/$totalFrameCount, '
      'severity=${severity.name})';
}
