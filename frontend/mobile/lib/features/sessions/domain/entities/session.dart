enum SessionStatus { planned, inProgress, completed, skipped }

class SetEntry {
  final int setNumber;
  final int? reps;
  final String? weight; // e.g. "50kg", "BW", "Red band"
  final bool completed;

  const SetEntry({
    required this.setNumber,
    this.reps,
    this.weight,
    required this.completed,
  });

  SetEntry copyWith({
    int? setNumber,
    int? reps,
    String? weight,
    bool? completed,
  }) =>
      SetEntry(
        setNumber: setNumber ?? this.setNumber,
        reps: reps ?? this.reps,
        weight: weight ?? this.weight,
        completed: completed ?? this.completed,
      );

  @override
  bool operator ==(Object other) =>
      other is SetEntry && other.setNumber == setNumber;

  @override
  int get hashCode => setNumber.hashCode;
}

class ExerciseBlock {
  final String exerciseId;
  final int plannedSets;
  final String plannedReps; // e.g. "10", "30s", "AMRAP"
  final List<SetEntry> actualSets;
  final int? rpe; // Rate of Perceived Exertion 1–10
  final String? notes;

  const ExerciseBlock({
    required this.exerciseId,
    required this.plannedSets,
    required this.plannedReps,
    this.actualSets = const [],
    this.rpe,
    this.notes,
  });

  bool get isStarted => actualSets.isNotEmpty;
  int get completedSetsCount => actualSets.where((s) => s.completed).length;

  ExerciseBlock copyWith({
    String? exerciseId,
    int? plannedSets,
    String? plannedReps,
    List<SetEntry>? actualSets,
    int? rpe,
    String? notes,
  }) =>
      ExerciseBlock(
        exerciseId: exerciseId ?? this.exerciseId,
        plannedSets: plannedSets ?? this.plannedSets,
        plannedReps: plannedReps ?? this.plannedReps,
        actualSets: actualSets ?? this.actualSets,
        rpe: rpe ?? this.rpe,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      other is ExerciseBlock && other.exerciseId == exerciseId;

  @override
  int get hashCode => exerciseId.hashCode;
}

class Session {
  final String id;
  final String userId;
  final String? programId; // null for standalone sessions
  final String? focus; // copied from DayTemplate.focus
  final DateTime date;
  final SessionStatus status;
  final List<ExerciseBlock> exerciseBlocks;
  final String? notes;
  final int? durationMinutes;

  const Session({
    required this.id,
    required this.userId,
    this.programId,
    this.focus,
    required this.date,
    required this.status,
    required this.exerciseBlocks,
    this.notes,
    this.durationMinutes,
  });

  int get completedBlocksCount =>
      exerciseBlocks.where((b) => b.isStarted).length;

  bool get hasAnyWork => exerciseBlocks.any((b) => b.isStarted);

  Session copyWith({
    String? id,
    String? userId,
    String? programId,
    String? focus,
    DateTime? date,
    SessionStatus? status,
    List<ExerciseBlock>? exerciseBlocks,
    String? notes,
    int? durationMinutes,
  }) =>
      Session(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        programId: programId ?? this.programId,
        focus: focus ?? this.focus,
        date: date ?? this.date,
        status: status ?? this.status,
        exerciseBlocks: exerciseBlocks ?? this.exerciseBlocks,
        notes: notes ?? this.notes,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );

  @override
  bool operator ==(Object other) => other is Session && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
