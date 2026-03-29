import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/programs/domain/usecases/generate_program_from_assessment.dart';

void main() {
  group('GenerateProgramFromAssessment', () {
    test('returns Program with corrective exercises for detected compensations',
        () {
      final program = GenerateProgramFromAssessment.call(
        compensations: [
          CompensationPattern.anteriorPelvicTilt,
          CompensationPattern.poorCoreStability,
        ],
        userId: 'user_1',
      );

      expect(program.userId, 'user_1');
      expect(program.isActive, false);
      expect(program.durationWeeks, 8);

      // Should have at least some training days
      final trainingDays =
          program.weekTemplate.days.values.where((d) => !d.isRestDay).toList();
      expect(trainingDays, isNotEmpty);

      // Training days should have exercises
      for (final day in trainingDays) {
        expect(day.exerciseEntries, isNotEmpty);
      }
    });

    test('training days contain exercises mapped from compensations', () {
      final program = GenerateProgramFromAssessment.call(
        compensations: [CompensationPattern.anteriorPelvicTilt],
        userId: 'user_1',
      );

      final allExerciseIds = program.weekTemplate.days.values
          .expand((d) => d.exerciseEntries.map((e) => e.exerciseId))
          .toSet();

      // anteriorPelvicTilt maps to ex_90_90_breathing, ex_deadbug, ex_couch_stretch
      expect(
        allExerciseIds.any((id) => [
              'ex_90_90_breathing',
              'ex_deadbug',
              'ex_couch_stretch'
            ].contains(id)),
        isTrue,
      );
    });

    test('produces program with default name and goal when no compensations',
        () {
      final program = GenerateProgramFromAssessment.call(
        compensations: [],
        userId: 'user_1',
      );

      expect(program.name, isNotEmpty);
      expect(program.goal, isNotEmpty);
    });

    test('exercise entries have sets and reps set', () {
      final program = GenerateProgramFromAssessment.call(
        compensations: [CompensationPattern.roundedShoulders],
        userId: 'user_1',
      );

      for (final day in program.weekTemplate.days.values) {
        for (final entry in day.exerciseEntries) {
          expect(entry.sets, greaterThan(0));
          expect(entry.reps, isNotEmpty);
        }
      }
    });
  });
}
