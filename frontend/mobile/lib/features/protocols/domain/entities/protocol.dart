import '../../../workouts/domain/entities/workout_enums.dart';

/// A time-bounded prescription. The shape of "do all these workouts every
/// day for 6 weeks" — distinct from `programs` (open-ended weekly macro
/// plan) and from `weekPlans` (themed single-week schedule).
///
/// Today screen renders the Protocol's pinned workouts at the top of the
/// day with `X of Y exercises done` progress. On `endDate`, the data
/// layer flips status to `completed` so it stops pinning.
class Protocol {
  final String id;
  final String userId;

  final String name;
  final ProtocolKind kind;

  /// Inclusive — first day the protocol applies.
  final DateTime startDate;

  /// Exclusive — last day after which the protocol is complete.
  /// Always `startDate + durationWeeks * 7 days` at write time, but stored
  /// explicitly so renames/extensions don't break old reads.
  final DateTime endDate;

  final int durationWeeks;

  /// The user-facing prescription text — "all exercises every day, 1 set
  /// each". Free-form because every physio writes these differently.
  final String prescription;

  /// Workouts pinned every day during the protocol window. Today screen
  /// renders one card per id. Usually a single workout for a "from the
  /// ground up" prescription, but could be multiple for a complex program.
  final List<String> workoutIds;

  final ProtocolStatus status;

  /// Long-form notes (the chat / pasted-text body of the prescription).
  final String? notes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Protocol({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    required this.startDate,
    required this.endDate,
    required this.durationWeeks,
    required this.prescription,
    required this.workoutIds,
    this.status = ProtocolStatus.active,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// True if `now` falls inside the active window AND status is `active`.
  /// Use this — not just `status == active` — when deciding whether to
  /// pin protocol cards on Today, so an unswept-completed protocol stops
  /// rendering even if the daily auto-flip hasn't run yet.
  bool isActiveOn(DateTime now) {
    if (status != ProtocolStatus.active) return false;
    return !now.isBefore(startDate) && now.isBefore(endDate);
  }

  /// Day index within the protocol (1-based). Day 1 = startDate.
  /// Returns null if `now` is outside the window.
  int? dayIndexFor(DateTime now) {
    if (now.isBefore(startDate) || !now.isBefore(endDate)) return null;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  Protocol copyWith({
    String? id,
    String? userId,
    String? name,
    ProtocolKind? kind,
    DateTime? startDate,
    DateTime? endDate,
    int? durationWeeks,
    String? prescription,
    List<String>? workoutIds,
    ProtocolStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Protocol(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        durationWeeks: durationWeeks ?? this.durationWeeks,
        prescription: prescription ?? this.prescription,
        workoutIds: workoutIds ?? this.workoutIds,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) => other is Protocol && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
