import '../../../workouts/domain/entities/workout_enums.dart';
import 'sensation_feedback.dart';

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

/// A single exercise block — used both as a *template* slot inside a
/// `Workout` and as an *instance* slot inside a `Session`. Templates
/// leave `actualSets` empty; sessions populate them as the user logs.
///
/// New optional fields (phase / level / category / directions /
/// cuesOverride / currentlyIncluded) come from the Notion
/// `Workout_Exercise database` shape and let a workout's blocks carry
/// per-block coaching context that doesn't live on the canonical
/// Exercise (because the same exercise may show up in multiple workouts
/// with different cues, sets, or progression level).
class ExerciseBlock {
  final String exerciseId;
  final int plannedSets;
  final String plannedReps; // e.g. "10", "30s", "AMRAP"
  final List<SetEntry> actualSets;
  final int? rpe; // Rate of Perceived Exertion 1–10
  final String? notes;

  // --- New fields (training-week organizer) ------------------------------
  /// Where in the workout this block lives. Null on legacy session blocks.
  final ExercisePhase? phase;

  /// Progression level (Notion's "Level" column).
  final ExerciseLevel? level;

  /// Free-text category — Notion's "Category" column. e.g. "Hip flexion",
  /// "Shoulder Flexion / Overhead", "Cranio-cervical stability".
  final String? category;

  /// Verbatim directions from Notion — "3 sets × 6 reps / side, 3s lift /
  /// 3s lower". Render as a sub-label above the SetEntryForm.
  final String? directions;

  /// Block-specific cues that override the canonical
  /// `Exercise.cues`. Empty/null = use the exercise's own cues.
  final List<String>? cuesOverride;

  /// Notion's "Current Included" flag. False = the block is parked for
  /// later (Strength/Integration ladder above the user's current Level)
  /// and shouldn't be surfaced in today's view.
  final bool? currentlyIncluded;

  /// Stable display order within the block's `phase`. Notion's "Order"
  /// column. Defaults to insertion order if null.
  final int? order;

  /// Planned duration in seconds (for time-based / isometric work).
  /// Null for rep-based blocks.
  final int? plannedSeconds;

  /// Planned rest in seconds.
  final int? restSeconds;

  /// Planned weight hint — "50kg", "BW", "Red band".
  final String? plannedWeight;

  const ExerciseBlock({
    required this.exerciseId,
    required this.plannedSets,
    required this.plannedReps,
    this.actualSets = const [],
    this.rpe,
    this.notes,
    this.phase,
    this.level,
    this.category,
    this.directions,
    this.cuesOverride,
    this.currentlyIncluded,
    this.order,
    this.plannedSeconds,
    this.restSeconds,
    this.plannedWeight,
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
    ExercisePhase? phase,
    ExerciseLevel? level,
    String? category,
    String? directions,
    List<String>? cuesOverride,
    bool? currentlyIncluded,
    int? order,
    int? plannedSeconds,
    int? restSeconds,
    String? plannedWeight,
  }) =>
      ExerciseBlock(
        exerciseId: exerciseId ?? this.exerciseId,
        plannedSets: plannedSets ?? this.plannedSets,
        plannedReps: plannedReps ?? this.plannedReps,
        actualSets: actualSets ?? this.actualSets,
        rpe: rpe ?? this.rpe,
        notes: notes ?? this.notes,
        phase: phase ?? this.phase,
        level: level ?? this.level,
        category: category ?? this.category,
        directions: directions ?? this.directions,
        cuesOverride: cuesOverride ?? this.cuesOverride,
        currentlyIncluded: currentlyIncluded ?? this.currentlyIncluded,
        order: order ?? this.order,
        plannedSeconds: plannedSeconds ?? this.plannedSeconds,
        restSeconds: restSeconds ?? this.restSeconds,
        plannedWeight: plannedWeight ?? this.plannedWeight,
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

  // --- New fields (training-week organizer) ------------------------------
  /// The workout template this session was instantiated from. Null for
  /// fully ad-hoc sessions.
  final String? workoutId;

  /// Denormalized from `workouts.kind` for cheap timeline filtering
  /// without a join.
  final WorkoutKind? kind;

  /// Time-of-day bucket. Lets multiple sessions live on the same `date`
  /// without timestamps. Defaults to `flexible` for legacy sessions.
  final SessionSlot? slot;

  /// Coarse duration bucket, derived from `durationMinutes` but stored.
  final DurationCategory? durationCategory;

  /// Where the session happened — "Econofitness", "Home", "Park".
  /// Mirrors Notion's "Place" column.
  final String? place;

  /// Post-session body-listening capture.
  final SensationFeedback? sensationFeedback;

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
    this.workoutId,
    this.kind,
    this.slot,
    this.durationCategory,
    this.place,
    this.sensationFeedback,
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
    String? workoutId,
    WorkoutKind? kind,
    SessionSlot? slot,
    DurationCategory? durationCategory,
    String? place,
    SensationFeedback? sensationFeedback,
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
        workoutId: workoutId ?? this.workoutId,
        kind: kind ?? this.kind,
        slot: slot ?? this.slot,
        durationCategory: durationCategory ?? this.durationCategory,
        place: place ?? this.place,
        sensationFeedback: sensationFeedback ?? this.sensationFeedback,
      );

  @override
  bool operator ==(Object other) => other is Session && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
