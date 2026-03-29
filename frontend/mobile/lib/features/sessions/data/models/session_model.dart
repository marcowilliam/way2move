import 'package:cloud_firestore/cloud_firestore.dart';
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

  const ExerciseBlockModel({
    required this.exerciseId,
    required this.plannedSets,
    required this.plannedReps,
    required this.actualSets,
    this.rpe,
    this.notes,
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
      );

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'plannedSets': plannedSets,
        'plannedReps': plannedReps,
        'actualSets': actualSets.map((s) => s.toMap()).toList(),
        if (rpe != null) 'rpe': rpe,
        if (notes != null) 'notes': notes,
      };

  ExerciseBlock toEntity() => ExerciseBlock(
        exerciseId: exerciseId,
        plannedSets: plannedSets,
        plannedReps: plannedReps,
        actualSets: actualSets.map((s) => s.toEntity()).toList(),
        rpe: rpe,
        notes: notes,
      );

  factory ExerciseBlockModel.fromEntity(ExerciseBlock b) => ExerciseBlockModel(
        exerciseId: b.exerciseId,
        plannedSets: b.plannedSets,
        plannedReps: b.plannedReps,
        actualSets: b.actualSets.map(SetEntryModel.fromEntity).toList(),
        rpe: b.rpe,
        notes: b.notes,
      );
}

class SessionModel {
  final String id;
  final String userId;
  final String? programId;
  final String? focus;
  final DateTime date;
  final String status; // stored as string
  final List<ExerciseBlockModel> exerciseBlocks;
  final String? notes;
  final int? durationMinutes;

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
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
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
}
