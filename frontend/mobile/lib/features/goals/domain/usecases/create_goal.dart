import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

class CreateGoal {
  final GoalRepository _repo;
  const CreateGoal(this._repo);

  Future<Either<AppFailure, Goal>> call(Goal goal) => _repo.create(goal);
}
