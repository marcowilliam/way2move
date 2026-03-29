import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import '../entities/program.dart';

/// Generates a starter corrective program from assessment compensation patterns.
///
/// Produces 3 training days per week (Mon, Wed, Fri) with exercises
/// mapped from detected compensations. No repository needed — pure logic.
abstract class GenerateProgramFromAssessment {
  static Program call({
    required List<CompensationPattern> compensations,
    required String userId,
  }) {
    final exerciseIds = _collectExerciseIds(compensations);
    final weekTemplate = _buildWeekTemplate(exerciseIds);
    final goal = compensations.isEmpty
        ? 'Maintain and improve movement quality'
        : 'Address ${compensations.length} detected movement pattern${compensations.length == 1 ? '' : 's'}';

    return Program(
      id: '',
      userId: userId,
      name: 'Corrective Movement Program',
      goal: goal,
      durationWeeks: 8,
      weekTemplate: weekTemplate,
      isActive: false,
      createdAt: DateTime.now(),
    );
  }

  static List<String> _collectExerciseIds(
      List<CompensationPattern> compensations) {
    final Set<String> ids = {};
    for (final pattern in compensations) {
      ids.addAll(_patternToExercises[pattern] ?? []);
    }
    // If no specific exercises found, fall back to general corrective set
    if (ids.isEmpty) {
      ids.addAll([
        'ex_90_90_breathing',
        'ex_deadbug',
        'ex_bird_dog',
        'ex_hip_90_90',
        'ex_cat_cow',
        'ex_wall_slide',
      ]);
    }
    return ids.toList();
  }

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
    CompensationPattern.limitedHipInternalRotation: [
      'ex_hip_90_90',
      'ex_hip_90_90_lift',
      'ex_hip_car',
    ],
    CompensationPattern.limitedDorsiflexion: [
      'ex_ankle_car',
      'ex_calf_stretch',
    ],
    CompensationPattern.thoracicKyphosis: [
      'ex_thoracic_rotation',
      'ex_thoracic_extension_bench',
      'ex_cat_cow',
    ],
    CompensationPattern.kneeValgus: [
      'ex_clamshell',
      'ex_glute_bridge',
    ],
    CompensationPattern.overPronation: [
      'ex_ankle_car',
      'ex_calf_stretch',
    ],
    CompensationPattern.limitedThoracicRotation: [
      'ex_thoracic_rotation',
      'ex_cat_cow',
    ],
    CompensationPattern.excessiveLumbarLordosis: [
      'ex_90_90_breathing',
      'ex_deadbug',
      'ex_couch_stretch',
    ],
    CompensationPattern.posteriorPelvicTilt: [
      'ex_hip_hinge',
      'ex_deadbug',
    ],
    CompensationPattern.limitedHipExternalRotation: [
      'ex_hip_90_90',
      'ex_hip_car',
    ],
  };

  static WeekTemplate _buildWeekTemplate(List<String> exerciseIds) {
    final chunks = _splitIntoChunks(exerciseIds, 3);

    DayTemplate buildDay(int chunkIndex, String focus) {
      final entries = chunkIndex < chunks.length
          ? chunks[chunkIndex]
              .map((id) => ExerciseEntry(
                    exerciseId: id,
                    sets: 3,
                    reps: '10',
                  ))
              .toList()
          : <ExerciseEntry>[];
      return DayTemplate(
        focus: focus,
        exerciseEntries: entries,
        isRestDay: entries.isEmpty,
      );
    }

    return WeekTemplate(days: {
      0: buildDay(0, 'Day 1 — Corrective Work'), // Mon
      1: DayTemplate.rest, // Tue
      2: buildDay(1, 'Day 2 — Corrective Work'), // Wed
      3: DayTemplate.rest, // Thu
      4: buildDay(2, 'Day 3 — Corrective Work'), // Fri
      5: DayTemplate.rest, // Sat
      6: DayTemplate.rest, // Sun
    });
  }

  /// Splits [list] into at most [n] roughly equal chunks.
  static List<List<T>> _splitIntoChunks<T>(List<T> list, int n) {
    if (list.isEmpty) return List.generate(n, (_) => []);
    final chunkSize = (list.length / n).ceil();
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    // Pad to exactly n chunks
    while (chunks.length < n) {
      chunks.add([]);
    }
    return chunks;
  }
}
