import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/weight_log.dart';
import '../repositories/weight_log_repository.dart';

class GetWeightTrend {
  final WeightLogRepository _repo;
  const GetWeightTrend(this._repo);

  Future<Either<AppFailure, List<WeightLog>>> call(
    String userId,
    int daysBack,
  ) =>
      _repo.getTrend(userId, daysBack);
}
