import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/repositories/assessment_repository.dart';
import 'package:way2move/features/assessments/domain/usecases/log_weekly_pulse.dart';

class MockAssessmentRepository extends Mock implements AssessmentRepository {}

void main() {
  late MockAssessmentRepository mockRepo;
  late LogWeeklyPulse logWeeklyPulse;

  final tPulse = WeeklyPulse(
    id: 'pulse_1',
    userId: 'user_1',
    date: DateTime(2026, 3, 29),
    energyScore: 4,
    sorenessScore: 3,
    motivationScore: 5,
    sleepQualityScore: 4,
  );

  setUp(() {
    mockRepo = MockAssessmentRepository();
    logWeeklyPulse = LogWeeklyPulse(mockRepo);
  });

  group('LogWeeklyPulse', () {
    test('returns WeeklyPulse on success', () async {
      when(() => mockRepo.logWeeklyPulse(tPulse))
          .thenAnswer((_) async => Right(tPulse));

      final result = await logWeeklyPulse(tPulse);

      expect(result, Right(tPulse));
      verify(() => mockRepo.logWeeklyPulse(tPulse)).called(1);
    });

    test('returns ServerFailure on error', () async {
      when(() => mockRepo.logWeeklyPulse(tPulse))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await logWeeklyPulse(tPulse);

      expect(result.isLeft(), true);
    });

    test('composite score averages four scores', () {
      expect(tPulse.compositeScore, closeTo(4.0, 0.01));
    });
  });
}
