import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/re_assessment_schedule.dart';

class ReAssessmentScheduleModel {
  final String id;
  final String userId;
  final DateTime nextAssessmentDate;
  final int intervalWeeks;
  final DateTime? lastCompletedDate;
  final String source;
  final String? idempotencyKey;

  const ReAssessmentScheduleModel({
    required this.id,
    required this.userId,
    required this.nextAssessmentDate,
    required this.intervalWeeks,
    this.lastCompletedDate,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory ReAssessmentScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return ReAssessmentScheduleModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      nextAssessmentDate: (data['nextAssessmentDate'] as Timestamp).toDate(),
      intervalWeeks: (data['intervalWeeks'] as num?)?.toInt() ?? 4,
      lastCompletedDate: data['lastCompletedDate'] != null
          ? (data['lastCompletedDate'] as Timestamp).toDate()
          : null,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'nextAssessmentDate': Timestamp.fromDate(nextAssessmentDate),
        'intervalWeeks': intervalWeeks,
        if (lastCompletedDate != null)
          'lastCompletedDate': Timestamp.fromDate(lastCompletedDate!),
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  ReAssessmentSchedule toEntity() => ReAssessmentSchedule(
        id: id,
        userId: userId,
        nextAssessmentDate: nextAssessmentDate,
        intervalWeeks: intervalWeeks,
        lastCompletedDate: lastCompletedDate,
      );

  factory ReAssessmentScheduleModel.fromEntity(ReAssessmentSchedule entity) =>
      ReAssessmentScheduleModel(
        id: entity.id,
        userId: entity.userId,
        nextAssessmentDate: entity.nextAssessmentDate,
        intervalWeeks: entity.intervalWeeks,
        lastCompletedDate: entity.lastCompletedDate,
      );
}
