import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/daily_nutrition_summary.dart';

class WeeklyNutritionChart extends StatelessWidget {
  final List<DailyNutritionSummary> summaries;
  final double? calorieTarget;

  const WeeklyNutritionChart({
    super.key,
    required this.summaries,
    this.calorieTarget,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data yet')),
      );
    }

    final maxCal = summaries
        .map((s) => s.totalCalories)
        .fold(calorieTarget ?? 0.0, (a, b) => a > b ? a : b);
    final yMax = (maxCal * 1.2).clamp(100.0, double.infinity);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yMax,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final s = summaries[group.x.toInt()];
                return BarTooltipItem(
                  '${s.totalCalories.round()} kcal\n'
                  'Stomach: ${s.avgStomachFeeling.toStringAsFixed(1)}',
                  Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textDisabled,
                        fontSize: 10,
                      ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= summaries.length) return const SizedBox();
                  final day = summaries[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _dayLabel(day.weekday),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: AppColors.border,
              strokeWidth: 0.5,
            ),
          ),
          extraLinesData: calorieTarget != null
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: calorieTarget!,
                    color: AppColors.accentRed.withValues(alpha: 0.5),
                    strokeWidth: 1.5,
                    dashArray: [6, 4],
                  ),
                ])
              : const ExtraLinesData(),
          barGroups: List.generate(summaries.length, (i) {
            final s = summaries[i];
            final isOver =
                calorieTarget != null && s.totalCalories > calorieTarget!;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: s.totalCalories,
                  width: 24,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                  color: s.mealCount == 0
                      ? AppColors.border
                      : isOver
                          ? AppColors.accentRed
                          : AppColors.primary,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _dayLabel(int weekday) => const [
        '',
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][weekday];
}
