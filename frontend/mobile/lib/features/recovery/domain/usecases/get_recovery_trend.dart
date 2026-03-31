import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/recovery_score.dart';
import '../repositories/recovery_score_repository.dart';

class GetRecoveryTrend {
  final RecoveryScoreRepository _repo;
  const GetRecoveryTrend(this._repo);

  Future<Either<AppFailure, List<RecoveryScore>>> call(
          String userId, int days) =>
      _repo.getTrend(userId, days);
}
