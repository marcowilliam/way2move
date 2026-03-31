import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/meal_repository_impl.dart';
import '../../domain/entities/meal.dart';
import '../providers/nutrition_dashboard_providers.dart';
import '../providers/nutrition_target_provider.dart';
import '../widgets/meal_history_quick_add.dart';
import '../widgets/stomach_correlation_list.dart';
import '../widgets/weekly_nutrition_chart.dart';

class NutritionDashboardPage extends ConsumerWidget {
  const NutritionDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WeeklyOverviewSection(),
            const SizedBox(height: 24),
            _ConsistencySection(),
            const SizedBox(height: 24),
            _StomachCorrelationSection(),
            const SizedBox(height: 24),
            _QuickAddSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _WeeklyOverviewSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyNutritionProvider);
    final target = ref.watch(nutritionTargetNotifierProvider).valueOrNull;

    return _Section(
      title: 'Weekly Calories',
      child: weeklyAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 200,
          child: Center(child: Text('Error: $e')),
        ),
        data: (summaries) => Column(
          children: [
            WeeklyNutritionChart(
              summaries: summaries,
              calorieTarget: target?.baseCalories,
            ),
            if (target != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 2,
                      color: AppColors.accentRed.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Target: ${target.baseCalories.round()} kcal',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            _WeeklyMacroSummary(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _WeeklyMacroSummary extends StatelessWidget {
  final WidgetRef ref;
  const _WeeklyMacroSummary({required this.ref});

  @override
  Widget build(BuildContext context) {
    final weeklyAsync = ref.watch(weeklyNutritionProvider);
    final summaries = weeklyAsync.valueOrNull ?? [];
    final daysWithData = summaries.where((s) => s.hasData).toList();
    if (daysWithData.isEmpty) return const SizedBox();

    final avgCal = daysWithData.fold(0.0, (s, d) => s + d.totalCalories) /
        daysWithData.length;
    final avgP = daysWithData.fold(0.0, (s, d) => s + d.totalProtein) /
        daysWithData.length;
    final avgC = daysWithData.fold(0.0, (s, d) => s + d.totalCarbs) /
        daysWithData.length;
    final avgF =
        daysWithData.fold(0.0, (s, d) => s + d.totalFat) / daysWithData.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _AvgStat(label: 'Avg Cal', value: '${avgCal.round()}'),
          _AvgStat(label: 'Avg P', value: '${avgP.round()}g'),
          _AvgStat(label: 'Avg C', value: '${avgC.round()}g'),
          _AvgStat(label: 'Avg F', value: '${avgF.round()}g'),
        ],
      ),
    );
  }
}

class _AvgStat extends StatelessWidget {
  final String label;
  final String value;
  const _AvgStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _ConsistencySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyNutritionProvider);
    final streakAsync = ref.watch(loggingStreakProvider);

    final summaries = weeklyAsync.valueOrNull ?? [];
    final daysLogged = summaries.where((s) => s.hasData).length;
    final streak = streakAsync.valueOrNull ?? 0;

    return _Section(
      title: 'Consistency',
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.calendar_today_outlined,
              value: '$daysLogged / 7',
              label: 'Days logged this week',
              color: daysLogged >= 5
                  ? AppColors.accentGreen
                  : daysLogged >= 3
                      ? AppColors.secondary
                      : AppColors.accentRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.local_fire_department,
              value: '$streak',
              label: 'Day streak',
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StomachCorrelationSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final correlationsAsync = ref.watch(stomachCorrelationsProvider);

    return _Section(
      title: 'Stomach-Food Correlations',
      child: correlationsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
        data: (correlations) =>
            StomachCorrelationList(correlations: correlations),
      ),
    );
  }
}

class _QuickAddSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_mealHistoryProvider);

    return _Section(
      title: 'Quick Add from History',
      child: historyAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
        data: (meals) => MealHistoryQuickAdd(recentMeals: meals),
      ),
    );
  }
}

/// Fetches recent meal history for the quick-add section.
final _mealHistoryProvider = FutureProvider<List<Meal>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final repo = ref.watch(mealRepositoryProvider);
  final result = await repo.getMealHistory(userId, limit: 50);
  return result.fold((_) => [], (meals) => meals);
});

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
