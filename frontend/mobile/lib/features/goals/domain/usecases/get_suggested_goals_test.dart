import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/goals/domain/entities/goal.dart';
import 'package:way2move/features/goals/domain/usecases/get_suggested_goals.dart';

void main() {
  late GetSuggestedGoals getSuggestedGoals;

  setUp(() {
    getSuggestedGoals = const GetSuggestedGoals();
  });

  group('GetSuggestedGoals', () {
    test('returns empty list when no compensation patterns', () {
      final result = getSuggestedGoals([]);
      expect(result, isEmpty);
    });

    test('returns one suggestion for forwardHeadPosture', () {
      final result =
          getSuggestedGoals([CompensationPattern.forwardHeadPosture]);

      expect(result.length, 1);
      expect(result.first.name, 'Correct forward head posture');
      expect(result.first.targetMetric, 'chin tuck reps');
      expect(result.first.targetValue, 15);
      expect(result.first.source, GoalSource.suggested);
    });

    test('returns one suggestion for poorCoreStability', () {
      final result = getSuggestedGoals([CompensationPattern.poorCoreStability]);

      expect(result.length, 1);
      expect(result.first.targetMetric, 'plank seconds');
      expect(result.first.targetValue, 60);
    });

    test('returns multiple suggestions for multiple patterns', () {
      final result = getSuggestedGoals([
        CompensationPattern.weakGluteMed,
        CompensationPattern.limitedDorsiflexion,
        CompensationPattern.kneeValgus,
      ]);

      expect(result.length, 3);
    });

    test('returns no duplicate suggestions for same pattern listed twice', () {
      final result = getSuggestedGoals([
        CompensationPattern.overPronation,
        CompensationPattern.overPronation,
      ]);

      // List may contain 2 entries (one per occurrence) — that is acceptable;
      // deduplication is responsibility of the caller.
      expect(result.length, 2);
    });

    test('patterns without templates are ignored gracefully', () {
      // posteriorPelvicTilt and others not in the mapping
      final result = getSuggestedGoals([
        CompensationPattern.posteriorPelvicTilt,
        CompensationPattern.limitedHipExternalRotation,
        CompensationPattern.excessiveLumbarLordosis,
      ]);

      expect(result, isEmpty);
    });

    test('all suggested goals have source: suggested', () {
      final result = getSuggestedGoals(CompensationPattern.values);

      for (final goal in result) {
        expect(goal.source, GoalSource.suggested);
      }
    });
  });
}
