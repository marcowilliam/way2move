import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

class GetGoalsByCompensation {
  final GoalRepository _repo;
  const GetGoalsByCompensation(this._repo);

  Future<Either<AppFailure, List<Goal>>> call(
          String userId, String compensationId) =>
      _repo.getByCompensation(userId, compensationId);
}
