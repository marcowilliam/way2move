import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/nutrition_target.dart';
import '../repositories/nutrition_target_repository.dart';
import 'get_nutrition_target.dart';

class MockNutritionTargetRepository extends Mock
    implements NutritionTargetRepository {}

NutritionTarget _target() => NutritionTarget(
      userId: 'u1',
      preset: MacroPreset.maintenance,
      tdee: 2500,
      baseCalories: 2500,
      trainingDayCalories: 2875,
      restDayCalories: 2250,
      proteinGrams: 187,
      carbsGrams: 250,
      fatGrams: 83,
      updatedAt: DateTime(2024),
    );

void main() {
  late MockNutritionTargetRepository mockRepo;
  late GetNutritionTarget useCase;

  setUp(() {
    mockRepo = MockNutritionTargetRepository();
    useCase = GetNutritionTarget(mockRepo);
  });

  group('GetNutritionTarget', () {
    test('returns target when found', () async {
      final target = _target();
      when(() => mockRepo.getTarget('u1'))
          .thenAnswer((_) async => Right(target));

      final result = await useCase('u1');

      expect(result, Right<AppFailure, NutritionTarget?>(target));
    });

    test('returns null when no target saved yet', () async {
      when(() => mockRepo.getTarget('u1'))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase('u1');

      expect(result, const Right<AppFailure, NutritionTarget?>(null));
    });

    test('returns failure on error', () async {
      when(() => mockRepo.getTarget('u1'))
          .thenAnswer((_) async => Left(ServerFailure('error')));

      final result = await useCase('u1');

      expect(result.isLeft(), true);
    });
  });
}
