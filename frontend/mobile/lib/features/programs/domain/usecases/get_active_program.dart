import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/program.dart';
import '../repositories/program_repository.dart';

class GetActiveProgram {
  final ProgramRepository _repo;
  const GetActiveProgram(this._repo);

  Future<Either<AppFailure, Program?>> call(String userId) =>
      _repo.getActiveProgram(userId);
}
