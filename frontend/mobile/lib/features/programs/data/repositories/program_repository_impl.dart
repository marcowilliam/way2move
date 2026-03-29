import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';
import '../datasources/firestore_program_datasource.dart';

class ProgramRepositoryImpl implements ProgramRepository {
  final FirestoreProgramDatasource _datasource;
  ProgramRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, Program>> createProgram(Program program) async {
    try {
      final model = await _datasource.create(program);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Program?>> getActiveProgram(String userId) async {
    try {
      final model = await _datasource.getActive(userId);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Program>> updateProgram(Program program) async {
    try {
      final model = await _datasource.update(program);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, void>> deactivateProgram(String programId) async {
    try {
      await _datasource.deactivate(programId);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Program>>> getProgramHistory(
      String userId) async {
    try {
      final models = await _datasource.getHistory(userId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreProgramDatasourceProvider =
    Provider<FirestoreProgramDatasource>((ref) {
  return FirestoreProgramDatasource(ref.watch(firestoreProvider));
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepositoryImpl(
    ref.watch(firestoreProgramDatasourceProvider),
  );
});
