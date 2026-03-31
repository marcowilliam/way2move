import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/recovery_score.dart';
import '../../domain/repositories/recovery_score_repository.dart';
import '../datasources/firestore_recovery_score_datasource.dart';
import '../models/recovery_score_model.dart';

class RecoveryScoreRepositoryImpl implements RecoveryScoreRepository {
  final FirestoreRecoveryScoreDatasource _datasource;
  const RecoveryScoreRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, RecoveryScore?>> getToday(String userId) async {
    try {
      final model = await _datasource.fetchForDate(userId, DateTime.now());
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, RecoveryScore?>> getForDate(
      String userId, DateTime date) async {
    try {
      final model = await _datasource.fetchForDate(userId, date);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, List<RecoveryScore>>> getTrend(
      String userId, int days) async {
    try {
      final models = await _datasource.fetchTrend(userId, days);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, void>> save(RecoveryScore score) async {
    try {
      await _datasource.save(RecoveryScoreModel.fromEntity(score));
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }
}
