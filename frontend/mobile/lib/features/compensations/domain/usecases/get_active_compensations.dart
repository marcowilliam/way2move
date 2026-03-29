import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';

class GetActiveCompensations {
  final CompensationRepository _repo;
  const GetActiveCompensations(this._repo);

  Future<Either<AppFailure, List<Compensation>>> call(String userId) =>
      _repo.getActive(userId);
}
