import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../../domain/entities/sensation_feedback.dart';
import '../../domain/entities/session.dart';

class SetEntryModel {
  final int setNumber;
  final int? reps;
  final String? weight;
  final bool completed;

  const SetEntryModel({
    required this.setNumber,
    this.reps,
    this.weight,
    required this.completed,
  });

  factory SetEntryModel.fromMap(Map<String, dynamic> data) => SetEntryModel(
        setNumber: (data['setNumber'] as num).toInt(),
        reps: data['reps'] != null ? (data['reps'] as num).toInt() : null,
        weight: data['weight'] as String?,
        completed: data['completed'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
        'completed': completed,
      };

  SetEntry toEntity() => SetEntry(
        setNumber: setNumber,
        reps: reps,
        weight: weight,
        completed: completed,
      );

  factory SetEntryModel.fromEntity(SetEntry e) => SetEntryModel(
        setNumber: e.setNumber,
        reps: e.reps,
        weight: e.weight,
        completed: e.completed,
      );
}

class ExerciseBlockModel {
  final String exerciseId;
  final int plannedSets;
  final String plannedReps;
  final List<SetEntryModel> actualSets;
  final int? rpe;
  final String? notes;

  // Extended fields (training-week organizer)
  final ExercisePhase? phase;
  final ExerciseLevel? level;
  final String? category;
  final String? directions;
  final List<String>? cuesOverride;
  final bool? currentlyIncluded;
  final int? order;
  final int? plannedSeconds;
  final int? restSeconds;
  final String? plannedWeight;

  const ExerciseBlockModel({
    required this.exerciseId,
    required this.plannedSets,
    required this.plannedReps,
    required this.actualSets,
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

  factory ExerciseBlockModel.fromMap(Map<String, dynamic> data) =>
      ExerciseBlockModel(
        exerciseId: data['exerciseId'] as String,
        plannedSets: (data['plannedSets'] as num).toInt(),
        plannedReps: data['plannedReps'] as String,
        actualSets: (data['actualSets'] as List<dynamic>? ?? [])
            .map((s) => SetEntryModel.fromMap(s as Map<String, dynamic>))
            .toList(),
        rpe: data['rpe'] != null ? (data['rpe'] as num).toInt() : null,
        notes: data['notes'] as String?,
        phase: _phaseFromString(data['phase'] as String?),
        level: _levelFromString(data['level'] as String?),
        category: data['category'] as String?,
        directions: data['directions'] as String?,
        cuesOverride: (data['cuesOverride'] as List<dynamic>?)
            ?.map((c) => c as String)
            .toList(),
        currentlyIncluded: data['currentlyIncluded'] as bool?,
        order: data['order'] != null ? (data['order'] as num).toInt() : null,
        plannedSeconds: data['plannedSeconds'] != null
            ? (data['plannedSeconds'] as num).toInt()
            : null,
        restSeconds: data['restSeconds'] != null
            ? (data['restSeconds'] as num).toInt()
            : null,
        plannedWeight: data['plannedWeight'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'plannedSets': plannedSets,
        'plannedReps': plannedReps,
        'actualSets': actualSets.map((s) => s.toMap()).toList(),
        if (rpe != null) 'rpe': rpe,
        if (notes != null) 'notes': notes,
        if (phase != null) 'phase': phase!.name,
        if (level != null) 'level': level!.name,
        if (category != null) 'category': category,
        if (directions != null) 'directions': directions,
        if (cuesOverride != null) 'cuesOverride': cuesOverride,
        if (currentlyIncluded != null) 'currentlyIncluded': currentlyIncluded,
        if (order != null) 'order': order,
        if (plannedSeconds != null) 'plannedSeconds': plannedSeconds,
        if (restSeconds != null) 'restSeconds': restSeconds,
        if (plannedWeight != null) 'plannedWeight': plannedWeight,
      };

  ExerciseBlock toEntity() => ExerciseBlock(
        exerciseId: exerciseId,
        plannedSets: plannedSets,
        plannedReps: plannedReps,
        actualSets: actualSets.map((s) => s.toEntity()).toList(),
        rpe: rpe,
        notes: notes,
        phase: phase,
        level: level,
        category: category,
        directions: directions,
        cuesOverride: cuesOverride,
        currentlyIncluded: currentlyIncluded,
        order: order,
        plannedSeconds: plannedSeconds,
        restSeconds: restSeconds,
        plannedWeight: plannedWeight,
      );

  factory ExerciseBlockModel.fromEntity(ExerciseBlock b) => ExerciseBlockModel(
        exerciseId: b.exerciseId,
        plannedSets: b.plannedSets,
        plannedReps: b.plannedReps,
        actualSets: b.actualSets.map(SetEntryModel.fromEntity).toList(),
        rpe: b.rpe,
        notes: b.notes,
        phase: b.phase,
        level: b.level,
        category: b.category,
        directions: b.directions,
        cuesOverride: b.cuesOverride,
        currentlyIncluded: b.currentlyIncluded,
        order: b.order,
        plannedSeconds: b.plannedSeconds,
        restSeconds: b.restSeconds,
        plannedWeight: b.plannedWeight,
      );

  static ExercisePhase? _phaseFromString(String? s) {
    if (s == null) return null;
    return ExercisePhase.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ExercisePhase.main,
    );
  }

  static ExerciseLevel? _levelFromString(String? s) {
    if (s == null) return null;
    return ExerciseLevel.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ExerciseLevel.foundation,
    );
  }
}

class SensationFeedbackModel {
  final List<String> goodAreas;
  final List<String> strugglingAreas;
  final int? overallFeel;
  final String? notes;

