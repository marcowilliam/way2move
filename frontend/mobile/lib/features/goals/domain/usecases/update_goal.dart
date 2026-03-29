import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

class UpdateGoal {
  final GoalRepository _repo;
  const UpdateGoal(this._repo);

  Future<Either<AppFailure, Goal>> call(Goal goal) => _repo.update(goal);
}
