import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/progression/domain/entities/progression_rule.dart';
import 'package:way2move/features/progression/domain/entities/progression_suggestion.dart';
import 'package:way2move/features/progression/domain/services/progression_service.dart';
import 'package:way2move/features/progression/domain/usecases/evaluate_progression.dart';

void main() {
  late EvaluateProgression evaluateProgression;

  setUp(() {
    evaluateProgression = const EvaluateProgression(ProgressionService());
  });

  test('returns Right with progression suggestions on valid input', () {
    const input = ProgressionInput(
      exerciseId: 'ex1',
      exerciseName: 'Deadlift',
      completedSessionCount: 3,
      avgSleepQuality: 4.0,
      pulseScore: 4.0,
      avgStomachFeeling: 4.0,
      rule: ProgressionRule(),
    );

    final result = evaluateProgression(input);

    expect(result.isRight(), true);
    final suggestions = result.getRight().toNullable() ?? [];
    expect(suggestions, isNotEmpty);
  });

  test('returns deload suggestion when body signals are low', () {
    const input = ProgressionInput(
      exerciseId: 'ex1',
      exerciseName: 'Deadlift',
      completedSessionCount: 5,
      avgSleepQuality: 2.0, // below 3.5 threshold
      pulseScore: 4.0,
      avgStomachFeeling: 4.0,
      rule: ProgressionRule(),
    );

    final result = evaluateProgression(input);

    expect(result.isRight(), true);
    final suggestions = result.getRight().toNullable() ?? [];
    expect(suggestions.first.action, ProgressionAction.deload);
  });

  test('returns hold when count is below threshold', () {
    const input = ProgressionInput(
      exerciseId: 'ex1',
      exerciseName: 'Push-up',
      completedSessionCount: 1,
      avgSleepQuality: 4.0,
      pulseScore: 4.0,
      avgStomachFeeling: 4.0,
      rule: ProgressionRule(),
    );

    final result = evaluateProgression(input);

    expect(result.isRight(), true);
    final suggestions = result.getRight().toNullable() ?? [];
    expect(suggestions.first.action, ProgressionAction.hold);
  });
}
