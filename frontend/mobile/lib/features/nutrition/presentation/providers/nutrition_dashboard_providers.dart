import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../domain/entities/daily_nutrition_summary.dart';
import '../../domain/entities/stomach_food_correlation.dart';
import '../../domain/usecases/get_logging_streak.dart';
import '../../domain/usecases/get_stomach_food_correlations.dart';
import '../../domain/usecases/get_weekly_nutrition_summary.dart';

// ── Use-case providers ───────────────────────────────────────────────────────

final _getWeeklyNutritionSummaryProvider =
    Provider<GetWeeklyNutritionSummary>((ref) {
  return GetWeeklyNutritionSummary(ref.watch(mealRepositoryProvider));
});

final _getStomachFoodCorrelationsProvider =
    Provider<GetStomachFoodCorrelations>((ref) {
  return GetStomachFoodCorrelations(ref.watch(mealRepositoryProvider));
});

final _getLoggingStreakProvider = Provider<GetLoggingStreak>((ref) {
  return GetLoggingStreak(ref.watch(mealRepositoryProvider));
});

// ── Data providers ───────────────────────────────────────────────────────────

/// Weekly nutrition summaries (7 days ending today).
final weeklyNutritionProvider =
    FutureProvider<List<DailyNutritionSummary>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final result = await ref
      .read(_getWeeklyNutritionSummaryProvider)
      .call(userId, DateTime.now());
  return result.fold((_) => [], (summaries) => summaries);
});

/// Foods ranked by stomach feeling correlation (last 30 days).
final stomachCorrelationsProvider =
    FutureProvider<List<StomachFoodCorrelation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final result =
      await ref.read(_getStomachFoodCorrelationsProvider).call(userId);
  return result.fold((_) => [], (correlations) => correlations);
});

/// Consecutive days with at least 1 meal logged.
final loggingStreakProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  final result = await ref.read(_getLoggingStreakProvider).call(userId);
  return result.fold((_) => 0, (streak) => streak);
});
