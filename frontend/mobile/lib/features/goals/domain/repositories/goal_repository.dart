import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/goal.dart';

abstract class GoalRepository {
  Future<Either<AppFailure, Goal>> create(Goal goal);
  Future<Either<AppFailure, Goal>> update(Goal goal);
  Future<Either<AppFailure, List<Goal>>> getAll(String userId);
  Future<Either<AppFailure, List<Goal>>> getByStatus(
      String userId, GoalStatus status);
  Future<Either<AppFailure, List<Goal>>> getByCompensation(
      String userId, String compensationId);
  Future<Either<AppFailure, Goal>> markAchieved(String goalId);
}
