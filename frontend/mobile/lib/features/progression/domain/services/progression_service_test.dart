import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/progression/domain/entities/progression_rule.dart';
import 'package:way2move/features/progression/domain/entities/progression_suggestion.dart';
import 'package:way2move/features/progression/domain/services/progression_service.dart';

void main() {
  late ProgressionService service;
  late ProgressionRule defaultRule;

  setUp(() {
    service = const ProgressionService();
    defaultRule =
        const ProgressionRule(); // threshold: 3 completions, sleep 3.5, pulse 3.0, stomach 3.0
  });

  ProgressionInput makeInput({
    String exerciseId = 'ex1',
    String exerciseName = 'Squat',
    int completedSessionCount = 3,
    double avgSleepQuality = 4.0,
    double pulseScore = 4.0,
    double avgStomachFeeling = 4.0,
    String? nextProgressionId,
    ProgressionRule? rule,
  }) {
    return ProgressionInput(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      completedSessionCount: completedSessionCount,
      avgSleepQuality: avgSleepQuality,
      pulseScore: pulseScore,
      avgStomachFeeling: avgStomachFeeling,
      nextProgressionId: nextProgressionId,
      rule: rule ?? defaultRule,
    );
  }

  group('ProgressionService.evaluate — deload triggers', () {
    test('returns deload when avgSleepQuality is below sleepThreshold', () {
      final input = makeInput(avgSleepQuality: 2.0); // threshold is 3.5
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.deload);
      expect(suggestions.first.type, SuggestionType.deload);
    });

    test('returns deload when pulseScore is below pulseThreshold', () {
      final input = makeInput(pulseScore: 2.0); // threshold is 3.0
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.deload);
      expect(suggestions.first.type, SuggestionType.deload);
    });

    test('returns deload when avgStomachFeeling is below stomachThreshold', () {
      final input = makeInput(avgStomachFeeling: 2.0); // threshold is 3.0
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.deload);
      expect(suggestions.first.type, SuggestionType.deload);
    });

    test('deload reason mentions low sleep when sleep is the trigger', () {
      final input = makeInput(avgSleepQuality: 2.0);
      final suggestions = service.evaluate(input);

      expect(suggestions.first.reason, contains('sleep'));
    });

    test('deload reason mentions multiple triggers when multiple apply', () {
      final input = makeInput(avgSleepQuality: 2.0, pulseScore: 1.5);
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, ProgressionAction.deload);
      expect(suggestions.first.reason, contains('sleep'));
      expect(suggestions.first.reason, contains('energy'));
    });

    test('deload takes priority over progression even when count is high', () {
      final input = makeInput(
        completedSessionCount: 10,
        avgSleepQuality: 1.5, // triggers deload
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, ProgressionAction.deload);
    });
  });

  group('ProgressionService.evaluate — progression triggers', () {
    test(
        'returns advanceVariation when all thresholds met and nextProgressionId exists',
        () {
      final input = makeInput(
        completedSessionCount: 3,
        nextProgressionId: 'ex2',
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.advanceVariation);
      expect(suggestions.first.nextExerciseId, 'ex2');
      expect(suggestions.first.type, SuggestionType.progression);
    });

    test(
        'returns increaseLoad when count is at threshold+2 and no nextProgressionId',
        () {
      final input = makeInput(
        completedSessionCount: 5, // threshold(3) + 2 = 5
        nextProgressionId: null,
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.increaseLoad);
      expect(suggestions.first.newWeight, 2.5);
      expect(suggestions.first.type, SuggestionType.progression);
    });

    test(
        'returns increaseReps when count equals threshold and no nextProgressionId',
        () {
      final input = makeInput(
        completedSessionCount: 3, // exactly threshold
        nextProgressionId: null,
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.increaseReps);
      expect(suggestions.first.newReps, 2);
      expect(suggestions.first.type, SuggestionType.progression);
    });

    test(
        'advanceVariation takes priority over increaseLoad when nextProgressionId exists and count is high',
        () {
      final input = makeInput(
        completedSessionCount: 10,
        nextProgressionId: 'ex_advanced',
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, ProgressionAction.advanceVariation);
    });
  });

  group('ProgressionService.evaluate — hold', () {
    test('returns hold when count is below threshold and no deload triggers',
        () {
      final input = makeInput(completedSessionCount: 2); // threshold is 3
      final suggestions = service.evaluate(input);

      expect(suggestions.length, 1);
      expect(suggestions.first.action, ProgressionAction.hold);
      expect(suggestions.first.type, SuggestionType.progression);
    });

    test('hold reason mentions progress toward threshold', () {
      final input = makeInput(completedSessionCount: 1);
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, ProgressionAction.hold);
      expect(suggestions.first.reason, contains('1'));
      expect(suggestions.first.reason, contains('3'));
    });
  });

  group('ProgressionService.evaluate — zero/no-data handling', () {
    test('zero sleep (no data) does not block progression', () {
      final input = makeInput(
        completedSessionCount: 3,
        avgSleepQuality: 0.0, // no data — should not block
      );
      final suggestions = service.evaluate(input);

      // Should not be hold or deload
      expect(suggestions.first.action, isNot(ProgressionAction.deload));
      expect(suggestions.first.action, isNot(ProgressionAction.hold));
    });

    test('zero pulse (no data) does not block progression', () {
      final input = makeInput(
        completedSessionCount: 3,
        pulseScore: 0.0, // no data
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, isNot(ProgressionAction.deload));
      expect(suggestions.first.action, isNot(ProgressionAction.hold));
    });

    test('zero stomach (no data) does not trigger deload', () {
      final input = makeInput(
        completedSessionCount: 3,
        avgStomachFeeling: 0.0, // no data — should not trigger deload
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, isNot(ProgressionAction.deload));
    });

    test(
        'all zeros (no data at all) with sufficient completions triggers progression',
        () {
      final input = makeInput(
        completedSessionCount: 3,
        avgSleepQuality: 0.0,
        pulseScore: 0.0,
        avgStomachFeeling: 0.0,
      );
      final suggestions = service.evaluate(input);

      expect(suggestions.first.type, SuggestionType.progression);
    });

    test('zero sleep does not trigger deload', () {
      final input = makeInput(avgSleepQuality: 0.0);
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, isNot(ProgressionAction.deload));
    });
  });

  group('ProgressionService.evaluate — custom rules', () {
    test('respects custom completionThreshold', () {
      const customRule = ProgressionRule(completionThreshold: 5);
      final input = makeInput(completedSessionCount: 4, rule: customRule);
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, ProgressionAction.hold);
    });

    test('respects custom sleepThreshold', () {
      const customRule = ProgressionRule(sleepThreshold: 2.0);
      // sleep of 2.5 is above 2.0 threshold — should not deload
      final input = makeInput(avgSleepQuality: 2.5, rule: customRule);
      final suggestions = service.evaluate(input);

      expect(suggestions.first.action, isNot(ProgressionAction.deload));
    });
  });
}
