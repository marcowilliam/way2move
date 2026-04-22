import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/progression_rule.dart';

class ProgressionRuleModel {
  final String exerciseId;
  final int completionThreshold;
  final double sleepThreshold;
  final double pulseThreshold;
  final double stomachThreshold;
  final String source;
  final String? idempotencyKey;

  const ProgressionRuleModel({
    required this.exerciseId,
    required this.completionThreshold,
    required this.sleepThreshold,
    required this.pulseThreshold,
    required this.stomachThreshold,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory ProgressionRuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return ProgressionRuleModel(
      exerciseId: data['exerciseId'] as String? ?? '',
      completionThreshold: (data['completionThreshold'] as num?)?.toInt() ?? 3,
      sleepThreshold: (data['sleepThreshold'] as num?)?.toDouble() ?? 3.5,
      pulseThreshold: (data['pulseThreshold'] as num?)?.toDouble() ?? 3.0,
      stomachThreshold: (data['stomachThreshold'] as num?)?.toDouble() ?? 3.0,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  factory ProgressionRuleModel.fromEntity(ProgressionRule rule) {
    return ProgressionRuleModel(
      exerciseId: rule.exerciseId,
      completionThreshold: rule.completionThreshold,
      sleepThreshold: rule.sleepThreshold,
      pulseThreshold: rule.pulseThreshold,
      stomachThreshold: rule.stomachThreshold,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'exerciseId': exerciseId,
      'completionThreshold': completionThreshold,
      'sleepThreshold': sleepThreshold,
      'pulseThreshold': pulseThreshold,
      'stomachThreshold': stomachThreshold,
      ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
    };
  }

  ProgressionRule toEntity() {
    return ProgressionRule(
      exerciseId: exerciseId,
      completionThreshold: completionThreshold,
      sleepThreshold: sleepThreshold,
      pulseThreshold: pulseThreshold,
      stomachThreshold: stomachThreshold,
    );
  }
}
