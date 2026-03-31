import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/entities/compensation_report.dart';
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import '../entities/program.dart';

/// Pure Dart domain service — no Firebase, no async.
///
/// Generates a corrective [Program] from a [CompensationReport] and [UserProfile]:
/// - Prioritises compensations by severity (significant → moderate → mild)
/// - Filters exercises by the user's available equipment
/// - Distributes exercises across the user's preferred training days
/// - Links the program to the source assessment via [Program.basedOnAssessmentId]
abstract class ProgramRecommendationEngine {
  static const _defaultTrainingDays = 3;

  static Program generate({
    required CompensationReport report,
    required UserProfile profile,
  }) {
    final sorted = report.sortedByPriority;
    final userEquipment = profile.availableEquipment.toSet();

    final exerciseIds = _collectExercises(sorted, userEquipment);
    final dayIndices = _trainingDayIndices(
        profile.trainingDaysPerWeek ?? _defaultTrainingDays);
    final weekTemplate = _buildWeekTemplate(exerciseIds, dayIndices, sorted);

    return Program(
      id: '',
      userId: profile.id,
      name: sorted.isEmpty
          ? 'Movement Maintenance Program'
          : 'Corrective Movement Program',
      goal: _buildGoal(sorted),
      durationWeeks: 8,
      weekTemplate: weekTemplate,
      isActive: false,
      createdAt: DateTime.now(),
      basedOnAssessmentId: report.assessmentId,
    );
  }

  // ── Exercise collection ────────────────────────────────────────────────────

  /// Collects exercise IDs in compensation-priority order, filtered by equipment.
  /// Falls back to a bodyweight set when no compensations are detected.
  static List<String> _collectExercises(
    List<DetectedCompensation> sorted,
    Set<String> userEquipment,
  ) {
    final seen = <String>{};
    final result = <String>[];

    for (final detection in sorted) {
      for (final id in _patternToExercises[detection.pattern] ?? <String>[]) {
        if (!seen.contains(id) && _isAvailable(id, userEquipment)) {
          seen.add(id);
          result.add(id);
        }
      }
    }

    if (result.isEmpty) {
      for (final id in _fallbackExercises) {
        if (_isAvailable(id, userEquipment)) result.add(id);
      }
    }

    return result;
  }

  /// Returns true if the exercise can be performed with the user's equipment.
  /// Exercises with no equipment requirement (bodyweight) always pass.
  static bool _isAvailable(String exerciseId, Set<String> userEquipment) {
    final required = _exerciseEquipment[exerciseId];
    if (required == null || required.isEmpty) return true;
    return required.any(userEquipment.contains);
  }

  // ── Training day selection ─────────────────────────────────────────────────

  /// Returns day-of-week indices (0=Mon … 6=Sun) for [n] training days.
  static List<int> _trainingDayIndices(int n) {
    final clamped = n.clamp(1, 7);
    if (clamped == 1) return [0];
    if (clamped == 2) return [0, 3];
    if (clamped == 3) return [0, 2, 4];
    if (clamped == 4) return [0, 1, 3, 4];
    if (clamped == 5) return [0, 1, 2, 3, 4];
    if (clamped == 6) return [0, 1, 2, 3, 4, 5];
    return [0, 1, 2, 3, 4, 5, 6];
  }

  // ── Week template construction ─────────────────────────────────────────────

  static WeekTemplate _buildWeekTemplate(
    List<String> exerciseIds,
    List<int> dayIndices,
    List<DetectedCompensation> sorted,
  ) {
    final n = dayIndices.length;
    final chunks = _splitIntoChunks(exerciseIds, n);

    final days = <int, DayTemplate>{
      for (int i = 0; i < 7; i++) i: DayTemplate.rest,
    };

    for (int i = 0; i < n; i++) {
      final chunk = chunks[i];
      final focus = n == 1
          ? 'Corrective Work'
          : 'Corrective Work ${String.fromCharCode(65 + i)}';

      if (chunk.isEmpty) continue;

      days[dayIndices[i]] = DayTemplate(
        focus: focus,
        exerciseEntries: chunk
            .map((id) => ExerciseEntry(
                  exerciseId: id,
                  sets: _setsFor(id, sorted),
                  reps: _repsFor(id, sorted),
                ))
            .toList(),
        isRestDay: false,
      );
    }

    return WeekTemplate(days: days);
  }

  static int _setsFor(String exerciseId, List<DetectedCompensation> sorted) {
    return _severityFor(exerciseId, sorted) == CompensationSeverity.mild
        ? 2
        : 3;
  }

