import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../data/services/food_database_service.dart';
import '../entities/food_item.dart';

class SearchFoodItems {
  final FoodDatabaseService _service;
  SearchFoodItems(this._service);

  Future<Either<AppFailure, List<FoodItem>>> call(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Right([]);

    try {
      final results = await _service.search(trimmed);
      return Right(results);
    } catch (_) {
      return const Left(NetworkFailure());
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final searchFoodItemsProvider = Provider<SearchFoodItems>((ref) {
  return SearchFoodItems(ref.watch(foodDatabaseServiceProvider));
});
