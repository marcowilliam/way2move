import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/nutrition_target.dart';
import '../../domain/repositories/nutrition_target_repository.dart';
import '../datasources/firestore_nutrition_target_datasource.dart';
import '../models/nutrition_target_model.dart';

class NutritionTargetRepositoryImpl implements NutritionTargetRepository {
  final FirestoreNutritionTargetDatasource _datasource;
  NutritionTargetRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, NutritionTarget?>> getTarget(String userId) async {
    try {
      final model = await _datasource.get(userId);
      return Right(model?.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }

  @override
  Future<Either<AppFailure, NutritionTarget>> saveTarget(
      NutritionTarget target) async {
    try {
      final model =
          await _datasource.save(NutritionTargetModel.fromEntity(target));
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }
}

// Providers
final _firestoreNutritionTargetDatasourceProvider =
    Provider<FirestoreNutritionTargetDatasource>((ref) {
  return FirestoreNutritionTargetDatasource(ref.watch(firestoreProvider));
});

final nutritionTargetRepositoryProvider =
    Provider<NutritionTargetRepository>((ref) {
  return NutritionTargetRepositoryImpl(
      ref.watch(_firestoreNutritionTargetDatasourceProvider));
});
