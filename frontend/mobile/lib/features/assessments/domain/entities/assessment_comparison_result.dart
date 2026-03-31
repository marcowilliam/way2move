import 'assessment.dart';
import 'compensation_report.dart';
import 'detected_compensation.dart';
import 'video_analysis.dart';

/// A pair of [CompensationReport] and their associated [VideoAnalysis] records
/// for each of the two assessments being compared.
class AssessmentSnapshot {
  final String assessmentId;
  final DateTime assessmentDate;
  final CompensationReport report;
  final List<VideoAnalysis> videoAnalyses;

  const AssessmentSnapshot({
    required this.assessmentId,
    required this.assessmentDate,
    required this.report,
    required this.videoAnalyses,
  });

  /// Returns the score (0–100) for a given [ScreeningMovement].
  ///
  /// Score = 100 − (average percentage of frames with any compensation
  /// across all video analyses for that movement).
  ///
  /// Returns null when no video analysis exists for the movement.
  double? movementScore(ScreeningMovement movement) {
    final analyses =
        videoAnalyses.where((v) => v.movement == movement).toList();
    if (analyses.isEmpty) return null;

    double totalCompRate = 0;
    for (final a in analyses) {
      if (a.frames.isEmpty) {
        totalCompRate += 0;
      } else {
        final totalFrames = a.frames.length;
        final affectedFrames = a.detectedCompensations.fold<int>(
          0,
          (sum, c) {
            // Find the matching DetectedCompensation from the report
            final det = report.detectionFor(c);
            return sum + (det?.affectedFrameCount ?? 0);
          },
        );
        totalCompRate += (affectedFrames / totalFrames).clamp(0.0, 1.0);
      }
    }

    final avgCompRate = totalCompRate / analyses.length;
    return ((1.0 - avgCompRate) * 100).clamp(0.0, 100.0);
  }
}

/// The result of comparing two assessments — an initial and a re-assessment.
class AssessmentComparisonResult {
  final AssessmentSnapshot initial;
  final AssessmentSnapshot reAssessment;

  const AssessmentComparisonResult({
    required this.initial,
    required this.reAssessment,
  });

  /// Returns compensation patterns that changed severity between assessments.
  List<CompensationChange> get compensationChanges {
    final changes = <CompensationChange>[];

    final allPatterns = <CompensationPattern>{
      ...initial.report.detections.map((d) => d.pattern),
      ...reAssessment.report.detections.map((d) => d.pattern),
    };

    for (final pattern in allPatterns) {
      final before = initial.report.detectionFor(pattern);
      final after = reAssessment.report.detectionFor(pattern);

      if (before != null || after != null) {
        changes.add(CompensationChange(
          pattern: pattern,
          beforeSeverity: before?.severity,
          afterSeverity: after?.severity,
        ));
      }
    }

    // Sort: improved first, then worsened, then unchanged
    changes.sort((a, b) => a.changeType.index.compareTo(b.changeType.index));
    return changes;
  }
}

/// Represents the severity change for a single compensation pattern between
/// two assessments.
class CompensationChange {
  final CompensationPattern pattern;

  /// Null when the pattern was not present in the initial assessment.
  final CompensationSeverity? beforeSeverity;

  /// Null when the pattern resolved completely in the re-assessment.
  final CompensationSeverity? afterSeverity;

  const CompensationChange({
    required this.pattern,
    required this.beforeSeverity,
    required this.afterSeverity,
  });

  CompensationChangeType get changeType {
    if (beforeSeverity == null && afterSeverity != null) {
      return CompensationChangeType.newlyDetected;
    }
    if (beforeSeverity != null && afterSeverity == null) {
      return CompensationChangeType.resolved;
    }
    if (beforeSeverity != null && afterSeverity != null) {
      if (afterSeverity!.index < beforeSeverity!.index) {
        return CompensationChangeType.improved;
      }
      if (afterSeverity!.index > beforeSeverity!.index) {
        return CompensationChangeType.worsened;
      }
    }
    return CompensationChangeType.unchanged;
  }
}

enum CompensationChangeType {
  /// Pattern improved (severity reduced)
  improved,

  /// Pattern fully resolved (no longer detected)
  resolved,

  /// Pattern unchanged
  unchanged,

  /// Pattern worsened (severity increased)
  worsened,

  /// Pattern newly detected in re-assessment
  newlyDetected,
}
