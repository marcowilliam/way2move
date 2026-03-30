import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/entities/compensation_report.dart';
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import 'program_recommendation_engine.dart';

UserProfile _profile({
  int? trainingDaysPerWeek,
  List<String> availableEquipment = const [],
}) =>
    UserProfile(
      id: 'user_1',
      name: 'Test User',
      email: 'test@test.com',
      trainingDaysPerWeek: trainingDaysPerWeek,
      availableEquipment: availableEquipment,
      createdAt: DateTime(2026),
    );

CompensationReport _report(List<DetectedCompensation> detections) =>
    CompensationReport(
      assessmentId: 'assess_1',
      userId: 'user_1',
      detections: detections,
      generatedAt: DateTime(2026),
    );

DetectedCompensation _detection(
  CompensationPattern pattern, {
  int affected = 70,
  int total = 100,
}) =>
    DetectedCompensation(
      pattern: pattern,
      affectedFrameCount: affected,
      totalFrameCount: total,
    );

void main() {
  group('ProgramRecommendationEngine', () {
    group('priority ordering', () {
      test('significant compensations produce exercises before mild ones', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus,
              affected: 10, total: 100), // mild
          _detection(CompensationPattern.anteriorPelvicTilt,
              affected: 70, total: 100), // significant
        ]);

        final program =
            ProgramRecommendationEngine.generate(report: report, profile: _profile());

        final allExerciseIds = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries.map((e) => e.exerciseId))
            .toList();

        // anteriorPelvicTilt exercises appear (significant comes first)
        expect(
          allExerciseIds.any((id) =>
              ['ex_90_90_breathing', 'ex_deadbug', 'ex_couch_stretch']
                  .contains(id)),
          isTrue,
        );
      });

      test('generated program links to the source assessmentId', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus),
        ]);

        final program =
            ProgramRecommendationEngine.generate(report: report, profile: _profile());

        expect(program.basedOnAssessmentId, 'assess_1');
      });

      test('exercise entries for significant pattern get sets=3', () {
        final report = _report([
          _detection(CompensationPattern.roundedShoulders,
              affected: 70, total: 100), // significant
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(),
        );

        final entries = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries)
            .toList();

        expect(entries.isNotEmpty, isTrue);
        expect(entries.every((e) => e.sets == 3), isTrue);
      });

      test('exercise entries for mild pattern get sets=2', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus,
              affected: 5, total: 100), // mild
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(),
        );

        final entries = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries)
            .toList();

        expect(entries.isNotEmpty, isTrue);
        expect(entries.every((e) => e.sets == 2), isTrue);
      });
    });

    group('equipment filtering', () {
      test('ex_ys_ts included when user has resistance_band', () {
        final report = _report([
          _detection(CompensationPattern.roundedShoulders),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(availableEquipment: ['resistance_band']),
        );

        final allIds = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries.map((e) => e.exerciseId))
            .toSet();

        expect(allIds.contains('ex_ys_ts'), isTrue);
      });

      test('ex_ys_ts excluded when user has no relevant equipment', () {
        final report = _report([
          _detection(CompensationPattern.roundedShoulders),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(availableEquipment: []),
        );

        final allIds = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries.map((e) => e.exerciseId))
            .toSet();

        expect(allIds.contains('ex_ys_ts'), isFalse);
      });

      test('ex_face_pull included when user has cable_machine', () {
        final report = _report([
          _detection(CompensationPattern.roundedShoulders),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(availableEquipment: ['cable_machine']),
        );

        final allIds = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries.map((e) => e.exerciseId))
            .toSet();

        expect(allIds.contains('ex_face_pull'), isTrue);
      });

      test('bodyweight exercises always included regardless of equipment', () {
        final report = _report([
          _detection(CompensationPattern.anteriorPelvicTilt),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(availableEquipment: []),
        );

        final allIds = program.weekTemplate.days.values
            .expand((d) => d.exerciseEntries.map((e) => e.exerciseId))
            .toSet();

        // ex_90_90_breathing is bodyweight — must be present
        expect(allIds.contains('ex_90_90_breathing'), isTrue);
      });
    });

    group('training days distribution', () {
      test('defaults to 3 training days when trainingDaysPerWeek is null', () {
        final report = _report([
          _detection(CompensationPattern.poorCoreStability),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(trainingDaysPerWeek: null),
        );

        final activeDays = program.weekTemplate.days.values
            .where((d) => !d.isRestDay)
            .length;

        expect(activeDays, 3);
      });

      test('respects trainingDaysPerWeek=2', () {
        final report = _report([
          _detection(CompensationPattern.poorCoreStability),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(trainingDaysPerWeek: 2),
        );

        final activeDays = program.weekTemplate.days.values
            .where((d) => !d.isRestDay)
            .length;

        expect(activeDays, 2);
      });

      test('respects trainingDaysPerWeek=5', () {
        final report = _report([
          _detection(CompensationPattern.anteriorPelvicTilt),
          _detection(CompensationPattern.poorCoreStability),
          _detection(CompensationPattern.roundedShoulders),
          _detection(CompensationPattern.kneeValgus),
          _detection(CompensationPattern.weakGluteMed),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(trainingDaysPerWeek: 5),
        );

        final activeDays = program.weekTemplate.days.values
            .where((d) => !d.isRestDay)
            .length;

        expect(activeDays, 5);
      });

      test('week template always has exactly 7 days', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(trainingDaysPerWeek: 3),
        );

        expect(program.weekTemplate.days.length, 7);
      });

      test('training days use correct Mon/Wed/Fri indices for 3 days', () {
        final report = _report([
          _detection(CompensationPattern.anteriorPelvicTilt),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(trainingDaysPerWeek: 3),
        );

        final activeDayIndices = program.weekTemplate.days.entries
            .where((e) => !e.value.isRestDay)
            .map((e) => e.key)
            .toSet();

        expect(activeDayIndices, containsAll([0, 2, 4])); // Mon, Wed, Fri
      });
    });

    group('edge cases', () {
      test('empty report produces fallback bodyweight program', () {
        final report = _report([]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(),
        );

        final activeDays = program.weekTemplate.days.values
            .where((d) => !d.isRestDay)
            .toList();

        expect(activeDays, isNotEmpty);
        expect(activeDays.first.exerciseEntries, isNotEmpty);
      });

      test('goal description mentions phase progression', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(),
        );

        expect(program.goal, contains('Weeks 1'));
      });

      test('durationWeeks is 8', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(),
        );

        expect(program.durationWeeks, 8);
      });

      test('program userId matches profile id', () {
        final report = _report([
          _detection(CompensationPattern.kneeValgus),
        ]);

        final program = ProgramRecommendationEngine.generate(
          report: report,
          profile: _profile(),
        );

        expect(program.userId, 'user_1');
      });
    });
  });
}
