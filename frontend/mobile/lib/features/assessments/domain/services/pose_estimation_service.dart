import '../entities/pose_frame.dart';

/// Inference mode hint passed to the service.
///
/// - [gpu]: lowest latency (~3 ms/frame), best for live camera feed.
/// - [npu]: battery-efficient (~13 ms/frame), preferred for batch
///   post-recording analysis on supported Snapdragon devices.
/// - [cpu]: fallback when no hardware accelerator is available.
enum InferenceMode { gpu, npu, cpu }

/// Result of analysing a recorded video clip.
///
/// Named [PoseAnalysisResult] to avoid collision with the SDK's own
/// [VideoAnalysisResult] type.
class PoseAnalysisResult {
  /// Ordered list of pose frames extracted from the clip, one per detected
  /// keyframe. May be empty if no person was detected.
  final List<PoseFrame> frames;

  /// Total number of video frames that were processed (includes frames where
  /// no person was detected).
  final int totalFramesProcessed;

  const PoseAnalysisResult({
    required this.frames,
    required this.totalFramesProcessed,
  });

  /// Percentage of frames in which a person was successfully detected.
  double get detectionRate =>
      totalFramesProcessed == 0 ? 0.0 : frames.length / totalFramesProcessed;
}

/// Abstract interface for on-device pose estimation.
///
/// All inference runs **on-device** — no network calls are made.
/// Implementations wrap a hardware-accelerated ML backend (e.g.
/// `flutter_pose_detection` / MediaPipe BlazePose).
abstract class PoseEstimationService {
  /// Analyses a single image frame and returns a [PoseFrame] if a person is
  /// detected, or null otherwise.
  ///
  /// [imageBytes] must be a JPEG- or PNG-encoded image.
  /// [mode] selects the inference backend; defaults to [InferenceMode.gpu].
  Future<PoseFrame?> analyzeFrame(
    List<int> imageBytes, {
    InferenceMode mode = InferenceMode.gpu,
  });

  /// Analyses a recorded video file at [videoPath] and extracts a
  /// [PoseFrame] for each detected keyframe.
  ///
  /// Use [InferenceMode.npu] for post-recording batch analysis to preserve
  /// battery. Progress updates are reported via [onProgress] (0.0 → 1.0).
  ///
  /// Throws [PoseEstimationException] if the file cannot be opened or if
  /// inference fails unrecoverably.
  Future<PoseAnalysisResult> analyzeVideo(
    String videoPath, {
    InferenceMode mode = InferenceMode.npu,
    void Function(double progress)? onProgress,
  });

  /// Releases any native resources held by the service.
  Future<void> dispose();
}

/// Thrown by [PoseEstimationService] when inference fails.
class PoseEstimationException implements Exception {
  final String message;
  const PoseEstimationException(this.message);

  @override
  String toString() => 'PoseEstimationException: $message';
}
