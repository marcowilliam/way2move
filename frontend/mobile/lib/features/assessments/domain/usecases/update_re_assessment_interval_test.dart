import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/errors/app_failure.dart';
import '../repositories/re_assessment_schedule_repository.dart';
import 'update_re_assessment_interval.dart';

class MockReAssessmentScheduleRepository extends Mock
    implements ReAssessmentScheduleRepository {}

void main() {
  late MockReAssessmentScheduleRepository mockRepo;
  late UpdateReAssessmentInterval useCase;

  setUp(() {
    mockRepo = MockReAssessmentScheduleRepository();
    useCase = UpdateReAssessmentInterval(mockRepo);
  });

  group('UpdateReAssessmentInterval', () {
    const userId = 'user123';

    test('calls repo with valid interval', () async {
      when(() => mockRepo.updateInterval(userId, 4))
          .thenAnswer((_) async => const Right<AppFailure, void>(null));

      final result = await useCase(userId, 4);

      expect(result.isRight(), true);
      verify(() => mockRepo.updateInterval(userId, 4)).called(1);
    });

    test('accepts all valid interval options', () async {
      for (final weeks in [4, 6, 8, 12]) {
        when(() => mockRepo.updateInterval(userId, weeks))
            .thenAnswer((_) async => const Right<AppFailure, void>(null));

        final result = await useCase(userId, weeks);
        expect(result.isRight(), true, reason: '$weeks weeks should be valid');
      }
    });

    test('returns ValidationFailure for invalid interval', () async {
      final result = await useCase(userId, 5);

      expect(result.isLeft(), true);
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      verifyNever(() => mockRepo.updateInterval(any(), any()));
    });

    test('returns ServerFailure when repo fails', () async {
      when(() => mockRepo.updateInterval(userId, 6)).thenAnswer(
          (_) async => const Left(ServerFailure('firestore-error')));

      final result = await useCase(userId, 6);

      expect(result.isLeft(), true);
    });
  });
}
