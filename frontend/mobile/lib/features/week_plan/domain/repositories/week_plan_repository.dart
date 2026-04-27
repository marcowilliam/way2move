import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/week_plan.dart';

abstract class WeekPlanRepository {
  /// Returns the WeekPlan for the given ISO year-week, or null if none
  /// exists yet. Use cases call this and decide whether to create.
  Future<Either<AppFailure, WeekPlan?>> getWeekPlan(
    String userId,
    String isoYearWeek,
  );

  /// Live stream — drives Today's "this week's intent" header and the
  /// planner.
  Stream<WeekPlan?> watchWeekPlan(String userId, String isoYearWeek);

  Future<Either<AppFailure, WeekPlan>> createWeekPlan(WeekPlan plan);

  Future<Either<AppFailure, WeekPlan>> updateWeekPlan(WeekPlan plan);
}
