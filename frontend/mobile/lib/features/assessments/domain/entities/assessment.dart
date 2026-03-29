enum CompensationPattern {
  forwardHeadPosture,
  roundedShoulders,
  anteriorPelvicTilt,
  posteriorPelvicTilt,
  excessiveLumbarLordosis,
  thoracicKyphosis,
  kneeValgus,
  overPronation,
  limitedDorsiflexion,
  limitedHipInternalRotation,
  limitedHipExternalRotation,
  limitedThoracicRotation,
  weakGluteMed,
  poorCoreStability,
}

class MovementScore {
  final String movementName;
  final int score; // 0-10
  final String? notes;

  const MovementScore({
    required this.movementName,
    required this.score,
    this.notes,
  });
}

class Assessment {
  final String id;
  final String userId;
  final DateTime date;
  final Map<String, dynamic> answers;
  final List<CompensationPattern> compensationResults;
  final List<MovementScore> movementScores;
  final double overallScore; // 0-10

  const Assessment({
    required this.id,
    required this.userId,
    required this.date,
    required this.answers,
    required this.compensationResults,
    required this.movementScores,
    required this.overallScore,
  });

  Assessment copyWith({
    String? id,
    String? userId,
    DateTime? date,
    Map<String, dynamic>? answers,
    List<CompensationPattern>? compensationResults,
    List<MovementScore>? movementScores,
    double? overallScore,
  }) {
    return Assessment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      answers: answers ?? this.answers,
      compensationResults: compensationResults ?? this.compensationResults,
      movementScores: movementScores ?? this.movementScores,
      overallScore: overallScore ?? this.overallScore,
    );
  }

  @override
  bool operator ==(Object other) => other is Assessment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class WeeklyPulse {
  final String id;
  final String userId;
  final DateTime date;
  final int energyScore; // 1-5
  final int sorenessScore; // 1-5 (1=very sore, 5=no soreness)
  final int motivationScore; // 1-5
  final int sleepQualityScore; // 1-5
  final String? notes;

  const WeeklyPulse({
    required this.id,
    required this.userId,
    required this.date,
    required this.energyScore,
    required this.sorenessScore,
    required this.motivationScore,
    required this.sleepQualityScore,
    this.notes,
  });

  double get compositeScore =>
      (energyScore + sorenessScore + motivationScore + sleepQualityScore) / 4.0;
}
