import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/compensation.dart';
import '../repositories/compensation_repository.dart';

class MarkCompensationImproving {
  final CompensationRepository _repo;
  const MarkCompensationImproving(this._repo);

  Future<Either<AppFailure, Compensation>> call(
          String compensationId, String note) =>
      _repo.markImproving(compensationId, note);
}
