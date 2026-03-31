import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/nutrition_target.dart';
import '../repositories/nutrition_target_repository.dart';
import 'save_nutrition_target.dart';

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
  late SaveNutritionTarget useCase;

  setUpAll(() {
    registerFallbackValue(_target());
  });

  setUp(() {
    mockRepo = MockNutritionTargetRepository();
    useCase = SaveNutritionTarget(mockRepo);
  });

  group('SaveNutritionTarget', () {
    test('returns saved target on success', () async {
      final target = _target();
      when(() => mockRepo.saveTarget(any()))
          .thenAnswer((_) async => Right(target));

      final result = await useCase(target);

      expect(result, Right<AppFailure, NutritionTarget>(target));
      verify(() => mockRepo.saveTarget(target)).called(1);
    });

    test('returns failure on error', () async {
      when(() => mockRepo.saveTarget(any()))
          .thenAnswer((_) async => const Left(ServerFailure('save failed')));

      final result = await useCase(_target());

      expect(result.isLeft(), true);
    });
  });
}
