import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/week_plan.dart';
import '../repositories/week_plan_repository.dart';

/// Stamps the week as reviewed and persists the user's reflection.
class SaveWeekReview {
  final WeekPlanRepository _repo;
  const SaveWeekReview(this._repo);

  Future<Either<AppFailure, WeekPlan>> call({
    required WeekPlan plan,
    required String reviewNotes,
    required DateTime reviewedAt,
  }) {
    final updated = plan.copyWith(
      reviewNotes: reviewNotes,
      reviewedAt: reviewedAt,
    );
    return _repo.updateWeekPlan(updated);
  }
}
