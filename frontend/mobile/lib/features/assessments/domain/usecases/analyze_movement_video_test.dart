import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/assessment.dart';
import '../entities/pose_frame.dart';
import '../entities/pose_landmark.dart';
import '../entities/video_analysis.dart';
import '../repositories/video_analysis_repository.dart';
import '../services/pose_estimation_service.dart';
import 'analyze_movement_video.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

class MockVideoAnalysisRepository extends Mock
    implements VideoAnalysisRepository {}

class MockPoseEstimationService extends Mock implements PoseEstimationService {}

// ── Helpers ──────────────────────────────────────────────────────────────────

PoseFrame _frame(Duration ts) => PoseFrame(
      timestamp: ts,
      landmarks: [
        const PoseLandmark(
          joint: JointLandmark.leftKnee,
          x: 0.5,
          y: 0.7,
          z: 0.0,
          visibility: 0.9,
        ),
      ],
    );

VideoAnalysis _analysis({
  String id = 'vid1',
  List<PoseFrame>? frames,
  List<CompensationPattern>? compensations,
}) =>
    VideoAnalysis(
      id: id,
      assessmentId: 'assess1',
      userId: 'user1',
      movement: ScreeningMovement.overheadSquat,
      frames: frames ?? [_frame(Duration.zero)],
      detectedCompensations: compensations ?? [],
      analyzedAt: DateTime(2026),
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockVideoAnalysisRepository mockRepo;
  late MockPoseEstimationService mockPoseService;
  late AnalyzeMovementVideo useCase;

  setUp(() {
    mockRepo = MockVideoAnalysisRepository();
    mockPoseService = MockPoseEstimationService();
    useCase = AnalyzeMovementVideo(mockRepo, mockPoseService);
  });

  setUpAll(() {
    registerFallbackValue(
      VideoAnalysis(
        id: '',
        assessmentId: '',
        userId: '',
        movement: ScreeningMovement.overheadSquat,
        frames: const [],
        detectedCompensations: const [],
        analyzedAt: DateTime(2026),
      ),
    );
    registerFallbackValue(InferenceMode.npu);
    // ignore: prefer_function_declarations_over_variables
    final void Function(double) progressFn = (double _) {};
    registerFallbackValue(progressFn);
  });

  group('AnalyzeMovementVideo', () {
    test('calls analyzeVideo on the pose service with the given path',
        () async {
      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => PoseAnalysisResult(
            frames: [_frame(Duration.zero)],
            totalFramesProcessed: 10,
          ));
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => Right(_analysis()));
      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async =>
          const Right('users/user1/assessments/assess1/overheadSquat.mp4'));

      await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      verify(() => mockPoseService.analyzeVideo(
            '/tmp/squat.mp4',
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).called(1);
    });

    test('saves VideoAnalysis with extracted frames and assessment linkage',
        () async {
      final frames = [
        _frame(const Duration(milliseconds: 100)),
        _frame(const Duration(milliseconds: 200)),
      ];
      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async =>
          PoseAnalysisResult(frames: frames, totalFramesProcessed: 20));
      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => const Right('path/video.mp4'));

      VideoAnalysis? savedAnalysis;
      when(() => mockRepo.save(any())).thenAnswer((inv) async {
        savedAnalysis = inv.positionalArguments[0] as VideoAnalysis;
        return Right(_analysis(frames: frames));
      });

      await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      expect(savedAnalysis, isNotNull);
      expect(savedAnalysis!.assessmentId, 'assess1');
      expect(savedAnalysis!.userId, 'user1');
      expect(savedAnalysis!.movement, ScreeningMovement.overheadSquat);
      expect(savedAnalysis!.frames.length, 2);
    });

    test('returns Right with saved VideoAnalysis on success', () async {
      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async =>
          PoseAnalysisResult(frames: [], totalFramesProcessed: 5));
      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => const Right('path/video.mp4'));
      final saved = _analysis();
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => Right(saved));

      final result = await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      expect(result.isRight(), true);
      expect(result.getRight().toNullable(), saved);
    });

    test('returns Left(ServerFailure) when upload fails', () async {
      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async =>
          PoseAnalysisResult(frames: [], totalFramesProcessed: 1));
      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => const Left(ServerFailure('upload-failed')));

      final result = await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      expect(result.isLeft(), true);
      verifyNever(() => mockRepo.save(any()));
    });

    test('returns Left(ServerFailure) when save fails', () async {
      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async =>
          PoseAnalysisResult(frames: [], totalFramesProcessed: 1));
      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => const Right('path/video.mp4'));
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      expect(result.isLeft(), true);
    });

    test('returns Left when pose estimation throws PoseEstimationException',
        () async {
      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenThrow(const PoseEstimationException('GPU crashed'));
      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => const Right('path/video.mp4'));

      final result = await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      expect(result.isLeft(), true);
    });

    test('uploads video before analyzing pose', () async {
      final callOrder = <String>[];

      when(() => mockRepo.uploadVideo(
            localPath: any(named: 'localPath'),
            userId: any(named: 'userId'),
            assessmentId: any(named: 'assessmentId'),
            movementName: any(named: 'movementName'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async {
        callOrder.add('upload');
        return const Right('path/video.mp4');
      });

      when(() => mockPoseService.analyzeVideo(
            any(),
            mode: any(named: 'mode'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async {
        callOrder.add('analyze');
        return PoseAnalysisResult(frames: [], totalFramesProcessed: 1);
      });

      when(() => mockRepo.save(any())).thenAnswer((_) async {
        callOrder.add('save');
        return Right(_analysis());
      });

      await useCase(
        AnalyzeMovementVideoInput(
          localVideoPath: '/tmp/squat.mp4',
          assessmentId: 'assess1',
          userId: 'user1',
          movement: ScreeningMovement.overheadSquat,
        ),
      );

      expect(callOrder, ['upload', 'analyze', 'save']);
    });
  });
}
