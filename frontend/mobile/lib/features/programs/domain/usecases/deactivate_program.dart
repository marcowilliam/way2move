import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../repositories/program_repository.dart';

class DeactivateProgram {
  final ProgramRepository _repo;
  const DeactivateProgram(this._repo);

  Future<Either<AppFailure, void>> call(String programId) =>
      _repo.deactivateProgram(programId);
}
