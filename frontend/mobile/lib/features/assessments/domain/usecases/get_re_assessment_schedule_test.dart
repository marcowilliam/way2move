import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/re_assessment_schedule.dart';
import '../repositories/re_assessment_schedule_repository.dart';
import 'get_re_assessment_schedule.dart';

class MockReAssessmentScheduleRepository extends Mock
    implements ReAssessmentScheduleRepository {}

void main() {
  late MockReAssessmentScheduleRepository mockRepo;
  late GetReAssessmentSchedule useCase;

  setUp(() {
    mockRepo = MockReAssessmentScheduleRepository();
    useCase = GetReAssessmentSchedule(mockRepo);
  });

  group('GetReAssessmentSchedule', () {
    const userId = 'user123';
    final schedule = ReAssessmentSchedule(
      id: 'user123',
      userId: userId,
      nextAssessmentDate: DateTime(2026, 4, 28),
      intervalWeeks: 4,
    );

    test('returns schedule when repo succeeds', () async {
      when(() => mockRepo.getSchedule(userId))
          .thenAnswer((_) async => Right(schedule));

      final result = await useCase(userId);

      expect(result, Right<AppFailure, ReAssessmentSchedule?>(schedule));
      verify(() => mockRepo.getSchedule(userId)).called(1);
    });

    test('returns null when no schedule exists', () async {
      when(() => mockRepo.getSchedule(userId))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(userId);

      expect(result, const Right<AppFailure, ReAssessmentSchedule?>(null));
    });

    test('returns ServerFailure when repo fails', () async {
      when(() => mockRepo.getSchedule(userId)).thenAnswer(
          (_) async => const Left(ServerFailure('firestore-error')));

      final result = await useCase(userId);

      expect(result.isLeft(), true);
    });
  });
}