  const SensationFeedbackModel({
    this.goodAreas = const [],
    this.strugglingAreas = const [],
    this.overallFeel,
    this.notes,
  });

  factory SensationFeedbackModel.fromMap(Map<String, dynamic> data) =>
      SensationFeedbackModel(
        goodAreas: (data['goodAreas'] as List<dynamic>? ?? [])
            .map((s) => s as String)
            .toList(),
        strugglingAreas: (data['strugglingAreas'] as List<dynamic>? ?? [])
            .map((s) => s as String)
            .toList(),
        overallFeel: data['overallFeel'] != null
            ? (data['overallFeel'] as num).toInt()
            : null,
        notes: data['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (goodAreas.isNotEmpty) 'goodAreas': goodAreas,
        if (strugglingAreas.isNotEmpty) 'strugglingAreas': strugglingAreas,
        if (overallFeel != null) 'overallFeel': overallFeel,
        if (notes != null) 'notes': notes,
      };

  SensationFeedback toEntity() => SensationFeedback(
        goodAreas: goodAreas,
        strugglingAreas: strugglingAreas,
        overallFeel: overallFeel,
        notes: notes,
      );

  factory SensationFeedbackModel.fromEntity(SensationFeedback s) =>
      SensationFeedbackModel(
        goodAreas: s.goodAreas,
        strugglingAreas: s.strugglingAreas,
        overallFeel: s.overallFeel,
        notes: s.notes,
      );
}

class SessionModel {
  final String id;
  final String userId;
  final String? programId;
  final String? focus;
  final DateTime date;
  final String status;
  final List<ExerciseBlockModel> exerciseBlocks;
  final String? notes;
  final int? durationMinutes;

  // Extended fields (training-week organizer)
  final String? workoutId;
  final WorkoutKind? kind;
  final SessionSlot? slot;
  final DurationCategory? durationCategory;
  final String? place;
  final SensationFeedbackModel? sensationFeedback;

  final String source;
  final String? idempotencyKey;

