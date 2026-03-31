import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/meal.dart';
import '../providers/nutrition_providers.dart';

class MealHistoryQuickAdd extends ConsumerWidget {
  final List<Meal> recentMeals;

  const MealHistoryQuickAdd({super.key, required this.recentMeals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recentMeals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No previous meals to quick-add.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Deduplicate by description + mealType
    final seen = <String>{};
    final unique = recentMeals.where((m) {
      final key = '${m.mealType.name}|${m.description}';
      return seen.add(key);
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: unique.length.clamp(0, 10),
      itemBuilder: (context, index) {
        final meal = unique[index];
        return _QuickAddTile(meal: meal);
      },
    );
  }
}

class _QuickAddTile extends ConsumerWidget {
  final Meal meal;
  const _QuickAddTile({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macroText = meal.hasMacros
        ? '${meal.totalCalories.round()} kcal · '
            '${meal.totalProtein.round()}P · '
            '${meal.totalCarbs.round()}C · '
            '${meal.totalFat.round()}F'
        : null;

    return ListTile(
      dense: true,
      leading: Icon(
        _mealTypeIcon(meal.mealType),
        color: AppColors.primary,
        size: 20,
      ),
      title: Text(
        meal.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: macroText != null
          ? Text(
              macroText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        tooltip: 'Quick add to today',
        onPressed: () => _quickAdd(context, ref),
      ),
    );
  }

  void _quickAdd(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final copy = meal.copyWith(
      id: '', // will be assigned by Firestore
      date: now,
      stomachFeeling: 3, // default; user can edit later
    );
    ref.read(dailyMealsNotifierProvider.notifier).addMeal(copy);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${meal.description}" to today'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _mealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.lunch:
        return Icons.restaurant_outlined;
      case MealType.dinner:
        return Icons.dinner_dining_outlined;
      case MealType.snack:
        return Icons.cookie_outlined;
      case MealType.drink:
        return Icons.local_cafe_outlined;
    }
  }
}
