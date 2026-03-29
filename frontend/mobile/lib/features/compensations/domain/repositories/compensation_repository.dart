import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';

abstract class CompensationRepository {
  Future<Either<AppFailure, Compensation>> create(Compensation compensation);
  Future<Either<AppFailure, Compensation>> update(Compensation compensation);
  Future<Either<AppFailure, List<Compensation>>> getActive(String userId);
  Future<Either<AppFailure, List<Compensation>>> getByRegion(
      String userId, CompensationRegion region);
  Stream<List<Compensation>> watchByUser(String userId);
  Future<Either<AppFailure, Compensation>> markImproving(
      String compensationId, String note);
  Future<Either<AppFailure, Compensation>> markResolved(
      String compensationId, String note);
}
