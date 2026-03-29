enum GoalCategory {
  mobility,
  stability,
  strength,
  endurance,
  posture,
  sport,
  recovery,
  general,
}

enum GoalSource {
  assessment,
  manual,
  suggested,
}

enum GoalStatus {
  active,
  achieved,
  paused,
}

class Goal {
  final String id;
  final String userId;
  final String name;
  final String description;
  final GoalCategory category;
  final String targetMetric;
  final double targetValue;
  final double currentValue;
  final String unit;
  final String? sport;
  final List<String> compensationIds;
  final List<String> exerciseIds;
  final GoalSource source;
  final GoalStatus status;
  final DateTime? achievedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    this.description = '',
    required this.category,
    required this.targetMetric,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    this.sport,
    this.compensationIds = const [],
    this.exerciseIds = const [],
    required this.source,
    this.status = GoalStatus.active,
    this.achievedAt,
  });

  double get progressFraction =>
      targetValue <= 0 ? 0 : (currentValue / targetValue).clamp(0.0, 1.0);

  bool get isAchieved => status == GoalStatus.achieved;

  Goal copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    GoalCategory? category,
    String? targetMetric,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? sport,
    List<String>? compensationIds,
    List<String>? exerciseIds,
    GoalSource? source,
    GoalStatus? status,
    DateTime? achievedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      targetMetric: targetMetric ?? this.targetMetric,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      sport: sport ?? this.sport,
      compensationIds: compensationIds ?? this.compensationIds,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      source: source ?? this.source,
      status: status ?? this.status,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Goal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
