/// Supported re-assessment interval options in weeks.
const List<int> kAssessmentIntervalOptions = [4, 6, 8, 12];

class ReAssessmentSchedule {
  final String id;
  final String userId;
  final DateTime nextAssessmentDate;
  final int intervalWeeks; // one of: 4, 6, 8, 12
  final DateTime? lastCompletedDate;

  const ReAssessmentSchedule({
    required this.id,
    required this.userId,
    required this.nextAssessmentDate,
    this.intervalWeeks = 4,
    this.lastCompletedDate,
  });

  ReAssessmentSchedule copyWith({
    String? id,
    String? userId,
    DateTime? nextAssessmentDate,
    int? intervalWeeks,
    DateTime? lastCompletedDate,
  }) {
    return ReAssessmentSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nextAssessmentDate: nextAssessmentDate ?? this.nextAssessmentDate,
      intervalWeeks: intervalWeeks ?? this.intervalWeeks,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReAssessmentSchedule && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
