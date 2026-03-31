import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/stomach_food_correlation.dart';

class StomachCorrelationList extends StatelessWidget {
  final List<StomachFoodCorrelation> correlations;

  const StomachCorrelationList({super.key, required this.correlations});

  @override
  Widget build(BuildContext context) {
    if (correlations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Not enough data yet. Log meals with food items for at least 2 weeks.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: correlations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final c = correlations[index];
        return _CorrelationTile(correlation: c);
      },
    );
  }
}

class _CorrelationTile extends StatelessWidget {
  final StomachFoodCorrelation correlation;
  const _CorrelationTile({required this.correlation});

  @override
  Widget build(BuildContext context) {
    final color = correlation.isProblematic
        ? AppColors.accentRed
        : correlation.avgStomachFeeling >= 4
            ? AppColors.accentGreen
            : AppColors.textSecondary;

    final emoji = correlation.avgStomachFeeling >= 4.5
        ? '😊'
        : correlation.avgStomachFeeling >= 3.5
            ? '🙂'
            : correlation.avgStomachFeeling >= 2.5
                ? '😐'
                : correlation.avgStomachFeeling >= 1.5
                    ? '😕'
                    : '😣';

    return ListTile(
      dense: true,
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(
        correlation.foodName[0].toUpperCase() +
            correlation.foodName.substring(1),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: correlation.isProblematic
                  ? AppColors.accentRed
                  : AppColors.textPrimary,
            ),
      ),
      subtitle: Text(
        '${correlation.occurrences} meals',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      trailing: Text(
        correlation.avgStomachFeeling.toStringAsFixed(1),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
      ),
    );
  }
}
