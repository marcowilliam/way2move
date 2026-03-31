import 'dart:typed_data';

import 'package:flutter_pose_detection/flutter_pose_detection.dart' as sdk
    show
        NpuPoseDetector,
        PoseResult,
        VideoAnalysisResult,
        LandmarkType,
        AccelerationMode;

import '../../domain/entities/pose_frame.dart';
import '../../domain/entities/pose_landmark.dart';
import '../../domain/services/pose_estimation_service.dart';

// ---------------------------------------------------------------------------
// Internal wrapper interface — lets us inject a fake in tests without
// exposing SDK types in the domain layer.
// ---------------------------------------------------------------------------

/// Thin adapter interface over [sdk.NpuPoseDetector].
/// Only exposes the operations [FlutterPoseEstimationService] needs.
abstract class PoseDetectorAdapter {
  Future<sdk.AccelerationMode> initialize();
  Future<sdk.PoseResult> detectPose(Uint8List imageBytes);
  Future<sdk.VideoAnalysisResult> analyzeVideo(
    String videoPath, {
    int frameInterval,
  });
  void dispose();
}

/// Default adapter wrapping the real [sdk.NpuPoseDetector].
class DefaultPoseDetectorAdapter implements PoseDetectorAdapter {
  final sdk.NpuPoseDetector _detector;

  DefaultPoseDetectorAdapter({sdk.NpuPoseDetector? detector})
      : _detector = detector ?? sdk.NpuPoseDetector();

  @override
  Future<sdk.AccelerationMode> initialize() => _detector.initialize();

  @override
  Future<sdk.PoseResult> detectPose(Uint8List imageBytes) =>
      _detector.detectPose(imageBytes);

  @override
  Future<sdk.VideoAnalysisResult> analyzeVideo(
    String videoPath, {
    int frameInterval = 1,
  }) =>
      _detector.analyzeVideo(videoPath, frameInterval: frameInterval);

  @override
  void dispose() => _detector.dispose();
}

// ---------------------------------------------------------------------------
// Landmark mapping
// ---------------------------------------------------------------------------

/// Maps each [JointLandmark] to the [sdk.LandmarkType] index used by the SDK.
sdk.LandmarkType _toSdkLandmarkType(JointLandmark joint) {
  return switch (joint) {
    JointLandmark.nose => sdk.LandmarkType.nose,
    JointLandmark.leftShoulder => sdk.LandmarkType.leftShoulder,
    JointLandmark.rightShoulder => sdk.LandmarkType.rightShoulder,
    JointLandmark.leftElbow => sdk.LandmarkType.leftElbow,
    JointLandmark.rightElbow => sdk.LandmarkType.rightElbow,
    JointLandmark.leftWrist => sdk.LandmarkType.leftWrist,
    JointLandmark.rightWrist => sdk.LandmarkType.rightWrist,
    JointLandmark.leftHip => sdk.LandmarkType.leftHip,
    JointLandmark.rightHip => sdk.LandmarkType.rightHip,
    JointLandmark.leftKnee => sdk.LandmarkType.leftKnee,
    JointLandmark.rightKnee => sdk.LandmarkType.rightKnee,
    JointLandmark.leftAnkle => sdk.LandmarkType.leftAnkle,
    JointLandmark.rightAnkle => sdk.LandmarkType.rightAnkle,
    JointLandmark.leftHeel => sdk.LandmarkType.leftHeel,
    JointLandmark.rightHeel => sdk.LandmarkType.rightHeel,
    JointLandmark.leftFootIndex => sdk.LandmarkType.leftFootIndex,
    JointLandmark.rightFootIndex => sdk.LandmarkType.rightFootIndex,
  };
}

/// Converts an [sdk.PoseResult] into a domain [PoseFrame].
///
/// Returns null when no pose was detected in the result.
PoseFrame? _toDomainFrame(sdk.PoseResult result, Duration timestamp) {
  if (!result.hasPoses) return null;

  final sdkPose = result.firstPose!;
  final landmarks = <PoseLandmark>[];

  for (final joint in JointLandmark.values) {
    final sdkLandmark = sdkPose.getLandmark(_toSdkLandmarkType(joint));
    landmarks.add(
      PoseLandmark(
        joint: joint,
        x: sdkLandmark.x,
        y: sdkLandmark.y,
        z: sdkLandmark.z,
        visibility: sdkLandmark.visibility,
      ),
    );
  }

  return PoseFrame(timestamp: timestamp, landmarks: landmarks);
}

// ---------------------------------------------------------------------------
// Service implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [PoseEstimationService] backed by the
/// `flutter_pose_detection` package (MediaPipe BlazePose, 33 landmarks).
///
/// All inference runs on-device — no network calls.
class FlutterPoseEstimationService implements PoseEstimationService {
  final PoseDetectorAdapter _adapter;
  bool _initialised = false;

  FlutterPoseEstimationService({PoseDetectorAdapter? adapter})
      : _adapter = adapter ?? DefaultPoseDetectorAdapter();

  Future<void> _ensureInitialised() async {
    if (_initialised) return;
    await _adapter.initialize();
    _initialised = true;
  }

  @override
  Future<PoseFrame?> analyzeFrame(
    List<int> imageBytes, {
    InferenceMode mode = InferenceMode.gpu,
  }) async {
    await _ensureInitialised();
    final result = await _adapter.detectPose(Uint8List.fromList(imageBytes));
    return _toDomainFrame(result, Duration.zero);
  }

  @override
  Future<PoseAnalysisResult> analyzeVideo(
    String videoPath, {
    InferenceMode mode = InferenceMode.npu,
    void Function(double progress)? onProgress,
  }) async {
    await _ensureInitialised();

    try {
      final sdkResult = await _adapter.analyzeVideo(videoPath);

      final domainFrames = <PoseFrame>[];
      final totalFrames = sdkResult.frames.length;

      for (int i = 0; i < totalFrames; i++) {
        final videoFrame = sdkResult.frames[i];
        final timestamp = Duration(
          microseconds:
              (videoFrame.timestampSeconds * Duration.microsecondsPerSecond)
                  .round(),
        );
        final frame = _toDomainFrame(videoFrame.result, timestamp);
        if (frame != null) domainFrames.add(frame);
        onProgress?.call((i + 1) / totalFrames);
      }

      return PoseAnalysisResult(
        frames: domainFrames,
        totalFramesProcessed: sdkResult.analyzedFrames,
      );
    } catch (e) {
      throw PoseEstimationException('Video analysis failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _adapter.dispose();
    _initialised = false;
  }
}
