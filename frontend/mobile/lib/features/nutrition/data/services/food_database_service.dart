import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/food_item.dart';

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class FoodDatabaseService {
  Future<List<FoodItem>> search(String query);
}

// ── OpenFoodFacts implementation ──────────────────────────────────────────────

class OpenFoodFactsService implements FoodDatabaseService {
  final http.Client _client;

  OpenFoodFactsService({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<List<FoodItem>> search(String query) async {
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl'
      '?search_terms=${Uri.encodeComponent(query)}&json=1&page_size=20',
    );

    final response = await _client.get(
      uri,
      headers: {'User-Agent': 'Way2Move/1.0 (flutter; diet-tracking)'},
    );

    if (response.statusCode != 200) return [];

    final body = json.decode(response.body) as Map<String, dynamic>;
    final products = body['products'];
    if (products is! List) return [];

    final results = <FoodItem>[];
    for (final raw in products) {
      final product = raw as Map<String, dynamic>?;
      if (product == null) continue;

      final name = product['product_name'] as String?;
      if (name == null || name.trim().isEmpty) continue;

      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) continue;

      final calories = (nutriments['energy-kcal_100g'] as num?)?.toDouble();
      final protein = (nutriments['proteins_100g'] as num?)?.toDouble();
      final carbs = (nutriments['carbohydrates_100g'] as num?)?.toDouble();
      final fat = (nutriments['fat_100g'] as num?)?.toDouble();

      // Skip entries missing essential macro data
      if (calories == null || protein == null || carbs == null || fat == null) {
        continue;
      }

      results.add(FoodItem(
        name: name.trim(),
        portionGrams: 100,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ));
    }

    return results;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final foodDatabaseServiceProvider = Provider<FoodDatabaseService>(
  (_) => OpenFoodFactsService(),
);
