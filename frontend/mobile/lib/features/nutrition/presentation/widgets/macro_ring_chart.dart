import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MacroRingChart extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final Color color;

  const MacroRingChart({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.5) : 0.0;
    final remaining = (1.0 - progress).clamp(0.0, 1.0);
    final isOver = value > target && target > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: 28,
                  sections: [
                    PieChartSectionData(
                      value: progress.clamp(0.0, 1.0),
                      color: isOver ? AppColors.accentRed : color,
                      radius: 10,
                      showTitle: false,
                    ),
                    if (remaining > 0)
                      PieChartSectionData(
                        value: remaining,
                        color: AppColors.border,
                        radius: 10,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${value.round()}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isOver ? AppColors.accentRed : color,
                          fontSize: 14,
                        ),
                  ),
                  Text(
                    'g',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          '/ ${target.round()}g',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textDisabled,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}
