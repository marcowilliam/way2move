import 'package:flutter/material.dart';
import '../../domain/entities/weight_log.dart';

class WeightTrendChart extends StatelessWidget {
  final List<WeightLog> logs;

  const WeightTrendChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (logs.isEmpty) {
      return Container(
        key: const Key('weight_trend_chart_empty'),
        height: 160,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
              const SizedBox(height: 8),
              Text(
                'No weight data yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Compute average
    final avg = logs.map((l) => l.weight).reduce((a, b) => a + b) / logs.length;
    final unit = logs.last.unit.name;

    // Determine weight range for scaling
    final minW = logs.map((l) => l.weight).reduce((a, b) => a < b ? a : b);
    final maxW = logs.map((l) => l.weight).reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avg: ${avg.toStringAsFixed(1)} $unit',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: const Key('weight_trend_chart'),
          height: 120,
          child: CustomPaint(
            painter: _WeightLinePainter(
              logs: logs,
              minWeight: minW,
              range: range,
              lineColor: theme.colorScheme.primary,
              dotColor: theme.colorScheme.primary,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _WeightLinePainter extends CustomPainter {
  final List<WeightLog> logs;
  final double minWeight;
  final double range;
  final Color lineColor;
  final Color dotColor;

  _WeightLinePainter({
    required this.logs,
    required this.minWeight,
    required this.range,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final n = logs.length;
    final points = List.generate(n, (i) {
      final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
      final normalised = (logs[i].weight - minWeight) / range;
      final y =
          size.height - normalised * size.height * 0.85 - size.height * 0.075;
      return Offset(x, y);
    });

    // Draw line segments
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw dots
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_WeightLinePainter old) =>
      old.logs != logs || old.lineColor != lineColor;
}
