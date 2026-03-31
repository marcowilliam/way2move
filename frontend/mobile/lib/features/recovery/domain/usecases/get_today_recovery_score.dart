import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/recovery_score.dart';
import '../repositories/recovery_score_repository.dart';

class GetTodayRecoveryScore {
  final RecoveryScoreRepository _repo;
  const GetTodayRecoveryScore(this._repo);

  Future<Either<AppFailure, RecoveryScore?>> call(String userId) =>
      _repo.getToday(userId);
}
