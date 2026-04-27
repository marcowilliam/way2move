import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../../../workouts/domain/repositories/workout_repository.dart';
import '../entities/week_plan.dart';
import '../repositories/week_plan_repository.dart';
import 'iso_week.dart';

/// Returns the user's plan for the ISO week containing `now`, creating it
/// (with auto Mon-Fri ABCDE pre-fill) if it doesn't exist yet.
///
/// Auto-fill rule: each ABCDE workout the user owns gets pinned to a
/// weekday in workout-list order — the *first* abcde workout to day 1
/// (Mon), the second to day 2 (Tue), etc. Up to 5 days. Sat/Sun stay
/// open. Slot defaults to `afternoon` (the typical gym time) — user can
/// drag to morning/evening in the planner.
class GetOrCreateCurrentWeekPlan {
  final WeekPlanRepository _weekPlanRepo;
  final WorkoutRepository _workoutRepo;

  const GetOrCreateCurrentWeekPlan({
    required WeekPlanRepository weekPlanRepo,
    required WorkoutRepository workoutRepo,
  })  : _weekPlanRepo = weekPlanRepo,
        _workoutRepo = workoutRepo;

  Future<Either<AppFailure, WeekPlan>> call({
    required String userId,
    required DateTime now,
  }) async {
    final isoWeek = isoYearWeekOf(now);
    final monday = mondayOf(now);
    final nextMonday = nextMondayOf(now);

    final existingResult = await _weekPlanRepo.getWeekPlan(userId, isoWeek);
    final readFailure = existingResult.swap().toNullable();
    if (readFailure != null) return Left(readFailure);

    final existing = existingResult.toNullable();
    if (existing != null) return Right(existing);

    final abcdeResult =
        await _workoutRepo.getWorkouts(userId, kind: WorkoutKind.abcde);
    final fetchFailure = abcdeResult.swap().toNullable();
    if (fetchFailure != null) return Left(fetchFailure);

    final abcdeWorkouts = abcdeResult.toNullable() ?? const <Workout>[];
    final slots = _buildAutoSlots(abcdeWorkouts);
    final plan = WeekPlan(
      id: '',
      userId: userId,
      isoYearWeek: isoWeek,
      startDate: monday,
      endDate: nextMonday,
      plannedSlots: slots,
    );
    return _weekPlanRepo.createWeekPlan(plan);
  }

  static List<PlannedSlot> _buildAutoSlots(List<Workout> abcdeWorkouts) {
    final result = <PlannedSlot>[];
    for (var i = 0; i < abcdeWorkouts.length && i < 5; i++) {
      result.add(PlannedSlot(
        day: i + 1,
        slot: SessionSlot.afternoon,
        workoutId: abcdeWorkouts[i].id,
        autoAssigned: true,
      ));
    }
    return result;
  }
}
