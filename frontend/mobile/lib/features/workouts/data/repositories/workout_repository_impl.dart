import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';
import '../../domain/repositories/workout_repository.dart';
import '../datasources/firestore_workout_datasource.dart';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final FirestoreWorkoutDatasource _datasource;
  WorkoutRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, List<Workout>>> getWorkouts(
    String userId, {
    WorkoutKind? kind,
  }) async {
    try {
      final models = await _datasource.getWorkouts(userId, kind: kind);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<List<Workout>> watchWorkouts(
    String userId, {
    WorkoutKind? kind,
  }) {
    return _datasource
        .watchWorkouts(userId, kind: kind)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Either<AppFailure, Workout>> getWorkoutById(String workoutId) async {
    try {
      final model = await _datasource.getWorkoutById(workoutId);
      if (model == null) return const Left(NotFoundFailure());
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Workout>> createWorkout(Workout workout) async {
    try {
      final model = await _datasource.create(workout);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Workout>> updateWorkout(Workout workout) async {
    try {
      final model = await _datasource.update(workout);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, void>> deleteWorkout(String workoutId) async {
    try {
      await _datasource.delete(workoutId);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

final firestoreWorkoutDatasourceProvider =
    Provider<FirestoreWorkoutDatasource>((ref) {
  return FirestoreWorkoutDatasource(ref.watch(firestoreProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepositoryImpl(
    ref.watch(firestoreWorkoutDatasourceProvider),
  );
});
