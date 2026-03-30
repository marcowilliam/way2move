import 'dart:typed_data';

import 'package:flutter_pose_detection/flutter_pose_detection.dart'
    as sdk
    show
        PoseResult,
        Pose,
        PoseLandmark,
        LandmarkType,
        VideoAnalysisResult,
        VideoFrameResult,
        AccelerationMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../domain/entities/pose_landmark.dart';
import '../../domain/services/pose_estimation_service.dart';
import 'flutter_pose_estimation_service.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockPoseDetectorAdapter extends Mock implements PoseDetectorAdapter {}

// ---------------------------------------------------------------------------
// SDK test-object builders
// ---------------------------------------------------------------------------

/// Builds an [sdk.PoseLandmark] with given coordinates at [type].
sdk.PoseLandmark _sdkLm(
  sdk.LandmarkType type, {
  double x = 0.5,
  double y = 0.5,
  double z = 0.0,
  double visibility = 0.9,
}) =>
    sdk.PoseLandmark(
      type: type,
      x: x,
      y: y,
      z: z,
      visibility: visibility,
    );

/// Builds an [sdk.Pose] with all 33 landmarks set to default values.
/// Each landmark at [overrides] will have custom coords/visibility.
sdk.Pose _sdkPose({
  Map<sdk.LandmarkType, sdk.PoseLandmark> overrides = const {},
}) {
  final landmarks = List.generate(sdk.LandmarkType.values.length, (i) {
    final type = sdk.LandmarkType.values[i];
    return overrides[type] ?? _sdkLm(type);
  });
  return sdk.Pose(landmarks: landmarks, score: 0.95);
}

/// [sdk.PoseResult] with [poses] list.
sdk.PoseResult _sdkPoseResult({List<sdk.Pose> poses = const []}) =>
    sdk.PoseResult(
      poses: poses,
      processingTimeMs: 5,
      accelerationMode: sdk.AccelerationMode.gpu,
      timestamp: DateTime(2026),
      imageWidth: 640,
      imageHeight: 480,
    );

