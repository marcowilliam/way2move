import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/recovery_score.dart';

class RecoveryScoreModel {
  final String id;
  final String userId;
  final DateTime date;
  final double score;
  final double sleepComponent;
  final double trainingLoadComponent;
  final double weeklyPulseComponent;
  final double gutFeelingComponent;
  final String recommendation;

  const RecoveryScoreModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.score,
    required this.sleepComponent,
    required this.trainingLoadComponent,
    required this.weeklyPulseComponent,
    required this.gutFeelingComponent,
    required this.recommendation,
  });

  factory RecoveryScoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final components = data['components'] as Map<String, dynamic>? ?? {};
    return RecoveryScoreModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      date: (data['date'] as Timestamp).toDate(),
      score: (data['score'] as num).toDouble(),
      sleepComponent: (components['sleep'] as num?)?.toDouble() ?? 50.0,
      trainingLoadComponent:
          (components['trainingLoad'] as num?)?.toDouble() ?? 50.0,
      weeklyPulseComponent:
          (components['weeklyPulse'] as num?)?.toDouble() ?? 50.0,
      gutFeelingComponent:
          (components['gutFeeling'] as num?)?.toDouble() ?? 50.0,
      recommendation: data['recommendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'score': score,
        'components': {
          'sleep': sleepComponent,
          'trainingLoad': trainingLoadComponent,
          'weeklyPulse': weeklyPulseComponent,
          'gutFeeling': gutFeelingComponent,
        },
        'recommendation': recommendation,
      };

  RecoveryScore toEntity() => RecoveryScore(
        id: id,
        userId: userId,
        date: date,
        score: score,
        components: RecoveryScoreComponents(
          sleepComponent: sleepComponent,
          trainingLoadComponent: trainingLoadComponent,
          weeklyPulseComponent: weeklyPulseComponent,
          gutFeelingComponent: gutFeelingComponent,
        ),
        recommendation: recommendation,
      );

  factory RecoveryScoreModel.fromEntity(RecoveryScore entity) =>
      RecoveryScoreModel(
        id: entity.id,
        userId: entity.userId,
        date: entity.date,
        score: entity.score,
        sleepComponent: entity.components.sleepComponent,
        trainingLoadComponent: entity.components.trainingLoadComponent,
        weeklyPulseComponent: entity.components.weeklyPulseComponent,
        gutFeelingComponent: entity.components.gutFeelingComponent,
        recommendation: entity.recommendation,
      );
}
