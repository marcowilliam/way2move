enum CompensationType {
  mobilityDeficit,
  stabilityDeficit,
  motorControl,
  strengthImbalance,
  posturalPattern,
}

enum CompensationRegion {
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  leftShoulder,
  rightShoulder,
  thoracicSpine,
  lumbarSpine,
  cervicalSpine,
  core,
  leftFoot,
  rightFoot,
  pelvis,
}

enum CompensationSeverity { mild, moderate, severe }

enum CompensationStatus { active, improving, resolved }

enum CompensationSource { assessment, journal, manual }

class CompensationHistoryEntry {
  final DateTime date;
  final CompensationSeverity severity;
  final CompensationStatus status;
  final String note;

  const CompensationHistoryEntry({
    required this.date,
    required this.severity,
    required this.status,
    required this.note,
  });

  @override
  bool operator ==(Object other) =>
      other is CompensationHistoryEntry &&
      other.date == date &&
      other.severity == severity &&
      other.status == status &&
      other.note == note;

  @override
  int get hashCode => Object.hash(date, severity, status, note);
}

class Compensation {
  final String id;
  final String userId;
  final String name;
  final CompensationType type;
  final CompensationRegion region;
  final CompensationSeverity severity;
  final CompensationStatus status;
  final CompensationSource source;
  final List<String> relatedGoalIds;
  final List<String> relatedExerciseIds;
  final List<CompensationHistoryEntry> history;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  const Compensation({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.region,
    required this.severity,
    required this.status,
    required this.source,
    this.relatedGoalIds = const [],
    this.relatedExerciseIds = const [],
    this.history = const [],
    required this.detectedAt,
    this.resolvedAt,
  });

  Compensation copyWith({
    String? id,
    String? userId,
    String? name,
    CompensationType? type,
    CompensationRegion? region,
    CompensationSeverity? severity,
    CompensationStatus? status,
    CompensationSource? source,
    List<String>? relatedGoalIds,
    List<String>? relatedExerciseIds,
    List<CompensationHistoryEntry>? history,
    DateTime? detectedAt,
    DateTime? resolvedAt,
  }) {
    return Compensation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      region: region ?? this.region,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      source: source ?? this.source,
      relatedGoalIds: relatedGoalIds ?? this.relatedGoalIds,
      relatedExerciseIds: relatedExerciseIds ?? this.relatedExerciseIds,
      history: history ?? this.history,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Compensation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
