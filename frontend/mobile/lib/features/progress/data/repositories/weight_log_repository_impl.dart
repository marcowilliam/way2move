import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/weight_log.dart';
import '../../domain/repositories/weight_log_repository.dart';
import '../datasources/firestore_weight_log_datasource.dart';

class WeightLogRepositoryImpl implements WeightLogRepository {
  final FirestoreWeightLogDatasource _datasource;
  WeightLogRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, WeightLog>> logWeight(WeightLog log) async {
    try {
      final model = await _datasource.save(log);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<WeightLog>>> getLogs(String userId,
      {int limit = 50}) async {
    try {
      final models = await _datasource.getLogs(userId, limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<WeightLog>>> getTrend(
      String userId, int daysBack) async {
    try {
      final models = await _datasource.getTrend(userId, daysBack);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreWeightLogDatasourceProvider =
    Provider<FirestoreWeightLogDatasource>((ref) {
  return FirestoreWeightLogDatasource(ref.watch(firestoreProvider));
});

final weightLogRepositoryProvider = Provider<WeightLogRepository>((ref) {
  return WeightLogRepositoryImpl(
    ref.watch(firestoreWeightLogDatasourceProvider),
  );
});
