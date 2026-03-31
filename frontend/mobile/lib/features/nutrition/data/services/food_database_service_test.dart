import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/nutrition/data/services/food_database_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late OpenFoodFactsService service;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = OpenFoodFactsService(client: mockClient);
  });

  Map<String, dynamic> makeResponse(List<Map<String, dynamic>> products) =>
      {'products': products};

  Map<String, dynamic> makeProduct({
    required String name,
    double? calories = 200.0,
    double? protein = 10.0,
    double? carbs = 30.0,
    double? fat = 5.0,
  }) =>
      {
        'product_name': name,
        'nutriments': {
          if (calories != null) 'energy-kcal_100g': calories,
          if (protein != null) 'proteins_100g': protein,
          if (carbs != null) 'carbohydrates_100g': carbs,
          if (fat != null) 'fat_100g': fat,
        },
      };

  void mockResponse(Map<String, dynamic> body, {int status = 200}) {
    when(() => mockClient.get(any(), headers: any(named: 'headers')))
        .thenAnswer(
      (_) async => http.Response(json.encode(body), status),
    );
  }

  group('OpenFoodFactsService.search', () {
    test('returns parsed FoodItems for valid products', () async {
      mockResponse(makeResponse([
        makeProduct(
            name: 'Oats', calories: 389, protein: 17, carbs: 66, fat: 7),
      ]));

      final result = await service.search('oats');

      expect(result.length, 1);
      expect(result.first.name, 'Oats');
      expect(result.first.calories, 389);
      expect(result.first.protein, 17);
      expect(result.first.carbs, 66);
      expect(result.first.fat, 7);
      expect(result.first.portionGrams, 100);
    });

    test('filters out products with empty name', () async {
      mockResponse(makeResponse([
        makeProduct(name: ''),
        makeProduct(name: 'Banana'),
      ]));

      final result = await service.search('banana');

      expect(result.length, 1);
      expect(result.first.name, 'Banana');
    });

    test('filters out products with missing nutriments', () async {
      mockResponse(makeResponse([
        {'product_name': 'Mystery food'},
        makeProduct(name: 'Real food'),
      ]));

      final result = await service.search('food');

      expect(result.length, 1);
      expect(result.first.name, 'Real food');
    });

    test('filters out products missing any macro value', () async {
      mockResponse(makeResponse([
        makeProduct(name: 'Incomplete', calories: null),
        makeProduct(name: 'Complete'),
      ]));

      final result = await service.search('food');

      expect(result.length, 1);
      expect(result.first.name, 'Complete');
    });

    test('returns empty list on non-200 response', () async {
      mockResponse({}, status: 500);

      final result = await service.search('oats');

      expect(result, isEmpty);
    });

    test('returns empty list when products field is missing', () async {
      mockResponse({'count': 0});

      final result = await service.search('oats');

      expect(result, isEmpty);
    });

    test('returns multiple products when multiple valid entries exist',
        () async {
      mockResponse(makeResponse([
        makeProduct(name: 'Chicken Breast'),
        makeProduct(name: 'Chicken Thigh'),
      ]));

      final result = await service.search('chicken');

      expect(result.length, 2);
    });

    test('trims whitespace from product names', () async {
      mockResponse(makeResponse([
        makeProduct(name: '  Oats  '),
      ]));

      final result = await service.search('oats');

      expect(result.first.name, 'Oats');
    });
  });
}
