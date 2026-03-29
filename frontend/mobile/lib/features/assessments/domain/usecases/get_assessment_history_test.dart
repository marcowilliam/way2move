import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/domain/usecases/get_assessment_history.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late MockAssessmentRepository mockRepo;
  late GetAssessmentHistory getAssessmentHistory;

  final tHistory = [
    Assessment(
      id: 'a1',
      userId: 'user_1',
      date: DateTime(2026, 3, 1),
      answers: const {},
      compensationResults: const [],
      movementScores: const [],
      overallScore: 8.0,
    ),
    Assessment(
      id: 'a2',
      userId: 'user_1',
      date: DateTime(2026, 3, 29),
      answers: const {},
      compensationResults: const [CompensationPattern.anteriorPelvicTilt],
      movementScores: const [],
      overallScore: 7.0,
    ),
  ];

  setUp(() {
    mockRepo = MockAssessmentRepository();
    getAssessmentHistory = GetAssessmentHistory(mockRepo);
  });

  group('GetAssessmentHistory', () {
    test('returns list of assessments in order', () async {
      when(() => mockRepo.getAssessmentHistory('user_1'))
          .thenAnswer((_) async => Right(tHistory));

      final result = await getAssessmentHistory('user_1');

      expect(result, Right(tHistory));
      verify(() => mockRepo.getAssessmentHistory('user_1')).called(1);
    });

    test('returns empty list when no assessments exist', () async {
      when(() => mockRepo.getAssessmentHistory('user_1'))
          .thenAnswer((_) async => const Right([]));

      final result = await getAssessmentHistory('user_1');

      expect(result, const Right(<Assessment>[]));
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.getAssessmentHistory('user_1'))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getAssessmentHistory('user_1');

      expect(result.isLeft(), true);
    });
  });
}
