import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';

class UpdateCompensation {
  final CompensationRepository _repo;
  const UpdateCompensation(this._repo);

  Future<Either<AppFailure, Compensation>> call(Compensation compensation) =>
      _repo.update(compensation);
}
