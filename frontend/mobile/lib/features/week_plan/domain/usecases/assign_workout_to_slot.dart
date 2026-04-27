import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../entities/week_plan.dart';
import '../repositories/week_plan_repository.dart';

/// Assigns a workout to a specific (day, slot) within a WeekPlan.
///
/// - If a slot already exists at (day, slot), it's replaced (workoutId
///   updated, autoAssigned cleared since this is a manual placement).
/// - If no slot exists, a new one is appended.
/// - If `workoutId` is null, the slot is removed entirely.
class AssignWorkoutToSlot {
  final WeekPlanRepository _repo;
  const AssignWorkoutToSlot(this._repo);

  Future<Either<AppFailure, WeekPlan>> call({
    required WeekPlan plan,
    required int day,
    required SessionSlot slot,
    required String? workoutId,
    int? plannedDuration,
  }) {
    final filtered = plan.plannedSlots
        .where((s) => !(s.day == day && s.slot == slot))
        .toList();

    final updatedSlots = workoutId == null
        ? filtered
        : [
            ...filtered,
            PlannedSlot(
              day: day,
              slot: slot,
              workoutId: workoutId,
              plannedDuration: plannedDuration,
              autoAssigned: false,
            ),
          ];

    final updated = plan.copyWith(plannedSlots: updatedSlots);
    return _repo.updateWeekPlan(updated);
  }
}
