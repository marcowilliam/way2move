import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/sleep_log.dart';
import '../repositories/sleep_repository.dart';

class LogSleep {
  final SleepRepository _repo;
  const LogSleep(this._repo);

  Future<Either<AppFailure, SleepLog>> call(SleepLog sleepLog) =>
      _repo.logSleep(sleepLog);
}
