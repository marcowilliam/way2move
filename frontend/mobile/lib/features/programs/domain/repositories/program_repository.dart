import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/program.dart';

abstract class ProgramRepository {
  Future<Either<AppFailure, Program>> createProgram(Program program);
  Future<Either<AppFailure, Program?>> getActiveProgram(String userId);
  Future<Either<AppFailure, Program>> updateProgram(Program program);
  Future<Either<AppFailure, void>> deactivateProgram(String programId);
  Future<Either<AppFailure, List<Program>>> getProgramHistory(String userId);
}
