import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/sleep_log.dart';

abstract class SleepRepository {
  Future<Either<AppFailure, SleepLog>> logSleep(SleepLog sleepLog);
  Future<Either<AppFailure, List<SleepLog>>> getSleepLogs(
    String userId, {
    int limit = 30,
  });
  Future<Either<AppFailure, double>> getAverageSleepQuality(
    String userId,
    int daysBack,
  );
}
