import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/entities/assessment_comparison_result.dart';
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';
import 'package:way2move/features/assessments/domain/entities/video_analysis.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/domain/repositories/video_analysis_repository.dart';
import 'package:way2move/features/assessments/domain/usecases/get_assessment_comparison.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

class MockVideoAnalysisRepository extends Mock
    implements VideoAnalysisRepository {}

void main() {
  late MockAssessmentRepository mockAssessmentRepo;
  late MockVideoAnalysisRepository mockVideoRepo;
  late GetAssessmentComparison useCase;

  final earlierDate = DateTime(2024, 1, 1);
  final laterDate = DateTime(2024, 6, 1);

  final assessmentA = Assessment(
    id: 'assessA',
    userId: 'user1',
    date: earlierDate,
    answers: {},
    compensationResults: [CompensationPattern.kneeValgus],
    movementScores: [],
    overallScore: 6,
  );

  final assessmentB = Assessment(
    id: 'assessB',
    userId: 'user1',
    date: laterDate,
    answers: {},
    compensationResults: [],
    movementScores: [],
    overallScore: 8,
  );

  final videoA = VideoAnalysis(
    id: 'va1',
    assessmentId: 'assessA',
    userId: 'user1',
    movement: ScreeningMovement.overheadSquat,
    frames: [],
    detectedCompensations: [CompensationPattern.kneeValgus],
    analyzedAt: earlierDate,
  );

  final videoB = VideoAnalysis(
    id: 'vb1',
    assessmentId: 'assessB',
    userId: 'user1',
    movement: ScreeningMovement.overheadSquat,
    frames: [],
    detectedCompensations: [],
    analyzedAt: laterDate,
  );

  setUp(() {
    mockAssessmentRepo = MockAssessmentRepository();
    mockVideoRepo = MockVideoAnalysisRepository();
    useCase = GetAssessmentComparison(mockAssessmentRepo, mockVideoRepo);
  });

  group('GetAssessmentComparison', () {
    test('returns comparison result with earlier date as initial', () async {
      when(() => mockAssessmentRepo.getAssessmentById('assessA'))
          .thenAnswer((_) async => Right(assessmentA));
      when(() => mockAssessmentRepo.getAssessmentById('assessB'))
          .thenAnswer((_) async => Right(assessmentB));
      when(() => mockVideoRepo.getByAssessment('assessA'))
          .thenAnswer((_) async => Right([videoA]));
      when(() => mockVideoRepo.getByAssessment('assessB'))
          .thenAnswer((_) async => Right([videoB]));

      final result = await useCase(const GetAssessmentComparisonInput(
        firstAssessmentId: 'assessA',
        secondAssessmentId: 'assessB',
      ));

      expect(result.isRight(), true);
      final comparison = result.getRight().toNullable()!;
      expect(comparison.initial.assessmentId, 'assessA');
      expect(comparison.reAssessment.assessmentId, 'assessB');
    });

    test('swaps order so earlier date is always initial', () async {
      // Pass B first (later date) and A second (earlier date)
      when(() => mockAssessmentRepo.getAssessmentById('assessB'))
          .thenAnswer((_) async => Right(assessmentB));
      when(() => mockAssessmentRepo.getAssessmentById('assessA'))
          .thenAnswer((_) async => Right(assessmentA));
      when(() => mockVideoRepo.getByAssessment('assessB'))
          .thenAnswer((_) async => Right([videoB]));
      when(() => mockVideoRepo.getByAssessment('assessA'))
          .thenAnswer((_) async => Right([videoA]));

      final result = await useCase(const GetAssessmentComparisonInput(
        firstAssessmentId: 'assessB',
        secondAssessmentId: 'assessA',
      ));

      expect(result.isRight(), true);
      final comparison = result.getRight().toNullable()!;
      // A has the earlier date, so it should always be initial
      expect(comparison.initial.assessmentId, 'assessA');
      expect(comparison.reAssessment.assessmentId, 'assessB');
    });

    test('returns NotFoundFailure when first assessment is not found',
        () async {
      when(() => mockAssessmentRepo.getAssessmentById('missing'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));
      when(() => mockAssessmentRepo.getAssessmentById('assessB'))
          .thenAnswer((_) async => Right(assessmentB));

      final result = await useCase(const GetAssessmentComparisonInput(
        firstAssessmentId: 'missing',
        secondAssessmentId: 'assessB',
      ));

      expect(result.isLeft(), true);
      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('returns failure when second assessment is not found', () async {
      when(() => mockAssessmentRepo.getAssessmentById('assessA'))
          .thenAnswer((_) async => Right(assessmentA));
      when(() => mockAssessmentRepo.getAssessmentById('missing'))
          .thenAnswer((_) async => const Left(NotFoundFailure()));

      final result = await useCase(const GetAssessmentComparisonInput(
        firstAssessmentId: 'assessA',
        secondAssessmentId: 'missing',
      ));

      expect(result.isLeft(), true);
    });

    test('returns ServerFailure when video fetch fails', () async {
      when(() => mockAssessmentRepo.getAssessmentById('assessA'))
          .thenAnswer((_) async => Right(assessmentA));
      when(() => mockAssessmentRepo.getAssessmentById('assessB'))
          .thenAnswer((_) async => Right(assessmentB));
      when(() => mockVideoRepo.getByAssessment('assessA'))
          .thenAnswer((_) async => const Left(ServerFailure()));
      when(() => mockVideoRepo.getByAssessment('assessB'))
          .thenAnswer((_) async => Right([videoB]));

      final result = await useCase(const GetAssessmentComparisonInput(
        firstAssessmentId: 'assessA',
        secondAssessmentId: 'assessB',
      ));

      expect(result.isLeft(), true);
    });

    test('compensationChanges detects resolved pattern', () async {
      when(() => mockAssessmentRepo.getAssessmentById('assessA'))
          .thenAnswer((_) async => Right(assessmentA));
      when(() => mockAssessmentRepo.getAssessmentById('assessB'))
          .thenAnswer((_) async => Right(assessmentB));
      when(() => mockVideoRepo.getByAssessment('assessA'))
          .thenAnswer((_) async => Right([videoA]));
      when(() => mockVideoRepo.getByAssessment('assessB'))
          .thenAnswer((_) async => Right([videoB]));

      final result = await useCase(const GetAssessmentComparisonInput(
        firstAssessmentId: 'assessA',
        secondAssessmentId: 'assessB',
      ));

      final comparison = result.getRight().toNullable()!;
      final changes = comparison.compensationChanges;
      // kneeValgus was in assessA but not assessB → resolved or improved
      final kneeChange = changes.firstWhere(
        (c) => c.pattern == CompensationPattern.kneeValgus,
        orElse: () => throw StateError('kneeValgus not in changes'),
      );
      expect(
        kneeChange.changeType == CompensationChangeType.resolved ||
            kneeChange.changeType == CompensationChangeType.improved,
        true,
      );
    });

    test('CompensationChangeType is resolved when afterSeverity is null', () {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.moderate,
        afterSeverity: null,
      );
      expect(change.changeType, CompensationChangeType.resolved);
    });

    test('CompensationChangeType is newlyDetected when beforeSeverity is null',
        () {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: null,
        afterSeverity: CompensationSeverity.mild,
      );
      expect(change.changeType, CompensationChangeType.newlyDetected);
    });

    test('CompensationChangeType is improved when severity reduces', () {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.significant,
        afterSeverity: CompensationSeverity.mild,
      );
      expect(change.changeType, CompensationChangeType.improved);
    });

    test('CompensationChangeType is worsened when severity increases', () {
      const change = CompensationChange(
        pattern: CompensationPattern.kneeValgus,
        beforeSeverity: CompensationSeverity.mild,
        afterSeverity: CompensationSeverity.significant,
      );
      expect(change.changeType, CompensationChangeType.worsened);
    });
  });
}
