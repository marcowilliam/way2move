import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../domain/entities/video_analysis.dart';
import '../../domain/repositories/video_analysis_repository.dart';
import '../datasources/firestore_video_analysis_datasource.dart';

class VideoAnalysisRepositoryImpl implements VideoAnalysisRepository {
  final FirestoreVideoAnalysisDatasource _datasource;

  VideoAnalysisRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, VideoAnalysis>> save(VideoAnalysis analysis) async {
    try {
      final model = await _datasource.save(analysis);
      return Right(model.toEntity());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, List<VideoAnalysis>>> getByAssessment(
      String assessmentId) async {
    try {
      final models = await _datasource.getByAssessment(assessmentId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<AppFailure, String>> uploadVideo({
    required String localPath,
    required String userId,
    required String assessmentId,
    required String movementName,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final storagePath = await _datasource.uploadVideo(
        localFile: File(localPath),
        userId: userId,
        assessmentId: assessmentId,
        movementName: movementName,
        onProgress: onProgress,
      );
      return Right(storagePath);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final firestoreVideoAnalysisDatasourceProvider =
    Provider<FirestoreVideoAnalysisDatasource>((ref) {
  return FirestoreVideoAnalysisDatasource(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final videoAnalysisRepositoryProvider =
    Provider<VideoAnalysisRepository>((ref) {
  return VideoAnalysisRepositoryImpl(
    ref.watch(firestoreVideoAnalysisDatasourceProvider),
  );
});
