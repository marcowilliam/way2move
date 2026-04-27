import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../../domain/entities/week_plan.dart';

class PlannedSlotModel {
  final int day;
  final String slot;
  final String? workoutId;
  final int? plannedDuration;
  final bool autoAssigned;

  const PlannedSlotModel({
    required this.day,
    required this.slot,
    this.workoutId,
    this.plannedDuration,
    this.autoAssigned = false,
  });

  factory PlannedSlotModel.fromMap(Map<String, dynamic> data) =>
      PlannedSlotModel(
        day: (data['day'] as num).toInt(),
        slot: data['slot'] as String? ?? 'flexible',
        workoutId: data['workoutId'] as String?,
        plannedDuration: data['plannedDuration'] != null
            ? (data['plannedDuration'] as num).toInt()
            : null,
        autoAssigned: data['autoAssigned'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'slot': slot,
        if (workoutId != null) 'workoutId': workoutId,
        if (plannedDuration != null) 'plannedDuration': plannedDuration,
        'autoAssigned': autoAssigned,
      };

  PlannedSlot toEntity() => PlannedSlot(
        day: day,
        slot: _slotFromString(slot),
        workoutId: workoutId,
        plannedDuration: plannedDuration,
        autoAssigned: autoAssigned,
      );

  factory PlannedSlotModel.fromEntity(PlannedSlot s) => PlannedSlotModel(
        day: s.day,
        slot: s.slot.name,
        workoutId: s.workoutId,
        plannedDuration: s.plannedDuration,
        autoAssigned: s.autoAssigned,
      );

  static SessionSlot _slotFromString(String s) => SessionSlot.values.firstWhere(
        (k) => k.name == s,
        orElse: () => SessionSlot.flexible,
      );
}

class WeekPlanModel {
  final String id;
  final String userId;
  final String isoYearWeek;
  final DateTime startDate;
  final DateTime endDate;
  final String? intent;
  final List<String> focusAreas;
  final List<PlannedSlotModel> plannedSlots;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String source;
  final String? idempotencyKey;

  const WeekPlanModel({
    required this.id,
    required this.userId,
    required this.isoYearWeek,
    required this.startDate,
    required this.endDate,
    this.intent,
    this.focusAreas = const [],
    this.plannedSlots = const [],
    this.reviewNotes,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory WeekPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return WeekPlanModel(
      id: doc.id,
      userId: data['userId'] as String,
      isoYearWeek: data['isoYearWeek'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      intent: data['intent'] as String?,
      focusAreas: (data['focusAreas'] as List<dynamic>? ?? [])
          .map((f) => f as String)
          .toList(),
      plannedSlots: (data['plannedSlots'] as List<dynamic>? ?? [])
          .map((s) => PlannedSlotModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      reviewNotes: data['reviewNotes'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'isoYearWeek': isoYearWeek,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        if (intent != null) 'intent': intent,
        if (focusAreas.isNotEmpty) 'focusAreas': focusAreas,
        'plannedSlots': plannedSlots.map((s) => s.toMap()).toList(),
        if (reviewNotes != null) 'reviewNotes': reviewNotes,
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  WeekPlan toEntity() => WeekPlan(
        id: id,
        userId: userId,
        isoYearWeek: isoYearWeek,
        startDate: startDate,
        endDate: endDate,
        intent: intent,
        focusAreas: focusAreas,
        plannedSlots: plannedSlots.map((s) => s.toEntity()).toList(),
        reviewNotes: reviewNotes,
        reviewedAt: reviewedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory WeekPlanModel.fromEntity(WeekPlan p) => WeekPlanModel(
        id: p.id,
        userId: p.userId,
        isoYearWeek: p.isoYearWeek,
        startDate: p.startDate,
        endDate: p.endDate,
        intent: p.intent,
        focusAreas: p.focusAreas,
        plannedSlots: p.plannedSlots.map(PlannedSlotModel.fromEntity).toList(),
        reviewNotes: p.reviewNotes,
        reviewedAt: p.reviewedAt,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      );
}
