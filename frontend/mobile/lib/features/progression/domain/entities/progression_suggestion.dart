enum ProgressionAction {
  increaseReps,
  increaseLoad,
  advanceVariation,
  deload,
  hold,
}

enum SuggestionType {
  progression,
  deload,
}

class ProgressionSuggestion {
  final String exerciseId;
  final String exerciseName;
  final ProgressionAction action;
  final String? nextExerciseId;
  final int? newReps;
  final double? newWeight;
  final String reason;
  final SuggestionType type;

  const ProgressionSuggestion({
    required this.exerciseId,
    required this.exerciseName,
    required this.action,
    this.nextExerciseId,
    this.newReps,
    this.newWeight,
    required this.reason,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      other is ProgressionSuggestion &&
      other.exerciseId == exerciseId &&
      other.action == action &&
      other.type == type;

  @override
  int get hashCode => Object.hash(exerciseId, action, type);
}
