import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/program.dart';

class ProgramModel {
  final String id;
  final String userId;
  final String name;
  final String goal;
  final int durationWeeks;
  final Map<String, dynamic> weekTemplate;
  final bool isActive;
  final DateTime createdAt;
  final String? basedOnAssessmentId;
  final String source;
  final String? idempotencyKey;

  const ProgramModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.goal,
    required this.durationWeeks,
    required this.weekTemplate,
    required this.isActive,
    required this.createdAt,
    this.basedOnAssessmentId,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory ProgramModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return ProgramModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      goal: data['goal'] as String? ?? '',
      durationWeeks: (data['durationWeeks'] as num?)?.toInt() ?? 8,
      weekTemplate:
          Map<String, dynamic>.from(data['weekTemplate'] as Map? ?? {}),
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      basedOnAssessmentId: data['basedOnAssessmentId'] as String?,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'goal': goal,
        'durationWeeks': durationWeeks,
        'weekTemplate': weekTemplate,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        if (basedOnAssessmentId != null)
          'basedOnAssessmentId': basedOnAssessmentId,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Program toEntity() => Program(
        id: id,
        userId: userId,
        name: name,
        goal: goal,
        durationWeeks: durationWeeks,
        weekTemplate: _deserializeWeekTemplate(weekTemplate),
        isActive: isActive,
        createdAt: createdAt,
        basedOnAssessmentId: basedOnAssessmentId,
      );

  factory ProgramModel.fromEntity(Program entity) => ProgramModel(
        id: entity.id,
        userId: entity.userId,
        name: entity.name,
        goal: entity.goal,
        durationWeeks: entity.durationWeeks,
        weekTemplate: _serializeWeekTemplate(entity.weekTemplate),
        isActive: entity.isActive,
        createdAt: entity.createdAt,
        basedOnAssessmentId: entity.basedOnAssessmentId,
      );

  // ── Serialization helpers ──────────────────────────────────────────────────

  static Map<String, dynamic> _serializeWeekTemplate(WeekTemplate template) {
    return {
      for (final entry in template.days.entries)
        entry.key.toString(): _serializeDayTemplate(entry.value),
    };
  }

  static Map<String, dynamic> _serializeDayTemplate(DayTemplate day) => {
        'isRestDay': day.isRestDay,
        if (day.focus != null) 'focus': day.focus,
        'exerciseEntries': day.exerciseEntries
            .map((e) => {
                  'exerciseId': e.exerciseId,
                  'sets': e.sets,
                  'reps': e.reps,
                  if (e.notes != null) 'notes': e.notes,
                })
            .toList(),
      };

  static WeekTemplate _deserializeWeekTemplate(Map<String, dynamic> raw) {
    final days = <int, DayTemplate>{};
    for (final entry in raw.entries) {
      final dayIndex = int.tryParse(entry.key);
      if (dayIndex == null) continue;
      final dayData = Map<String, dynamic>.from(entry.value as Map);
      days[dayIndex] = _deserializeDayTemplate(dayData);
    }
    // Ensure all 7 days exist
    for (int i = 0; i < 7; i++) {
      days.putIfAbsent(i, () => DayTemplate.rest);
    }
    return WeekTemplate(days: days);
  }

  static DayTemplate _deserializeDayTemplate(Map<String, dynamic> data) {
    final entries = (data['exerciseEntries'] as List? ?? []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return ExerciseEntry(
        exerciseId: m['exerciseId'] as String,
        sets: (m['sets'] as num).toInt(),
        reps: m['reps'] as String,
        notes: m['notes'] as String?,
      );
    }).toList();

    return DayTemplate(
      focus: data['focus'] as String?,
      exerciseEntries: entries,
      isRestDay: data['isRestDay'] as bool? ?? true,
    );
  }
}
