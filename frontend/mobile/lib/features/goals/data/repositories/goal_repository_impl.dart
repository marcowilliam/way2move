import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../datasources/firestore_goal_datasource.dart';
import '../models/goal_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  final FirestoreGoalDatasource _datasource;

  GoalRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, Goal>> create(Goal goal) async {
    try {
      final model = GoalModel.fromEntity(goal);
      final data = model.toFirestore();
      data['meta'] = {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final ref = await _datasource.create(data);
      final doc = await ref.get();
      return Right(GoalModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Goal>> update(Goal goal) async {
    try {
      final model = GoalModel.fromEntity(goal);
      await _datasource.update(goal.id, model.toFirestore());
      final doc = await _datasource.get(goal.id);
      if (!doc.exists) return const Left(NotFoundFailure());
      return Right(GoalModel.fromFirestore(doc).toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Goal>>> getAll(String userId) async {
    try {
      final snap = await _datasource.getAll(userId);
      final list = snap.docs
          .map((doc) => GoalModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Goal>>> getByStatus(
      String userId, GoalStatus status) async {
    try {
      final snap = await _datasource.getByStatus(userId, status.name);
      final list = snap.docs
          .map((doc) => GoalModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Goal>>> getByCompensation(
      String userId, String compensationId) async {
    try {
      final snap = await _datasource.getByCompensation(userId, compensationId);
      final list = snap.docs
          .map((doc) => GoalModel.fromFirestore(doc).toEntity())
          .toList();
      return Right(list);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Goal>> markAchieved(String goalId) async {
    try {
      final doc = await _datasource.get(goalId);
      if (!doc.exists) return const Left(NotFoundFailure());
      final current = GoalModel.fromFirestore(doc).toEntity();
      final updated = current.copyWith(
        status: GoalStatus.achieved,
        achievedAt: DateTime.now(),
        currentValue: current.targetValue,
      );
      return update(updated);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreGoalDatasourceProvider =
    Provider<FirestoreGoalDatasource>((ref) {
  return FirestoreGoalDatasource(ref.watch(firestoreProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(ref.watch(firestoreGoalDatasourceProvider));
});
