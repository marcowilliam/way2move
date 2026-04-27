import '../../../workouts/domain/entities/workout_enums.dart';

/// One slot in a week's plan: "Tuesday morning, do workout X".
class PlannedSlot {
  /// 1 = Monday, 7 = Sunday (ISO weekday).
  final int day;
  final SessionSlot slot;

  /// The workout pinned to this slot. Null = the slot is reserved
  /// (e.g. "morning open for snacks") but unassigned.
  final String? workoutId;

  /// Override of the workout's `estimatedMinutes` for this slot.
  /// Null = use the workout's default.
  final int? plannedDuration;

  /// True if this slot was placed by the auto-fill (Mon-Fri ABCDE) vs
  /// hand-placed by the user. Used by the planner to render "auto" vs
  /// "you set this" affordances differently.
  final bool autoAssigned;

  const PlannedSlot({
    required this.day,
    required this.slot,
    this.workoutId,
    this.plannedDuration,
    this.autoAssigned = false,
  });

  PlannedSlot copyWith({
    int? day,
    SessionSlot? slot,
    String? workoutId,
    int? plannedDuration,
    bool? autoAssigned,
  }) =>
      PlannedSlot(
        day: day ?? this.day,
        slot: slot ?? this.slot,
        workoutId: workoutId ?? this.workoutId,
        plannedDuration: plannedDuration ?? this.plannedDuration,
        autoAssigned: autoAssigned ?? this.autoAssigned,
      );

  @override
  bool operator ==(Object other) =>
      other is PlannedSlot && other.day == day && other.slot == slot;

  @override
  int get hashCode => Object.hash(day, slot);
}

/// One ISO week's plan for a user. Drives the Today screen ("what's
/// scheduled now?") and the Weekly Review screen ("what did I actually
/// do?"). Distinct from `programs` (multi-week macro plan) — a week plan
/// is a single-week themed schedule that swaps each Monday.
class WeekPlan {
  final String id;
  final String userId;

  /// ISO year-week string, e.g. `2026-W18`. The week the plan covers.
  final String isoYearWeek;

  /// Inclusive — Monday of the week.
  final DateTime startDate;

  /// Exclusive — next Monday.
  final DateTime endDate;

  /// "This week's intent" — free text. e.g. "Alignment + body awareness".
  final String? intent;

  /// Body areas the user is consciously paying attention to this week —
  /// "eyes", "neck", "si_joint", "hamstring". Used by the planner's
  /// focus-area chips and by the Weekly Review heatmap.
  final List<String> focusAreas;

  final List<PlannedSlot> plannedSlots;

  /// Filled at week-end during review.
  final String? reviewNotes;
  final DateTime? reviewedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WeekPlan({
    required this.id,
    required this.userId,
    required this.isoYearWeek,
    required this.startDate,
    required this.endDate,
    this.intent,
    this.focusAreas = const [],
    this.plannedSlots = const [],
    this.reviewNotes,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// True once the user has filled review notes — the planner uses this
  /// to gate "Plan next week" CTA.
  bool get isReviewed => reviewedAt != null;

  /// All slots scheduled for a given ISO weekday (1=Mon … 7=Sun).
  List<PlannedSlot> slotsForDay(int day) =>
      plannedSlots.where((s) => s.day == day).toList()
        ..sort((a, b) => a.slot.index.compareTo(b.slot.index));

  WeekPlan copyWith({
    String? id,
    String? userId,
    String? isoYearWeek,
    DateTime? startDate,
    DateTime? endDate,
    String? intent,
    List<String>? focusAreas,
    List<PlannedSlot>? plannedSlots,
    String? reviewNotes,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      WeekPlan(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        isoYearWeek: isoYearWeek ?? this.isoYearWeek,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        intent: intent ?? this.intent,
        focusAreas: focusAreas ?? this.focusAreas,
        plannedSlots: plannedSlots ?? this.plannedSlots,
        reviewNotes: reviewNotes ?? this.reviewNotes,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) => other is WeekPlan && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
