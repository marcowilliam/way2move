import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/sleep_log.dart';
import '../repositories/sleep_repository.dart';

class GetSleepLogs {
  final SleepRepository _repo;
  const GetSleepLogs(this._repo);

  Future<Either<AppFailure, List<SleepLog>>> call(
    String userId, {
    int limit = 30,
  }) =>
      _repo.getSleepLogs(userId, limit: limit);
}
