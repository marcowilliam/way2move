import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/firestore_exercise_datasource.dart';
import '../models/exercise_model.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final FirestoreExerciseDatasource _datasource;

  // In-memory cache — seed data cached permanently after first load
  List<Exercise>? _cache;

  ExerciseRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, List<Exercise>>> getExercises() async {
    if (_cache != null) return Right(_cache!);

    // Seed exercises always loaded from local data
    final seedModels = _datasource.getSeedExercises();
    final seedExercises = seedModels.map((m) => m.toEntity()).toList();

    // Custom exercises from Firestore
    try {
      final customModels = await _datasource.fetchExercises();
      final customExercises = customModels
          .where((m) => m.isCustom)
          .map((m) => m.toEntity())
          .toList();
      _cache = [...seedExercises, ...customExercises];
      return Right(_cache!);
    } on FirebaseException catch (_) {
      // If Firestore fails, return seed data only
      _cache = seedExercises;
      return Right(_cache!);
    } catch (_) {
      _cache = seedExercises;
      return Right(_cache!);
    }
  }

  @override
  Future<Either<AppFailure, Exercise>> getExerciseById(String id) async {
    // Check cache first
    if (_cache != null) {
      final cached = _cache!.where((e) => e.id == id).toList();
      if (cached.isNotEmpty) return Right(cached.first);
    }

    // Try seed data
    final seedModels = _datasource.getSeedExercises();
    final seed = seedModels.where((m) => m.id == id).toList();
    if (seed.isNotEmpty) return Right(seed.first.toEntity());

    // Fetch from Firestore
    try {
      final model = await _datasource.fetchExerciseById(id);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(NotFoundFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<Exercise>>> searchExercises(
      String query) async {
    final allResult = await getExercises();
    return allResult.map((exercises) {
      final q = query.toLowerCase();
      return exercises
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.typeTags.any((t) => t.name.contains(q)) ||
              e.regionTags.any((t) => t.name.contains(q)) ||
              e.patternTags.any((t) => t.name.contains(q)))
          .toList();
    });
  }

  @override
  Future<Either<AppFailure, List<Exercise>>> filterExercises({
    List<SportTag>? sportTags,
    List<ExerciseType>? typeTags,
    List<BodyRegion>? regionTags,
    List<EquipmentTag>? equipmentTags,
    ExerciseDifficulty? difficulty,
  }) async {
    final allResult = await getExercises();
    return allResult.map((exercises) {
      return exercises.where((e) {
        if (sportTags != null && sportTags.isNotEmpty) {
          if (!e.sportTags.any((t) => sportTags.contains(t))) return false;
        }
        if (typeTags != null && typeTags.isNotEmpty) {
          if (!e.typeTags.any((t) => typeTags.contains(t))) return false;
        }
        if (regionTags != null && regionTags.isNotEmpty) {
          if (!e.regionTags.any((t) => regionTags.contains(t))) return false;
        }
        if (equipmentTags != null && equipmentTags.isNotEmpty) {
          if (!e.equipmentTags.any((t) => equipmentTags.contains(t))) {
            return false;
          }
        }
        if (difficulty != null && e.difficulty != difficulty) return false;
        return true;
      }).toList();
    });
  }

  @override
  Future<Either<AppFailure, Exercise>> addCustomExercise(
      Exercise exercise) async {
    try {
      final model = ExerciseModel.fromEntity(exercise);
      final saved = await _datasource.addCustomExercise(model);
      final entity = saved.toEntity();
      // Invalidate cache so next getExercises includes new custom exercise
      _cache = null;
      return Right(entity);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreExerciseDatasourceProvider =
    Provider<FirestoreExerciseDatasource>((ref) {
  return FirestoreExerciseDatasource(ref.watch(firestoreProvider));
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepositoryImpl(
    ref.watch(firestoreExerciseDatasourceProvider),
  );
});
