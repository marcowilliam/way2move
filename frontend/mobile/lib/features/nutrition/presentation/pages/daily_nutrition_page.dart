import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/nutrition_target.dart';
import '../providers/nutrition_dashboard_providers.dart';
import '../providers/nutrition_providers.dart';
import '../providers/nutrition_target_provider.dart';
import '../widgets/calorie_progress_bar.dart';
import '../widgets/daily_meals_view.dart';
import '../widgets/macro_ring_chart.dart';

class DailyNutritionPage extends ConsumerStatefulWidget {
  const DailyNutritionPage({super.key});

  @override
  ConsumerState<DailyNutritionPage> createState() => _DailyNutritionPageState();
}

class _DailyNutritionPageState extends ConsumerState<DailyNutritionPage> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int delta) {
    final newDate = _selectedDate.add(Duration(days: delta));
    setState(() => _selectedDate = newDate);
    ref.read(dailyMealsNotifierProvider.notifier).loadDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(dailyMealsNotifierProvider);
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return Scaffold(
      key: AppKeys.nutritionPage,
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Weekly dashboard',
            onPressed: () => context.push(Routes.nutritionDashboard),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Stomach patterns',
            onPressed: () => context.push(Routes.stomachPattern),
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Nutrition targets',
            onPressed: () => context.push(Routes.nutritionTargetSettings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.mealLog),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _DateNavigator(
            date: _selectedDate,
            isToday: isToday,
            onPrev: () => _changeDate(-1),
            onNext: () => _changeDate(1),
          ),
          mealsAsync.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Expanded(
              child: Center(child: Text('Error: $e')),
            ),
            data: (meals) => _NutritionBody(meals: meals),
          ),
        ],
      ),
    );
  }
}

class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateNavigator({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final label =
        isToday ? 'Today' : '${_month(date.month)} ${date.day}, ${date.year}';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: isToday ? null : onNext,
          ),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m];
}

class _NutritionBody extends ConsumerWidget {
  final List<Meal> meals;
  const _NutritionBody({required this.meals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(nutritionTargetNotifierProvider).valueOrNull;
    final streak = ref.watch(loggingStreakProvider).valueOrNull ?? 0;

    return Expanded(
      child: Column(
        children: [
          _DailyMacroSummary(meals: meals, target: target, streak: streak),
          Expanded(child: DailyMealsView(meals: meals)),
        ],
      ),
    );
  }
}

class _DailyMacroSummary extends StatelessWidget {
  final List<Meal> meals;
  final NutritionTarget? target;
  final int streak;

  const _DailyMacroSummary({
    required this.meals,
    required this.target,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final totalCal = meals.fold(0.0, (s, m) => s + m.totalCalories);
    final totalP = meals.fold(0.0, (s, m) => s + m.totalProtein);
    final totalC = meals.fold(0.0, (s, m) => s + m.totalCarbs);
    final totalF = meals.fold(0.0, (s, m) => s + m.totalFat);

    final count = meals.length;
    final avgStomach = count == 0
        ? null
        : meals.map((m) => m.stomachFeeling).reduce((a, b) => a + b) / count;

    final stomachEmoji = avgStomach == null
        ? '—'
        : avgStomach >= 4.5
            ? '😊'
            : avgStomach >= 3.5
                ? '🙂'
                : avgStomach >= 2.5
                    ? '😐'
                    : avgStomach >= 1.5
                        ? '😕'
                        : '😣';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: meal count + streak + stomach
          Row(
            children: [
              Expanded(
                child: Text(
                  '$count meal${count == 1 ? '' : 's'} logged',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (streak > 0) ...[
                const Icon(Icons.local_fire_department,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 2),
                Text(
                  '$streak',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                ),
                const SizedBox(width: 12),
              ],
              if (avgStomach != null) ...[
                Text(stomachEmoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  avgStomach.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _stomachColor(avgStomach),
                      ),
                ),
              ],
            ],
          ),
          if (target != null) ...[
            const SizedBox(height: 16),
            CalorieProgressBar(
              consumed: totalCal,
              target: target!.baseCalories,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MacroRingChart(
                  label: 'Protein',
                  value: totalP,
                  target: target!.proteinGrams,
                  color: AppColors.accentGreen,
                ),
                MacroRingChart(
                  label: 'Carbs',
                  value: totalC,
                  target: target!.carbsGrams,
                  color: AppColors.accent,
                ),
                MacroRingChart(
                  label: 'Fat',
                  value: totalF,
                  target: target!.fatGrams,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ] else if (count > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _SimpleChip(label: '${totalCal.round()} kcal'),
                const SizedBox(width: 8),
                _SimpleChip(label: '${totalP.round()}g P'),
                const SizedBox(width: 8),
                _SimpleChip(label: '${totalC.round()}g C'),
                const SizedBox(width: 8),
                _SimpleChip(label: '${totalF.round()}g F'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _stomachColor(double avg) => avg >= 4
      ? AppColors.accentGreen
      : avg >= 3
          ? AppColors.secondary
          : AppColors.accentRed;
}

class _SimpleChip extends StatelessWidget {
  final String label;
  const _SimpleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
