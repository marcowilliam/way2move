import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/meal.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/firestore_meal_datasource.dart';

class MealRepositoryImpl implements MealRepository {
  final FirestoreMealDatasource _datasource;
  MealRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, Meal>> createMeal(Meal meal) async {
    try {
      final model = await _datasource.create(meal);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Meal>> updateMeal(Meal meal) async {
    try {
      final model = await _datasource.update(meal);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, Unit>> deleteMeal(String mealId) async {
    try {
      await _datasource.delete(mealId);
      return const Right(unit);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Meal>>> getMealsByDate(
      String userId, DateTime date) async {
    try {
      final models = await _datasource.getByDate(userId, date);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Meal>>> getMealHistory(String userId,
      {int limit = 100}) async {
    try {
      final models = await _datasource.getHistory(userId, limit: limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreMealDatasourceProvider =
    Provider<FirestoreMealDatasource>((ref) {
  return FirestoreMealDatasource(ref.watch(firestoreProvider));
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl(ref.watch(firestoreMealDatasourceProvider));
});
