import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/progress_photo.dart';
import '../../domain/repositories/progress_photo_repository.dart';
import '../datasources/firestore_progress_photo_datasource.dart';

class ProgressPhotoRepositoryImpl implements ProgressPhotoRepository {
  final FirestoreProgressPhotoDatasource _datasource;
  ProgressPhotoRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, ProgressPhoto>> capturePhoto(
      ProgressPhoto photo) async {
    try {
      final model = await _datasource.save(photo);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  /// Upload a local file to Storage + save metadata to Firestore.
  Future<Either<AppFailure, ProgressPhoto>> capturePhotoFromFile({
    required File imageFile,
    required String userId,
    required DateTime date,
    required PhotoAngle angle,
    String? notes,
  }) async {
    try {
      final model = await _datasource.uploadAndSave(
        imageFile: imageFile,
        userId: userId,
        date: date,
        angle: angle,
        notes: notes,
      );
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<ProgressPhoto>>> getPhotosByDate(
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
  Future<Either<AppFailure, List<ProgressPhoto>>> getTimeline(String userId,
      {int limit = 50}) async {
    try {
      final models = await _datasource.getTimeline(userId, limit);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<ProgressPhoto>>> getByAngle(
      String userId, PhotoAngle angle) async {
    try {
      final models = await _datasource.getByAngle(userId, angle);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// Providers
final firestoreProgressPhotoDatasourceProvider =
    Provider<FirestoreProgressPhotoDatasource>((ref) {
  return FirestoreProgressPhotoDatasource(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final progressPhotoRepositoryProvider =
    Provider<ProgressPhotoRepository>((ref) {
  return ProgressPhotoRepositoryImpl(
    ref.watch(firestoreProgressPhotoDatasourceProvider),
  );
});
