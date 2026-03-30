import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../datasources/firestore_sleep_datasource.dart';
import '../models/sleep_log_model.dart';

class SleepRepositoryImpl implements SleepRepository {
  final FirestoreSleepDatasource _datasource;

  SleepRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, SleepLog>> logSleep(SleepLog sleepLog) async {
    try {
      final model = SleepLogModel.fromEntity(sleepLog);
      final ref = await _datasource.create(model.toFirestore());
      final doc = await ref.get();
      return Right(SleepLogModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<SleepLog>>> getSleepLogs(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final snap = await _datasource.getByUser(userId, limit: limit);
      final list = snap.docs
          .map((doc) => SleepLogModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, double>> getAverageSleepQuality(
    String userId,
    int daysBack,
  ) async {
    try {
      final since = DateTime.now().subtract(Duration(days: daysBack));
      final snap = await _datasource.getByUserSince(userId, since);
      if (snap.docs.isEmpty) return const Right(0.0);
      final total = snap.docs
          .map((doc) => SleepLogModel.fromFirestore(doc).quality)
          .reduce((a, b) => a + b);
      return Right(total / snap.docs.length);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreSleepDatasourceProvider =
    Provider<FirestoreSleepDatasource>((ref) {
  return FirestoreSleepDatasource(ref.watch(firestoreProvider));
});

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepositoryImpl(ref.watch(firestoreSleepDatasourceProvider));
});
