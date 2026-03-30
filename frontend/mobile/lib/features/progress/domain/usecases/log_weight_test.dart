import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progress/domain/entities/weight_log.dart';
import 'package:way2move/features/progress/domain/repositories/weight_log_repository.dart';
import 'package:way2move/features/progress/domain/usecases/log_weight.dart';

class MockWeightLogRepository extends Mock implements WeightLogRepository {}

void main() {
  late MockWeightLogRepository mockRepo;
  late LogWeight logWeight;

  final tLog = WeightLog(
    id: 'log1',
    userId: 'user1',
    date: DateTime(2026, 3, 29),
    weight: 75.5,
    unit: WeightUnit.kg,
    notes: 'Morning weight',
  );

  setUp(() {
    mockRepo = MockWeightLogRepository();
    logWeight = LogWeight(mockRepo);
    registerFallbackValue(tLog);
  });

  group('LogWeight', () {
    test('returns WeightLog on success', () async {
      when(() => mockRepo.logWeight(any()))
          .thenAnswer((_) async => Right(tLog));

      final result = await logWeight(tLog);

      expect(result, Right(tLog));
      verify(() => mockRepo.logWeight(tLog)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.logWeight(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await logWeight(tLog);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('supports lbs unit', () async {
      final lbsLog = tLog.copyWith(unit: WeightUnit.lbs, weight: 166.4);
      when(() => mockRepo.logWeight(any()))
          .thenAnswer((_) async => Right(lbsLog));

      final result = await logWeight(lbsLog);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (log) => expect(log.unit, WeightUnit.lbs),
      );
    });

    test('supports weight without notes', () async {
      final noNotesLog = WeightLog(
        id: 'log2',
        userId: 'user1',
        date: DateTime(2026, 3, 29),
        weight: 80.0,
        unit: WeightUnit.kg,
      );
      when(() => mockRepo.logWeight(any()))
          .thenAnswer((_) async => Right(noNotesLog));

      final result = await logWeight(noNotesLog);

      expect(result.isRight(), true);
    });
  });
}
