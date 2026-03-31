import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/recovery_score.dart';

abstract class RecoveryScoreRepository {
  Future<Either<AppFailure, RecoveryScore?>> getToday(String userId);
  Future<Either<AppFailure, RecoveryScore?>> getForDate(
      String userId, DateTime date);
  Future<Either<AppFailure, List<RecoveryScore>>> getTrend(
      String userId, int days);
  Future<Either<AppFailure, void>> save(RecoveryScore score);
}
