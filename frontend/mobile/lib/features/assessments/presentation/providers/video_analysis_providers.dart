import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/repositories/video_analysis_repository_impl.dart';
import '../../data/services/flutter_pose_estimation_service.dart';
import '../../domain/entities/video_analysis.dart';
import '../../domain/services/pose_estimation_service.dart';
import '../../domain/usecases/analyze_movement_video.dart';

// ── PoseEstimationService provider ───────────────────────────────────────────

final poseEstimationServiceProvider = Provider<PoseEstimationService>((ref) {
  final service = FlutterPoseEstimationService();
  ref.onDispose(service.dispose);
  return service;
});

// ── AnalyzeMovementVideo notifier ─────────────────────────────────────────────

/// Holds the list of [VideoAnalysis] results produced in the current recording
/// session. Each call to [analyze] appends one result.
class AnalyzeMovementVideoNotifier extends AsyncNotifier<List<VideoAnalysis>> {
  @override
  Future<List<VideoAnalysis>> build() async => [];

  Future<Either<AppFailure, VideoAnalysis>> analyze(
      AnalyzeMovementVideoInput input) async {
    final useCase = AnalyzeMovementVideo(
      ref.read(videoAnalysisRepositoryProvider),
      ref.read(poseEstimationServiceProvider),
    );
    final result = await useCase(input);
    result.fold(
      (_) {},
      (analysis) {
        state = AsyncData([
          ...state.valueOrNull ?? [],
          analysis,
        ]);
      },
    );
    return result;
  }

  void reset() {
    state = const AsyncData([]);
  }
}

final analyzeMovementVideoProvider =
    AsyncNotifierProvider<AnalyzeMovementVideoNotifier, List<VideoAnalysis>>(
  AnalyzeMovementVideoNotifier.new,
);

// ── VideoAnalysis history provider ────────────────────────────────────────────

final videoAnalysesByAssessmentProvider =
    FutureProvider.family<List<VideoAnalysis>, String>(
        (ref, assessmentId) async {
  final repo = ref.watch(videoAnalysisRepositoryProvider);
  final result = await repo.getByAssessment(assessmentId);
  return result.fold((_) => [], (list) => list);
});
