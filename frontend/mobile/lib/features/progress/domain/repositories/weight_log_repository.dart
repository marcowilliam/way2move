import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/weight_log.dart';

abstract class WeightLogRepository {
  Future<Either<AppFailure, WeightLog>> logWeight(WeightLog log);

  Future<Either<AppFailure, List<WeightLog>>> getLogs(
    String userId, {
    int limit = 50,
  });

  Future<Either<AppFailure, List<WeightLog>>> getTrend(
    String userId,
    int daysBack,
  );
}
