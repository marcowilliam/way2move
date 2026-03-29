import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

class MarkGoalAchieved {
  final GoalRepository _repo;
  const MarkGoalAchieved(this._repo);

  Future<Either<AppFailure, Goal>> call(String goalId) =>
      _repo.markAchieved(goalId);
}
