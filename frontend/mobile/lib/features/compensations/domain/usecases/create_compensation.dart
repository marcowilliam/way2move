import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';

class CreateCompensation {
  final CompensationRepository _repo;
  const CreateCompensation(this._repo);

  Future<Either<AppFailure, Compensation>> call(Compensation compensation) =>
      _repo.create(compensation);
}