  const SessionModel({
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
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return SessionModel(
      id: doc.id,
      userId: data['userId'] as String,
      programId: data['programId'] as String?,
      focus: data['focus'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] as String? ?? 'planned',
      exerciseBlocks: (data['exerciseBlocks'] as List<dynamic>? ?? [])
          .map((b) => ExerciseBlockModel.fromMap(b as Map<String, dynamic>))
          .toList(),
      notes: data['notes'] as String?,
      durationMinutes: data['durationMinutes'] != null
          ? (data['durationMinutes'] as num).toInt()
          : null,
      workoutId: data['workoutId'] as String?,
      kind: _kindFromString(data['kind'] as String?),
      slot: _slotFromString(data['slot'] as String?),
      durationCategory:
          _durationCategoryFromString(data['durationCategory'] as String?),
      place: data['place'] as String?,
      sensationFeedback: data['sensationFeedback'] != null
          ? SensationFeedbackModel.fromMap(
              data['sensationFeedback'] as Map<String, dynamic>)
          : null,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        if (programId != null) 'programId': programId,
        if (focus != null) 'focus': focus,
        'date': Timestamp.fromDate(date),
        'status': status,
        'exerciseBlocks': exerciseBlocks.map((b) => b.toMap()).toList(),
        if (notes != null) 'notes': notes,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (workoutId != null) 'workoutId': workoutId,
        if (kind != null) 'kind': kind!.name,
        if (slot != null) 'slot': slot!.name,
        if (durationCategory != null)
          'durationCategory': durationCategory!.name,
        if (place != null) 'place': place,
        if (sensationFeedback != null)
          'sensationFeedback': sensationFeedback!.toMap(),
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Session toEntity() => Session(
        id: id,
        userId: userId,
        programId: programId,
        focus: focus,
        date: date,
        status: _statusFromString(status),
        exerciseBlocks: exerciseBlocks.map((b) => b.toEntity()).toList(),
        notes: notes,
        durationMinutes: durationMinutes,
        workoutId: workoutId,
        kind: kind,
        slot: slot,
        durationCategory: durationCategory,
        place: place,
        sensationFeedback: sensationFeedback?.toEntity(),
      );

  factory SessionModel.fromEntity(Session s) => SessionModel(
        id: s.id,
        userId: s.userId,
        programId: s.programId,
        focus: s.focus,
        date: s.date,
        status: _statusToString(s.status),
        exerciseBlocks:
            s.exerciseBlocks.map(ExerciseBlockModel.fromEntity).toList(),
        notes: s.notes,
        durationMinutes: s.durationMinutes,
        workoutId: s.workoutId,
        kind: s.kind,
        slot: s.slot,
        durationCategory: s.durationCategory,
        place: s.place,
        sensationFeedback: s.sensationFeedback != null
            ? SensationFeedbackModel.fromEntity(s.sensationFeedback!)
            : null,
      );

  static SessionStatus _statusFromString(String s) => switch (s) {
        'inProgress' => SessionStatus.inProgress,
        'completed' => SessionStatus.completed,
        'skipped' => SessionStatus.skipped,
        _ => SessionStatus.planned,
      };

  static String _statusToString(SessionStatus s) => switch (s) {
        SessionStatus.planned => 'planned',
        SessionStatus.inProgress => 'inProgress',
        SessionStatus.completed => 'completed',
        SessionStatus.skipped => 'skipped',
      };

  static WorkoutKind? _kindFromString(String? s) {
    if (s == null) return null;
    return WorkoutKind.values.firstWhere(
      (k) => k.name == s,
      orElse: () => WorkoutKind.custom,
    );
  }

  static SessionSlot? _slotFromString(String? s) {
    if (s == null) return null;
    return SessionSlot.values.firstWhere(
      (k) => k.name == s,
      orElse: () => SessionSlot.flexible,
    );
  }

  static DurationCategory? _durationCategoryFromString(String? s) {
    if (s == null) return null;
    return DurationCategory.values.firstWhere(
      (k) => k.name == s,
      orElse: () => DurationCategory.medium,
    );
  }
}
