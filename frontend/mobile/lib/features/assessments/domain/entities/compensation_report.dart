import 'assessment.dart';
import 'detected_compensation.dart';

/// The full set of compensation findings for a single assessment,
/// combining video AI results and questionnaire-based results.
class CompensationReport {
  final String assessmentId;
  final String userId;
  final List<DetectedCompensation> detections;
  final DateTime generatedAt;

  const CompensationReport({
    required this.assessmentId,
    required this.userId,
    required this.detections,
    required this.generatedAt,
  });

  /// Merges questionnaire-based compensation patterns with video AI detections.
  ///
  /// Rules:
  /// - Patterns found only by video: included with their AI-derived severity.
  /// - Patterns found only by questionnaire: included as [CompensationSeverity.mild]
  ///   with zero frame counts (no video evidence available).
  /// - Patterns found by both: the **video detection takes precedence** (AI
  ///   result is more objective and carries a severity score).
  factory CompensationReport.merge({
    required String assessmentId,
    required String userId,
    required List<CompensationPattern> questionnairePatterns,
    required List<DetectedCompensation> videoDetections,
    required DateTime generatedAt,
  }) {
    // Build a map keyed by pattern so we can deduplicate.
    final Map<CompensationPattern, DetectedCompensation> merged = {};

    // 1. Seed with questionnaire patterns at mild severity.
    for (final pattern in questionnairePatterns) {
      merged[pattern] = DetectedCompensation(
        pattern: pattern,
        affectedFrameCount: 0,
        totalFrameCount: 0,
      );
    }

    // 2. Override / add video detections (AI takes precedence).
    for (final d in videoDetections) {
      merged[d.pattern] = d;
    }

    return CompensationReport(
      assessmentId: assessmentId,
      userId: userId,
      detections: merged.values.toList(),
      generatedAt: generatedAt,
    );
  }

  bool get isEmpty => detections.isEmpty;

  /// Returns the detection for [pattern], or null if it was not found.
  DetectedCompensation? detectionFor(CompensationPattern pattern) {
    for (final d in detections) {
      if (d.pattern == pattern) return d;
    }
    return null;
  }

  /// Returns detections ordered significant → moderate → mild.
  List<DetectedCompensation> get sortedByPriority {
    final copy = List<DetectedCompensation>.from(detections);
    copy.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return copy;
  }

  @override
  bool operator ==(Object other) =>
      other is CompensationReport && other.assessmentId == assessmentId;

  @override
  int get hashCode => assessmentId.hashCode;
}
