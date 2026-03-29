import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/domain/usecases/create_assessment.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late MockAssessmentRepository mockRepo;
  late CreateAssessment createAssessment;

  final tAssessment = Assessment(
    id: 'assessment_1',
    userId: 'user_1',
    date: DateTime(2026, 3, 29),
    answers: const {'occupation': 'desk', 'neckPain': true},
    compensationResults: const [
      CompensationPattern.forwardHeadPosture,
      CompensationPattern.roundedShoulders,
    ],
    movementScores: const [],
    overallScore: 7.0,
  );

  setUp(() {
    mockRepo = MockAssessmentRepository();
    createAssessment = CreateAssessment(mockRepo);
  });

  group('CreateAssessment', () {
    test('returns Assessment on success', () async {
      when(() => mockRepo.createAssessment(tAssessment))
          .thenAnswer((_) async => Right(tAssessment));

      final result = await createAssessment(tAssessment);

      expect(result, Right(tAssessment));
      verify(() => mockRepo.createAssessment(tAssessment)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.createAssessment(tAssessment))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await createAssessment(tAssessment);

      expect(result.isLeft(), true);
    });
  });
}
