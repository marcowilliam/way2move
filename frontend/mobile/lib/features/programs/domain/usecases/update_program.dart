import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/program.dart';
import '../repositories/program_repository.dart';

class UpdateProgram {
  final ProgramRepository _repo;
  const UpdateProgram(this._repo);

  Future<Either<AppFailure, Program>> call(Program program) =>
      _repo.updateProgram(program);
}
