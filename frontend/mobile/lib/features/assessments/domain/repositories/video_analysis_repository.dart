import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/video_analysis.dart';

abstract class VideoAnalysisRepository {
  /// Persists a [VideoAnalysis] result to Firestore.
  ///
  /// The returned entity has its [VideoAnalysis.id] populated by Firestore.
  Future<Either<AppFailure, VideoAnalysis>> save(VideoAnalysis analysis);

  /// Returns all [VideoAnalysis] records linked to [assessmentId],
  /// ordered by [VideoAnalysis.analyzedAt] ascending.
  Future<Either<AppFailure, List<VideoAnalysis>>> getByAssessment(
      String assessmentId);

  /// Uploads the local video file at [localPath] to Firebase Storage and
  /// returns the storage path on success.
  ///
  /// Storage path format:
  /// `users/{userId}/assessments/{assessmentId}/{movement}.mp4`
  Future<Either<AppFailure, String>> uploadVideo({
    required String localPath,
    required String userId,
    required String assessmentId,
    required String movementName,
    void Function(double progress)? onProgress,
  });
}
