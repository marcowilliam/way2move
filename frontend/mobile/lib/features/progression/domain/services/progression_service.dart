import '../entities/progression_rule.dart';
import '../entities/progression_suggestion.dart';

class ProgressionInput {
  final String exerciseId;
  final String exerciseName;
  final int completedSessionCount;
  final double avgSleepQuality; // 0.0 = no data
  final double
      pulseScore; // composite: (energy + motivation - soreness) / 3; 0.0 = no data
  final double avgStomachFeeling; // 0.0 = no data
  final String? nextProgressionId;
  final ProgressionRule rule;

  const ProgressionInput({
    required this.exerciseId,
    required this.exerciseName,
    required this.completedSessionCount,
    this.avgSleepQuality = 0.0,
    this.pulseScore = 0.0,
    this.avgStomachFeeling = 0.0,
    this.nextProgressionId,
    required this.rule,
  });
}

/// Pure Dart domain service — no Flutter/Firebase imports.
/// Takes [ProgressionInput] and returns a list of [ProgressionSuggestion].
class ProgressionService {
  const ProgressionService();

  List<ProgressionSuggestion> evaluate(ProgressionInput input) {
    final rule = input.rule;

    // Check deload conditions — any one triggers deload
    final sleepBelowThreshold = input.avgSleepQuality > 0 &&
        input.avgSleepQuality < rule.sleepThreshold;
    final pulseBelowThreshold =
        input.pulseScore > 0 && input.pulseScore < rule.pulseThreshold;
    final stomachBelowThreshold = input.avgStomachFeeling > 0 &&
        input.avgStomachFeeling < rule.stomachThreshold;

    if (sleepBelowThreshold || pulseBelowThreshold || stomachBelowThreshold) {
      final reasons = <String>[];
      if (sleepBelowThreshold) reasons.add('low sleep quality');
      if (pulseBelowThreshold) reasons.add('low energy/motivation');
      if (stomachBelowThreshold) reasons.add('poor gut feeling');

      return [
        ProgressionSuggestion(
          exerciseId: input.exerciseId,
          exerciseName: input.exerciseName,
          action: ProgressionAction.deload,
          reason:
              'Body signals suggest recovery is needed: ${reasons.join(', ')}',
          type: SuggestionType.deload,
        ),
      ];
    }

    // Check progression conditions
    // Sleep/pulse/stomach of 0 means no data — do not block progression
    final sleepOk = input.avgSleepQuality == 0 ||
        input.avgSleepQuality >= rule.sleepThreshold;
    final pulseOk =
        input.pulseScore == 0 || input.pulseScore >= rule.pulseThreshold;

    final readyToProgress =
        input.completedSessionCount >= rule.completionThreshold &&
            sleepOk &&
            pulseOk;

    if (readyToProgress) {
      return [_buildProgressionSuggestion(input)];
    }

    // Hold — not enough completions and no deload triggers
    return [
      ProgressionSuggestion(
        exerciseId: input.exerciseId,
        exerciseName: input.exerciseName,
        action: ProgressionAction.hold,
        reason:
            'Keep going — ${input.completedSessionCount}/${rule.completionThreshold} sessions completed.',
        type: SuggestionType.progression,
      ),
    ];
  }

  ProgressionSuggestion _buildProgressionSuggestion(ProgressionInput input) {
    final rule = input.rule;

    // Priority 1: advance variation if nextProgressionId exists
    if (input.nextProgressionId != null &&
        input.nextProgressionId!.isNotEmpty) {
      return ProgressionSuggestion(
        exerciseId: input.exerciseId,
        exerciseName: input.exerciseName,
        action: ProgressionAction.advanceVariation,
        nextExerciseId: input.nextProgressionId,
        reason:
            "You've completed ${input.completedSessionCount} sessions. Time to advance to the next variation.",
        type: SuggestionType.progression,
      );
    }

    // Priority 2: increase load if count is significantly over threshold
    if (input.completedSessionCount >= rule.completionThreshold + 2) {
      return ProgressionSuggestion(
        exerciseId: input.exerciseId,
        exerciseName: input.exerciseName,
        action: ProgressionAction.increaseLoad,
        newWeight: 2.5,
        reason:
            'Strong consistency — ${input.completedSessionCount} sessions done. Try adding 2.5kg.',
        type: SuggestionType.progression,
      );
    }

    // Priority 3: increase reps
    return ProgressionSuggestion(
      exerciseId: input.exerciseId,
      exerciseName: input.exerciseName,
      action: ProgressionAction.increaseReps,
      newReps: 2,
      reason:
          "You've hit ${input.completedSessionCount} sessions. Add 2 more reps next time.",
      type: SuggestionType.progression,
    );
  }
}
