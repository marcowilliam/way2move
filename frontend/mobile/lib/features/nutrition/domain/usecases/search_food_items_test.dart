import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/nutrition/data/services/food_database_service.dart';
import 'package:way2move/features/nutrition/domain/entities/food_item.dart';
import 'package:way2move/features/nutrition/domain/usecases/search_food_items.dart';

class MockFoodDatabaseService extends Mock implements FoodDatabaseService {}

void main() {
  late MockFoodDatabaseService mockService;
  late SearchFoodItems useCase;

  const tItem = FoodItem(
    name: 'Oats',
    portionGrams: 100,
    calories: 389,
    protein: 17,
    carbs: 66,
    fat: 7,
  );

  setUp(() {
    mockService = MockFoodDatabaseService();
    useCase = SearchFoodItems(mockService);
  });

  group('SearchFoodItems', () {
    test('returns Right with results for valid non-empty query', () async {
      when(() => mockService.search(any())).thenAnswer((_) async => [tItem]);

      final result = await useCase.call('oats');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (items) => expect(items, [tItem]),
      );
      verify(() => mockService.search('oats')).called(1);
    });

    test(
        'returns Right with empty list for empty query without calling service',
        () async {
      final result = await useCase.call('');

      expect(result.isRight(), true);
      result.fold(
          (_) => fail('Expected Right'), (items) => expect(items, isEmpty));
      verifyNever(() => mockService.search(any()));
    });

    test('returns Right with empty list for whitespace-only query', () async {
      final result = await useCase.call('   ');

      expect(result.isRight(), true);
      result.fold(
          (_) => fail('Expected Right'), (items) => expect(items, isEmpty));
      verifyNever(() => mockService.search(any()));
    });

    test('returns Left(NetworkFailure) when service throws', () async {
      when(() => mockService.search(any())).thenThrow(Exception('no internet'));

      final result = await useCase.call('oats');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('trims whitespace before calling service', () async {
      when(() => mockService.search(any())).thenAnswer((_) async => []);

      await useCase.call('  oats  ');

      verify(() => mockService.search('oats')).called(1);
    });

    test('returns Right with empty list when service returns empty', () async {
      when(() => mockService.search(any())).thenAnswer((_) async => []);

      final result = await useCase.call('xyz123notreal');

      expect(result.isRight(), true);
      result.fold(
          (_) => fail('Expected Right'), (items) => expect(items, isEmpty));
    });
  });
}
