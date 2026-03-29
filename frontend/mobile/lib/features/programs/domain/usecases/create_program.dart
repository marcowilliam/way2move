import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/program.dart';
import '../repositories/program_repository.dart';

class CreateProgram {
  final ProgramRepository _repo;
  const CreateProgram(this._repo);

  Future<Either<AppFailure, Program>> call(Program program) =>
      _repo.createProgram(program);
}