/// A single-frame [sdk.VideoAnalysisResult] with optional pose at the frame.
sdk.VideoAnalysisResult _sdkVideoResult(List<sdk.PoseResult> frameResults) {
  final frames = frameResults.asMap().entries.map((entry) {
    return sdk.VideoFrameResult(
      frameIndex: entry.key,
      timestampSeconds: entry.key * 0.1,
      result: entry.value,
    );
  }).toList();

  return sdk.VideoAnalysisResult(
    frames: frames,
    totalFrames: frameResults.length,
    analyzedFrames: frameResults.length,
    durationSeconds: frameResults.length * 0.1,
    frameRate: 10,
    width: 640,
    height: 480,
    totalAnalysisTimeMs: frameResults.length * 15,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockPoseDetectorAdapter mockAdapter;
  late FlutterPoseEstimationService service;

  setUp(() {
    mockAdapter = MockPoseDetectorAdapter();
    when(() => mockAdapter.initialize())
        .thenAnswer((_) async => sdk.AccelerationMode.gpu);
    service = FlutterPoseEstimationService(adapter: mockAdapter);
  });

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  // -------------------------------------------------------------------------
  // analyzeFrame
  // -------------------------------------------------------------------------

  group('analyzeFrame', () {
    test('returns null when no pose is detected', () async {
      when(() => mockAdapter.detectPose(any()))
          .thenAnswer((_) async => _sdkPoseResult());

      final frame = await service.analyzeFrame([1, 2, 3]);

      expect(frame, isNull);
    });

    test('returns a PoseFrame when a pose is detected', () async {
      when(() => mockAdapter.detectPose(any()))
          .thenAnswer((_) async => _sdkPoseResult(poses: [_sdkPose()]));

      final frame = await service.analyzeFrame([1, 2, 3]);

      expect(frame, isNotNull);
      expect(frame!.landmarks, isNotEmpty);
    });

    test('maps all JointLandmark joints into the returned frame', () async {
      when(() => mockAdapter.detectPose(any()))
          .thenAnswer((_) async => _sdkPoseResult(poses: [_sdkPose()]));

      final frame = await service.analyzeFrame([1, 2, 3]);

      expect(frame!.landmarks.length, equals(JointLandmark.values.length));
      for (final joint in JointLandmark.values) {
        expect(frame.landmarkFor(joint), isNotNull,
            reason: '${joint.name} must be present');
      }
    });

    test('preserves SDK landmark coordinates in domain PoseLandmark', () async {
      final kneeOverride = _sdkLm(
        sdk.LandmarkType.leftKnee,
        x: 0.3,
        y: 0.7,
        z: -0.05,
        visibility: 0.85,
      );
      when(() => mockAdapter.detectPose(any())).thenAnswer(
        (_) async => _sdkPoseResult(
          poses: [
            _sdkPose(overrides: {sdk.LandmarkType.leftKnee: kneeOverride}),
          ],
        ),
      );

      final frame = await service.analyzeFrame([1]);

      final knee = frame!.landmarkFor(JointLandmark.leftKnee)!;
      expect(knee.x, closeTo(0.3, 0.001));
      expect(knee.y, closeTo(0.7, 0.001));
      expect(knee.z, closeTo(-0.05, 0.001));
      expect(knee.visibility, closeTo(0.85, 0.001));
    });

    test('landmark with visibility < 0.5 is not considered visible', () async {
      final hidden = _sdkLm(
        sdk.LandmarkType.leftKnee,
        visibility: 0.3,
      );
      when(() => mockAdapter.detectPose(any())).thenAnswer(
        (_) async => _sdkPoseResult(
          poses: [_sdkPose(overrides: {sdk.LandmarkType.leftKnee: hidden})],
        ),
      );

      final frame = await service.analyzeFrame([1]);
      final knee = frame!.landmarkFor(JointLandmark.leftKnee)!;

      expect(knee.isVisible, isFalse);
    });

    test('calls initialize only once across multiple calls', () async {
      when(() => mockAdapter.detectPose(any()))
          .thenAnswer((_) async => _sdkPoseResult());

      await service.analyzeFrame([1]);
      await service.analyzeFrame([2]);
      await service.analyzeFrame([3]);

      verify(() => mockAdapter.initialize()).called(1);
    });

    test('passes image bytes directly to the adapter', () async {
      final capturedBytes = <Uint8List>[];
      when(() => mockAdapter.detectPose(any())).thenAnswer((invocation) async {
        capturedBytes.add(invocation.positionalArguments[0] as Uint8List);
        return _sdkPoseResult();
      });

      await service.analyzeFrame([10, 20, 30]);

      expect(capturedBytes.single, equals(Uint8List.fromList([10, 20, 30])));
    });
  });

  // -------------------------------------------------------------------------
  // analyzeVideo
  // -------------------------------------------------------------------------

  group('analyzeVideo', () {
    setUp(() {
      registerFallbackValue('');
    });

    test('returns empty frames when video has no detected poses', () async {
      when(() => mockAdapter.analyzeVideo(any(), frameInterval: any(named: 'frameInterval')))
          .thenAnswer(
              (_) async => _sdkVideoResult([_sdkPoseResult(), _sdkPoseResult()]));

      final result = await service.analyzeVideo('/test.mp4');

      expect(result.frames, isEmpty);
      expect(result.totalFramesProcessed, equals(2));
      expect(result.detectionRate, equals(0.0));
    });

    test('returns one domain frame per detected SDK frame', () async {
      when(() => mockAdapter.analyzeVideo(any(), frameInterval: any(named: 'frameInterval')))
          .thenAnswer(
        (_) async => _sdkVideoResult([
          _sdkPoseResult(poses: [_sdkPose()]),
          _sdkPoseResult(), // no pose
          _sdkPoseResult(poses: [_sdkPose()]),
        ]),
      );

      final result = await service.analyzeVideo('/test.mp4');

      expect(result.frames.length, equals(2));
      expect(result.totalFramesProcessed, equals(3));
      expect(result.detectionRate, closeTo(2 / 3, 0.001));
    });

    test('frame timestamps are derived from SDK timestampSeconds', () async {
      when(() => mockAdapter.analyzeVideo(any(), frameInterval: any(named: 'frameInterval')))
          .thenAnswer(
        (_) async => _sdkVideoResult([
          _sdkPoseResult(poses: [_sdkPose()]),
        ]),
      );

      final result = await service.analyzeVideo('/test.mp4');

      // First frame has timestampSeconds = 0 * 0.1 = 0.0
      expect(result.frames.first.timestamp, equals(Duration.zero));
    });

    test('reports progress from first to last frame', () async {
      when(() => mockAdapter.analyzeVideo(any(), frameInterval: any(named: 'frameInterval')))
          .thenAnswer(
        (_) async => _sdkVideoResult(
          List.generate(4, (_) => _sdkPoseResult()),
        ),
      );

      final progressValues = <double>[];
      await service.analyzeVideo('/test.mp4', onProgress: progressValues.add);

      expect(progressValues, equals([0.25, 0.5, 0.75, 1.0]));
    });

    test('wraps SDK exceptions in PoseEstimationException', () async {
      when(() => mockAdapter.analyzeVideo(any(), frameInterval: any(named: 'frameInterval')))
          .thenThrow(Exception('hardware error'));

      expect(
        () => service.analyzeVideo('/bad.mp4'),
        throwsA(isA<PoseEstimationException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose', () {
    test('calls dispose on the adapter', () async {
      when(() => mockAdapter.dispose()).thenReturn(null);

      await service.dispose();

      verify(() => mockAdapter.dispose()).called(1);
    });

    test('allows re-initialization after dispose', () async {
      when(() => mockAdapter.detectPose(any()))
          .thenAnswer((_) async => _sdkPoseResult());
      when(() => mockAdapter.dispose()).thenReturn(null);

      await service.analyzeFrame([1]);
      await service.dispose();
      await service.analyzeFrame([2]);

      // initialize should be called twice: once before first use, once after dispose
      verify(() => mockAdapter.initialize()).called(2);
    });
  });
}
