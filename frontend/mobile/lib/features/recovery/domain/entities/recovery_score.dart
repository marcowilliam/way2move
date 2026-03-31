enum RecoveryZone { green, yellow, red }

class RecoveryScoreComponents {
  final double sleepComponent; // 0–100
  final double trainingLoadComponent; // 0–100
  final double weeklyPulseComponent; // 0–100
  final double gutFeelingComponent; // 0–100

  const RecoveryScoreComponents({
    required this.sleepComponent,
    required this.trainingLoadComponent,
    required this.weeklyPulseComponent,
    required this.gutFeelingComponent,
  });

  RecoveryScoreComponents copyWith({
    double? sleepComponent,
    double? trainingLoadComponent,
    double? weeklyPulseComponent,
    double? gutFeelingComponent,
  }) =>
      RecoveryScoreComponents(
        sleepComponent: sleepComponent ?? this.sleepComponent,
        trainingLoadComponent:
            trainingLoadComponent ?? this.trainingLoadComponent,
        weeklyPulseComponent: weeklyPulseComponent ?? this.weeklyPulseComponent,
        gutFeelingComponent: gutFeelingComponent ?? this.gutFeelingComponent,
      );

  @override
  bool operator ==(Object other) =>
      other is RecoveryScoreComponents &&
      other.sleepComponent == sleepComponent &&
      other.trainingLoadComponent == trainingLoadComponent &&
      other.weeklyPulseComponent == weeklyPulseComponent &&
      other.gutFeelingComponent == gutFeelingComponent;

  @override
  int get hashCode => Object.hash(sleepComponent, trainingLoadComponent,
      weeklyPulseComponent, gutFeelingComponent);
}

class RecoveryScore {
  final String id;
  final String userId;
  final DateTime date;
  final double score; // 0–100
  final RecoveryScoreComponents components;
  final String recommendation;

  const RecoveryScore({
    required this.id,
    required this.userId,
    required this.date,
    required this.score,
    required this.components,
    required this.recommendation,
  });

  RecoveryZone get zone {
    if (score >= 75) return RecoveryZone.green;
    if (score >= 50) return RecoveryZone.yellow;
    return RecoveryZone.red;
  }

  RecoveryScore copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? score,
    RecoveryScoreComponents? components,
    String? recommendation,
  }) =>
      RecoveryScore(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        score: score ?? this.score,
        components: components ?? this.components,
        recommendation: recommendation ?? this.recommendation,
      );

  @override
  bool operator ==(Object other) => other is RecoveryScore && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
