class ProgressionRule {
  final String exerciseId; // empty = global rule
  final int completionThreshold;
  final double sleepThreshold;
  final double pulseThreshold;
  final double stomachThreshold;

  const ProgressionRule({
    this.exerciseId = '',
    this.completionThreshold = 3,
    this.sleepThreshold = 3.5,
    this.pulseThreshold = 3.0,
    this.stomachThreshold = 3.0,
  });

  bool get isGlobal => exerciseId.isEmpty;

  ProgressionRule copyWith({
    String? exerciseId,
    int? completionThreshold,
    double? sleepThreshold,
    double? pulseThreshold,
    double? stomachThreshold,
  }) {
    return ProgressionRule(
      exerciseId: exerciseId ?? this.exerciseId,
      completionThreshold: completionThreshold ?? this.completionThreshold,
      sleepThreshold: sleepThreshold ?? this.sleepThreshold,
      pulseThreshold: pulseThreshold ?? this.pulseThreshold,
      stomachThreshold: stomachThreshold ?? this.stomachThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressionRule &&
      other.exerciseId == exerciseId &&
      other.completionThreshold == completionThreshold &&
      other.sleepThreshold == sleepThreshold &&
      other.pulseThreshold == pulseThreshold &&
      other.stomachThreshold == stomachThreshold;

  @override
  int get hashCode => Object.hash(
        exerciseId,
        completionThreshold,
        sleepThreshold,
        pulseThreshold,
        stomachThreshold,
      );
}
