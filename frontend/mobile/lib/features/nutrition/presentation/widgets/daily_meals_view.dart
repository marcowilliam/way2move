import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/meal.dart';
import '../providers/nutrition_providers.dart';

class DailyMealsView extends ConsumerWidget {
  final List<Meal> meals;

  const DailyMealsView({super.key, required this.meals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      key: AppKeys.dailyMealsView,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: MealType.values
          .map((type) => _MealTypeSection(
                mealType: type,
                meals: meals.where((m) => m.mealType == type).toList(),
                onDelete: (mealId) => ref
                    .read(dailyMealsNotifierProvider.notifier)
                    .removeMeal(mealId),
              ))
          .toList(),
    );
  }
}

class _MealTypeSection extends StatelessWidget {
  final MealType mealType;
  final List<Meal> meals;
  final void Function(String mealId) onDelete;

  const _MealTypeSection({
    required this.mealType,
    required this.meals,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            _label(mealType),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        if (meals.isEmpty)
          _EmptyMealSection(mealType: mealType)
        else
          ...meals.map((meal) => _DismissibleMealCard(
                meal: meal,
                onDelete: onDelete,
              )),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  String _label(MealType t) => switch (t) {
        MealType.breakfast => 'BREAKFAST',
        MealType.lunch => 'LUNCH',
        MealType.dinner => 'DINNER',
        MealType.snack => 'SNACK',
        MealType.drink => 'DRINK',
      };
}

class _EmptyMealSection extends StatelessWidget {
  final MealType mealType;
  const _EmptyMealSection({required this.mealType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'No ${_label(mealType).toLowerCase()} logged yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDisabled,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  String _label(MealType t) => switch (t) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
        MealType.drink => 'Drink',
      };
}

class _DismissibleMealCard extends StatelessWidget {
  final Meal meal;
  final void Function(String) onDelete;

  const _DismissibleMealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('meal_${meal.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.accentRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(meal.id),
      child: _MealCard(meal: meal),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('meal_card_${meal.id}'),
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              _stomachEmoji(meal.stomachFeeling),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (meal.stomachNotes != null &&
                      meal.stomachNotes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.notes,
                            size: 12, color: AppColors.textDisabled),
                        const SizedBox(width: 4),
                        Text(
                          'Has notes',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textDisabled,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _formatTime(meal.date),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _stomachEmoji(int feeling) => switch (feeling) {
        1 => '😣',
        2 => '😕',
        3 => '😐',
        4 => '🙂',
        5 => '😊',
        _ => '😐',
      };

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
