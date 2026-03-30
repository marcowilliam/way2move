import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/weight_log.dart';
import '../repositories/weight_log_repository.dart';

class LogWeight {
  final WeightLogRepository _repo;
  const LogWeight(this._repo);

  Future<Either<AppFailure, WeightLog>> call(WeightLog log) =>
      _repo.logWeight(log);
}
