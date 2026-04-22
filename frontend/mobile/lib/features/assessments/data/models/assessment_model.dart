import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/assessment.dart';

class AssessmentModel {
  final String id;
  final String userId;
  final DateTime date;
  final Map<String, dynamic> answers;
  final List<String> compensationResults;
  final List<Map<String, dynamic>> movementScores;
  final double overallScore;
  final String source;
  final String? idempotencyKey;

  const AssessmentModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.answers,
    required this.compensationResults,
    required this.movementScores,
    required this.overallScore,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory AssessmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return AssessmentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      answers: Map<String, dynamic>.from(data['answers'] as Map? ?? {}),
      compensationResults:
          List<String>.from(data['compensationResults'] as List? ?? []),
      movementScores: List<Map<String, dynamic>>.from(
          (data['movementScores'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))),
      overallScore: (data['overallScore'] as num?)?.toDouble() ?? 0.0,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'answers': answers,
        'compensationResults': compensationResults,
        'movementScores': movementScores,
        'overallScore': overallScore,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Assessment toEntity() => Assessment(
        id: id,
        userId: userId,
        date: date,
        answers: answers,
        compensationResults: compensationResults
            .map((s) =>
                CompensationPattern.values.firstWhere((e) => e.name == s))
            .toList(),
        movementScores: movementScores
            .map((m) => MovementScore(
                  movementName: m['movementName'] as String,
                  score: (m['score'] as num).toInt(),
                  notes: m['notes'] as String?,
                ))
            .toList(),
        overallScore: overallScore,
      );

  factory AssessmentModel.fromEntity(Assessment entity) => AssessmentModel(
        id: entity.id,
        userId: entity.userId,
        date: entity.date,
        answers: entity.answers,
        compensationResults:
            entity.compensationResults.map((p) => p.name).toList(),
        movementScores: entity.movementScores
            .map((s) => {
                  'movementName': s.movementName,
                  'score': s.score,
                  if (s.notes != null) 'notes': s.notes,
                })
            .toList(),
        overallScore: entity.overallScore,
      );
}

class WeeklyPulseModel {
  final String id;
  final String userId;
  final DateTime date;
  final int energyScore;
  final int sorenessScore;
  final int motivationScore;
  final int sleepQualityScore;
  final String? notes;
  final String source;
  final String? idempotencyKey;

  const WeeklyPulseModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.energyScore,
    required this.sorenessScore,
    required this.motivationScore,
    required this.sleepQualityScore,
    this.notes,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory WeeklyPulseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return WeeklyPulseModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      energyScore: (data['energyScore'] as num?)?.toInt() ?? 3,
      sorenessScore: (data['sorenessScore'] as num?)?.toInt() ?? 3,
      motivationScore: (data['motivationScore'] as num?)?.toInt() ?? 3,
      sleepQualityScore: (data['sleepQualityScore'] as num?)?.toInt() ?? 3,
      notes: data['notes'] as String?,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'energyScore': energyScore,
        'sorenessScore': sorenessScore,
        'motivationScore': motivationScore,
        'sleepQualityScore': sleepQualityScore,
        if (notes != null) 'notes': notes,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  WeeklyPulse toEntity() => WeeklyPulse(
        id: id,
        userId: userId,
        date: date,
        energyScore: energyScore,
        sorenessScore: sorenessScore,
        motivationScore: motivationScore,
        sleepQualityScore: sleepQualityScore,
        notes: notes,
      );

  factory WeeklyPulseModel.fromEntity(WeeklyPulse entity) => WeeklyPulseModel(
        id: entity.id,
        userId: entity.userId,
        date: entity.date,
        energyScore: entity.energyScore,
        sorenessScore: entity.sorenessScore,
        motivationScore: entity.motivationScore,
        sleepQualityScore: entity.sleepQualityScore,
        notes: entity.notes,
      );
}
