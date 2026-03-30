import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/video_analysis.dart';
import '../repositories/video_analysis_repository.dart';
import '../services/pose_estimation_service.dart';

class AnalyzeMovementVideoInput {
  final String localVideoPath;
  final String assessmentId;
  final String userId;
  final ScreeningMovement movement;
  final void Function(double progress)? onUploadProgress;
  final void Function(double progress)? onAnalysisProgress;

  const AnalyzeMovementVideoInput({
    required this.localVideoPath,
    required this.assessmentId,
    required this.userId,
    required this.movement,
    this.onUploadProgress,
    this.onAnalysisProgress,
  });
}

/// Orchestrates the full pipeline for a single movement clip:
///
/// 1. Upload the compressed video to Firebase Storage.
/// 2. Run on-device pose estimation to extract [PoseFrame]s.
/// 3. Save the [VideoAnalysis] result to Firestore.
///
/// Returns [Left] if any step fails; the pipeline aborts early.
class AnalyzeMovementVideo {
  final VideoAnalysisRepository _repo;
  final PoseEstimationService _poseService;

  AnalyzeMovementVideo(this._repo, this._poseService);

  Future<Either<AppFailure, VideoAnalysis>> call(
      AnalyzeMovementVideoInput input) async {
    // Step 1 — Upload video
    final uploadResult = await _repo.uploadVideo(
      localPath: input.localVideoPath,
      userId: input.userId,
      assessmentId: input.assessmentId,
      movementName: input.movement.name,
      onProgress: input.onUploadProgress,
    );

    late final String storagePath;
    final uploadEither = uploadResult.fold(
      (failure) => Left<AppFailure, String>(failure),
      (path) {
        storagePath = path;
        return Right<AppFailure, String>(path);
      },
    );
    if (uploadEither.isLeft())
      return Left(uploadEither.getLeft().toNullable()!);

    // Step 2 — Pose estimation (on-device, NPU mode for battery efficiency)
    final PoseAnalysisResult poseResult;
    try {
      poseResult = await _poseService.analyzeVideo(
        input.localVideoPath,
        mode: InferenceMode.npu,
        onProgress: input.onAnalysisProgress,
      );
    } on PoseEstimationException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (_) {
      return const Left(ServerFailure());
    }

    // Step 3 — Persist result
    final analysis = VideoAnalysis(
      id: '',
      assessmentId: input.assessmentId,
      userId: input.userId,
      movement: input.movement,
      frames: poseResult.frames,
      detectedCompensations: const [],
      storageVideoPath: storagePath,
      analyzedAt: DateTime.now(),
    );

    return _repo.save(analysis);
  }
}
