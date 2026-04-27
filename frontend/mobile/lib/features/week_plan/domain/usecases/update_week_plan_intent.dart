import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/week_plan.dart';
import '../repositories/week_plan_repository.dart';

/// Updates the week's intent text and focus areas. Called from the
/// planner header.
class UpdateWeekPlanIntent {
  final WeekPlanRepository _repo;
  const UpdateWeekPlanIntent(this._repo);

  Future<Either<AppFailure, WeekPlan>> call({
    required WeekPlan plan,
    String? intent,
    List<String>? focusAreas,
  }) {
    final updated = plan.copyWith(
      intent: intent ?? plan.intent,
      focusAreas: focusAreas ?? plan.focusAreas,
    );
    return _repo.updateWeekPlan(updated);
  }
}
