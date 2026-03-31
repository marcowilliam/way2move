import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/meal.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/daily_meals_view.dart';

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

class _NutritionBody extends StatelessWidget {
  final List<Meal> meals;
  const _NutritionBody({required this.meals});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          _SummaryCard(meals: meals),
          Expanded(child: DailyMealsView(meals: meals)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Meal> meals;
  const _SummaryCard({required this.meals});

  @override
  Widget build(BuildContext context) {
    final count = meals.length;
    final avg = count == 0
        ? null
        : meals.map((m) => m.stomachFeeling).reduce((a, b) => a + b) / count;

    final color = avg == null
        ? AppColors.textDisabled
        : avg >= 4
            ? AppColors.accentGreen
            : avg >= 3
                ? AppColors.secondary
                : AppColors.accentRed;

    final emoji = avg == null
        ? '—'
        : avg >= 4.5
            ? '😊'
            : avg >= 3.5
                ? '🙂'
                : avg >= 2.5
                    ? '😐'
                    : avg >= 1.5
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count meal${count == 1 ? '' : 's'} logged',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stomach average',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (avg != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              avg.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ] else
            Text(
              'No data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textDisabled,
                  ),
            ),
        ],
      ),
    );
  }
}
