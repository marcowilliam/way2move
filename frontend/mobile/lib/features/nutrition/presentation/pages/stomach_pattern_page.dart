import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/meal.dart';
import '../providers/nutrition_providers.dart';

class StomachPatternPage extends ConsumerWidget {
  const StomachPatternPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(stomachTrendProvider);

    return Scaffold(
      key: AppKeys.stomachPatternPage,
      appBar: AppBar(
        title: const Text('Stomach Pattern'),
      ),
      body: trendAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (trend) => _StomachPatternBody(trend: trend),
      ),
    );
  }
}

class _StomachPatternBody extends StatelessWidget {
  final Map<MealType, double> trend;
  const _StomachPatternBody({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const _EmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Stomach Pattern',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your last 14 days',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        ...MealType.values
            .where((t) => trend.containsKey(t))
            .map((t) => _MealTypeRow(mealType: t, average: trend[t]!)),
      ],
    );
  }
}

class _MealTypeRow extends StatelessWidget {
  final MealType mealType;
  final double average;

  const _MealTypeRow({required this.mealType, required this.average});

  @override
  Widget build(BuildContext context) {
    final color = average >= 4
        ? AppColors.accentGreen
        : average >= 3
            ? AppColors.secondary
            : AppColors.accentRed;

    final fraction = (average / 5).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _label(mealType),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                children: [
                  Text(
                    _emoji(average),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    average.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
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

  String _emoji(double avg) {
    if (avg >= 4.5) return '😊';
    if (avg >= 3.5) return '🙂';
    if (avg >= 2.5) return '😐';
    if (avg >= 1.5) return '😕';
    return '😣';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'No patterns yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log meals for 14 days to see stomach pattern insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
