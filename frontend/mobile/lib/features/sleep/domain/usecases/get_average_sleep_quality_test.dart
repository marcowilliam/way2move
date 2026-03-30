import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/sleep/domain/repositories/sleep_repository.dart';
import 'package:way2move/features/sleep/domain/usecases/get_average_sleep_quality.dart';

class MockSleepRepository extends Mock implements SleepRepository {}

void main() {
  late MockSleepRepository mockRepo;
  late GetAverageSleepQuality getAverageSleepQuality;

  setUp(() {
    mockRepo = MockSleepRepository();
    getAverageSleepQuality = GetAverageSleepQuality(mockRepo);
  });

  group('GetAverageSleepQuality', () {
    test('returns average quality value on success', () async {
      when(() => mockRepo.getAverageSleepQuality('u1', 7))
          .thenAnswer((_) async => const Right(3.5));

      final result = await getAverageSleepQuality('u1', 7);

      expect(result, const Right(3.5));
      verify(() => mockRepo.getAverageSleepQuality('u1', 7)).called(1);
    });

    test('returns 0.0 when no logs exist', () async {
      when(() => mockRepo.getAverageSleepQuality('u1', 30))
          .thenAnswer((_) async => const Right(0.0));

      final result = await getAverageSleepQuality('u1', 30);

      expect(result, const Right(0.0));
    });

    test('passes daysBack parameter correctly', () async {
      when(() => mockRepo.getAverageSleepQuality('u1', 14))
          .thenAnswer((_) async => const Right(4.2));

      final result = await getAverageSleepQuality('u1', 14);

      expect(result.isRight(), true);
      verify(() => mockRepo.getAverageSleepQuality('u1', 14)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.getAverageSleepQuality('u1', 7))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getAverageSleepQuality('u1', 7);

      expect(result.isLeft(), true);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
