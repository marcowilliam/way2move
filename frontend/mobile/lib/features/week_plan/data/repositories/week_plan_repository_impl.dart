import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/week_plan.dart';
import '../../domain/repositories/week_plan_repository.dart';
import '../datasources/firestore_week_plan_datasource.dart';

class WeekPlanRepositoryImpl implements WeekPlanRepository {
  final FirestoreWeekPlanDatasource _datasource;
  WeekPlanRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, WeekPlan?>> getWeekPlan(
    String userId,
    String isoYearWeek,
  ) async {
    try {
      final model = await _datasource.getWeekPlan(userId, isoYearWeek);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Stream<WeekPlan?> watchWeekPlan(String userId, String isoYearWeek) {
    return _datasource
        .watchWeekPlan(userId, isoYearWeek)
        .map((model) => model?.toEntity());
  }

  @override
  Future<Either<AppFailure, WeekPlan>> createWeekPlan(WeekPlan plan) async {
    try {
      final model = await _datasource.create(plan);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, WeekPlan>> updateWeekPlan(WeekPlan plan) async {
    try {
      final model = await _datasource.update(plan);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

final firestoreWeekPlanDatasourceProvider =
    Provider<FirestoreWeekPlanDatasource>((ref) {
  return FirestoreWeekPlanDatasource(ref.watch(firestoreProvider));
});

final weekPlanRepositoryProvider = Provider<WeekPlanRepository>((ref) {
  return WeekPlanRepositoryImpl(
    ref.watch(firestoreWeekPlanDatasourceProvider),
  );
});
