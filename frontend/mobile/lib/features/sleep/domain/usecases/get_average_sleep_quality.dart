import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../repositories/sleep_repository.dart';

class GetAverageSleepQuality {
  final SleepRepository _repo;
  const GetAverageSleepQuality(this._repo);

  Future<Either<AppFailure, double>> call(String userId, int daysBack) =>
      _repo.getAverageSleepQuality(userId, daysBack);
}
