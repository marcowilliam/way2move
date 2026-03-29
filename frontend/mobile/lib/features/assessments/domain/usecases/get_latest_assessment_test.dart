import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/domain/usecases/get_latest_assessment.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late MockAssessmentRepository mockRepo;
  late GetLatestAssessment getLatestAssessment;

  final tAssessment = Assessment(
    id: 'assessment_1',
    userId: 'user_1',
    date: DateTime(2026, 3, 29),
    answers: const {},
    compensationResults: const [],
    movementScores: const [],
    overallScore: 9.0,
  );

  setUp(() {
    mockRepo = MockAssessmentRepository();
    getLatestAssessment = GetLatestAssessment(mockRepo);
  });

  group('GetLatestAssessment', () {
    test('returns Assessment when one exists', () async {
      when(() => mockRepo.getLatestAssessment('user_1'))
          .thenAnswer((_) async => Right(tAssessment));

      final result = await getLatestAssessment('user_1');

      expect(result, Right(tAssessment));
      verify(() => mockRepo.getLatestAssessment('user_1')).called(1);
    });

    test('returns null when no assessment exists', () async {
      when(() => mockRepo.getLatestAssessment('user_1'))
          .thenAnswer((_) async => const Right(null));

      final result = await getLatestAssessment('user_1');

      expect(result, const Right(null));
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getLatestAssessment('user_1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getLatestAssessment('user_1');

      expect(result.isLeft(), true);
    });
  });
}