  static String _repsFor(String exerciseId, List<DetectedCompensation> sorted) {
    final severity = _severityFor(exerciseId, sorted);
    if (severity == CompensationSeverity.significant) return '12';
    if (severity == CompensationSeverity.moderate) return '10';
    return '12';
  }

  static CompensationSeverity _severityFor(
    String exerciseId,
    List<DetectedCompensation> sorted,
  ) {
    for (final detection in sorted) {
      if ((_patternToExercises[detection.pattern] ?? []).contains(exerciseId)) {
        return detection.severity;
      }
    }
    return CompensationSeverity.mild;
  }

  // ── Goal string ────────────────────────────────────────────────────────────

  static String _buildGoal(List<DetectedCompensation> sorted) {
    final intro = sorted.isEmpty
        ? 'Maintain and improve movement quality.'
        : 'Address ${sorted.length} detected movement pattern${sorted.length == 1 ? '' : 's'}.';
    return '$intro '
        'Weeks 1–2: corrective focus. '
        'Weeks 3–4: integration & strength. '
        'Weeks 5–8: maintenance.';
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  /// Distributes [list] items across [n] buckets round-robin so that buckets
  /// fill as evenly as possible (e.g. 4 items into 3 → [2,1,1]).
  static List<List<T>> _splitIntoChunks<T>(List<T> list, int n) {
    if (n <= 0) return [];
    if (list.isEmpty) return List.generate(n, (_) => []);
    final chunks = List.generate(n, (_) => <T>[]);
    for (int i = 0; i < list.length; i++) {
      chunks[i % n].add(list[i]);
    }
    return chunks;
  }

  // ── Static data ────────────────────────────────────────────────────────────

  /// Maps each [CompensationPattern] to ordered exercise IDs.
  static const Map<CompensationPattern, List<String>> _patternToExercises = {
    CompensationPattern.forwardHeadPosture: [
      'ex_chin_tuck',
      'ex_dns_prone_forearm',
    ],
    CompensationPattern.roundedShoulders: [
      'ex_wall_slide',
      'ex_ys_ts',
      'ex_face_pull',
    ],
    CompensationPattern.anteriorPelvicTilt: [
      'ex_90_90_breathing',
      'ex_deadbug',
      'ex_couch_stretch',
    ],
    CompensationPattern.excessiveLumbarLordosis: [
      'ex_90_90_breathing',
      'ex_deadbug',
      'ex_couch_stretch',
    ],
    CompensationPattern.poorCoreStability: [
      'ex_deadbug',
      'ex_bird_dog',
      'ex_plank',
      'ex_rkg_plank',
    ],
    CompensationPattern.weakGluteMed: [
      'ex_clamshell',
      'ex_single_leg_glute_bridge',
    ],
    CompensationPattern.limitedDorsiflexion: [
      'ex_ankle_car',
      'ex_calf_stretch',
    ],
    CompensationPattern.overPronation: [
      'ex_ankle_car',
      'ex_calf_stretch',
    ],
    CompensationPattern.thoracicKyphosis: [
      'ex_thoracic_rotation',
      'ex_thoracic_extension_bench',
      'ex_cat_cow',
    ],
    CompensationPattern.limitedThoracicRotation: [
      'ex_thoracic_rotation',
      'ex_cat_cow',
    ],
    CompensationPattern.kneeValgus: [
      'ex_clamshell',
      'ex_glute_bridge',
    ],
    CompensationPattern.limitedHipInternalRotation: [
      'ex_hip_90_90',
      'ex_hip_90_90_lift',
      'ex_hip_car',
    ],
    CompensationPattern.limitedHipExternalRotation: [
      'ex_hip_90_90',
      'ex_hip_car',
    ],
    CompensationPattern.posteriorPelvicTilt: [
      'ex_hip_hinge',
      'ex_deadbug',
    ],
  };

  /// Exercises that require specific equipment.
  /// Absent = bodyweight (always available).
  static const Map<String, List<String>> _exerciseEquipment = {
    'ex_ys_ts': ['resistance_band', 'dumbbells'],
    'ex_face_pull': ['resistance_band', 'cable_machine'],
    'ex_thoracic_extension_bench': ['bench', 'foam_roller'],
  };

  /// Used when the compensation report has no detections.
  static const List<String> _fallbackExercises = [
    'ex_90_90_breathing',
    'ex_deadbug',
    'ex_bird_dog',
    'ex_hip_90_90',
    'ex_cat_cow',
    'ex_wall_slide',
  ];
}
