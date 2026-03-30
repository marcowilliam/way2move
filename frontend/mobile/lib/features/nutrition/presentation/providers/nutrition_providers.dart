import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../domain/entities/meal.dart';
import '../../domain/usecases/create_meal.dart';
import '../../domain/usecases/delete_meal.dart';
import '../../domain/usecases/get_meals_by_date.dart';
import '../../domain/usecases/update_meal.dart';

// Re-export repository provider for convenience
export '../../data/repositories/meal_repository_impl.dart'
    show mealRepositoryProvider;

// Use-case providers
final createMealProvider = Provider<CreateMeal>((ref) {
  return CreateMeal(ref.watch(mealRepositoryProvider));
});

final updateMealProvider = Provider<UpdateMeal>((ref) {
  return UpdateMeal(ref.watch(mealRepositoryProvider));
});

final deleteMealProvider = Provider<DeleteMeal>((ref) {
  return DeleteMeal(ref.watch(mealRepositoryProvider));
});

final getMealsByDateProvider = Provider<GetMealsByDate>((ref) {
  return GetMealsByDate(ref.watch(mealRepositoryProvider));
});

// ── Daily meals state ─────────────────────────────────────────────────────────

class DailyMealsNotifier extends AsyncNotifier<List<Meal>> {
  DateTime _date = DateTime.now();

  @override
  Future<List<Meal>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    final result = await ref.read(getMealsByDateProvider).call(userId, _date);
    return result.fold((_) => [], (meals) => meals);
  }

  Future<void> loadDate(DateTime date) async {
    _date = date;
    ref.invalidateSelf();
  }

  Future<void> addMeal(Meal meal) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final result = await ref.read(createMealProvider).call(meal);
    result.fold(
      (_) {},
      (created) {
        final current = state.valueOrNull ?? [];
        state = AsyncData(
            [...current, created]..sort((a, b) => a.date.compareTo(b.date)));
      },
    );
  }

  Future<void> removeMeal(String mealId) async {
    final result = await ref.read(deleteMealProvider).call(mealId);
    result.fold(
      (_) {},
      (_) {
        final current = state.valueOrNull ?? [];
        state = AsyncData(current.where((m) => m.id != mealId).toList());
      },
    );
  }
}

final dailyMealsNotifierProvider =
    AsyncNotifierProvider<DailyMealsNotifier, List<Meal>>(
  DailyMealsNotifier.new,
);

// ── Stomach trend (last 14 days) ──────────────────────────────────────────────

/// Returns a map of MealType → average stomach feeling (1.0–5.0).
/// Only includes meal types that have at least one entry.
final stomachTrendProvider = FutureProvider<Map<MealType, double>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};

  final repo = ref.watch(mealRepositoryProvider);
  final result = await repo.getMealHistory(userId, limit: 200);

  return result.fold((_) => {}, (meals) {
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final recent = meals.where((m) => m.date.isAfter(cutoff)).toList();

    final Map<MealType, List<int>> byType = {};
    for (final meal in recent) {
      byType.putIfAbsent(meal.mealType, () => []).add(meal.stomachFeeling);
    }

    return byType.map(
      (type, feelings) =>
          MapEntry(type, feelings.reduce((a, b) => a + b) / feelings.length),
    );
  });
});
