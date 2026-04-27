import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../../sessions/data/models/session_model.dart'
    show ExerciseBlockModel;
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';

class WorkoutModel {
  final String id;
  final String userId;
  final String name;
  final String kind;
  final String? focus;
  final List<String> planeTags;
  final List<String> intentTags;
  final String? color;
  final String? iconEmoji;
  final int? estimatedMinutes;
  final List<ExerciseBlockModel> exerciseBlocks;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String source;
  final String? idempotencyKey;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    this.focus,
    this.planeTags = const [],
    this.intentTags = const [],
    this.color,
    this.iconEmoji,
    this.estimatedMinutes,
    this.exerciseBlocks = const [],
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return WorkoutModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      kind: data['kind'] as String? ?? 'custom',
      focus: data['focus'] as String?,
      planeTags: (data['planeTags'] as List<dynamic>? ?? [])
          .map((t) => t as String)
          .toList(),
      intentTags: (data['intentTags'] as List<dynamic>? ?? [])
          .map((t) => t as String)
          .toList(),
      color: data['color'] as String?,
      iconEmoji: data['iconEmoji'] as String?,
      estimatedMinutes: data['estimatedMinutes'] != null
          ? (data['estimatedMinutes'] as num).toInt()
          : null,
      exerciseBlocks: (data['exerciseBlocks'] as List<dynamic>? ?? [])
          .map((b) => ExerciseBlockModel.fromMap(b as Map<String, dynamic>))
          .toList(),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'kind': kind,
        if (focus != null) 'focus': focus,
        if (planeTags.isNotEmpty) 'planeTags': planeTags,
        if (intentTags.isNotEmpty) 'intentTags': intentTags,
        if (color != null) 'color': color,
        if (iconEmoji != null) 'iconEmoji': iconEmoji,
        if (estimatedMinutes != null) 'estimatedMinutes': estimatedMinutes,
        'exerciseBlocks': exerciseBlocks.map((b) => b.toMap()).toList(),
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Workout toEntity() => Workout(
        id: id,
        userId: userId,
        name: name,
        kind: _kindFromString(kind),
        focus: focus,
        planeTags: planeTags,
        intentTags: intentTags,
        color: color,
        iconEmoji: iconEmoji,
        estimatedMinutes: estimatedMinutes,
        exerciseBlocks: exerciseBlocks.map((b) => b.toEntity()).toList(),
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory WorkoutModel.fromEntity(Workout w) => WorkoutModel(
        id: w.id,
        userId: w.userId,
        name: w.name,
        kind: w.kind.name,
        focus: w.focus,
        planeTags: w.planeTags,
        intentTags: w.intentTags,
        color: w.color,
        iconEmoji: w.iconEmoji,
        estimatedMinutes: w.estimatedMinutes,
        exerciseBlocks:
            w.exerciseBlocks.map(ExerciseBlockModel.fromEntity).toList(),
        notes: w.notes,
        createdAt: w.createdAt,
        updatedAt: w.updatedAt,
      );

  static WorkoutKind _kindFromString(String s) => WorkoutKind.values.firstWhere(
        (k) => k.name == s,
        orElse: () => WorkoutKind.custom,
      );
}
