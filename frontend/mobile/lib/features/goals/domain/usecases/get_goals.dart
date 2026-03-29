import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/goal.dart';
import '../repositories/goal_repository.dart';

class GetGoals {
  final GoalRepository _repo;
  const GetGoals(this._repo);

  Future<Either<AppFailure, List<Goal>>> call(String userId) =>
      _repo.getAll(userId);
}
