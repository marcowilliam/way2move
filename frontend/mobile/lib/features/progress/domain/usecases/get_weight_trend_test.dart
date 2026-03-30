import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progress/domain/entities/weight_log.dart';
import 'package:way2move/features/progress/domain/repositories/weight_log_repository.dart';
import 'package:way2move/features/progress/domain/usecases/get_weight_trend.dart';

class MockWeightLogRepository extends Mock implements WeightLogRepository {}

void main() {
  late MockWeightLogRepository mockRepo;
  late GetWeightTrend getWeightTrend;

  final tLogs = [
    WeightLog(
      id: 'log1',
      userId: 'user1',
      date: DateTime(2026, 3, 29),
      weight: 75.5,
      unit: WeightUnit.kg,
    ),
    WeightLog(
      id: 'log2',
      userId: 'user1',
      date: DateTime(2026, 3, 28),
      weight: 75.8,
      unit: WeightUnit.kg,
    ),
    WeightLog(
      id: 'log3',
      userId: 'user1',
      date: DateTime(2026, 3, 27),
      weight: 76.0,
      unit: WeightUnit.kg,
    ),
  ];

  setUp(() {
    mockRepo = MockWeightLogRepository();
    getWeightTrend = GetWeightTrend(mockRepo);
  });

  group('GetWeightTrend', () {
    test('returns list of weight logs for given days back', () async {
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => Right(tLogs));

      final result = await getWeightTrend('user1', 30);

      expect(result, Right(tLogs));
      verify(() => mockRepo.getTrend('user1', 30)).called(1);
    });

    test('returns empty list when no logs in range', () async {
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Right([]));

      final result = await getWeightTrend('user1', 7);

      expect(result, const Right(<WeightLog>[]));
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getWeightTrend('user1', 30);

      expect(result.isLeft(), true);
    });

    test('passes correct daysBack to repository', () async {
      when(() => mockRepo.getTrend(any(), any()))
          .thenAnswer((_) async => Right(tLogs));

      await getWeightTrend('user1', 7);

      verify(() => mockRepo.getTrend('user1', 7)).called(1);
    });
  });
}
