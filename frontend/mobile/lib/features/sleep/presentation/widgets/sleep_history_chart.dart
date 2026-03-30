import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../domain/entities/sleep_log.dart';

class SleepHistoryChart extends StatefulWidget {
  final List<SleepLog> logs;

  const SleepHistoryChart({super.key, required this.logs});

  @override
  State<SleepHistoryChart> createState() => _SleepHistoryChartState();
}

class _SleepHistoryChartState extends State<SleepHistoryChart>
    with SingleTickerProviderStateMixin {
  bool _show30Days = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<SleepLog> get _filteredLogs {
    final days = _show30Days ? 30 : 7;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return widget.logs.where((l) => l.date.isAfter(cutoff)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  double get _averageQuality {
    final logs = _filteredLogs;
    if (logs.isEmpty) return 0.0;
    return logs.map((l) => l.quality).reduce((a, b) => a + b) / logs.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = _filteredLogs;
    final avg = _averageQuality;

    return Column(
      key: AppKeys.sleepHistoryChart,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Sleep Quality',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _ToggleButton(
              label: '7 days',
              selected: !_show30Days,
              onTap: () {
                setState(() => _show30Days = false);
                _animationController.forward(from: 0);
              },
            ),
            const SizedBox(width: 8),
            _ToggleButton(
              label: '30 days',
              selected: _show30Days,
              onTap: () {
                setState(() => _show30Days = true);
                _animationController.forward(from: 0);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (logs.isEmpty)
          _EmptyChartState(show30Days: _show30Days)
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) => CustomPaint(
                    painter: _SleepBarChartPainter(
                      logs: logs,
                      animation: _animation.value,
                      primaryColor: theme.colorScheme.primary,
                      surfaceColor: theme.colorScheme.surfaceContainerHighest,
                      show30Days: _show30Days,
                    ),
                    size: const Size(double.infinity, 120),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // X-axis labels
              _XAxisLabels(logs: logs, show30Days: _show30Days),
              const SizedBox(height: 8),

              // Average label
              Center(
                child: Text(
                  'Avg quality: ${avg.toStringAsFixed(1)} / 5',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final bool show30Days;

  const _EmptyChartState({required this.show30Days});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bedtime_outlined,
              size: 32,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No sleep data for the last ${show30Days ? 30 : 7} days',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XAxisLabels extends StatelessWidget {
  final List<SleepLog> logs;
  final bool show30Days;

  const _XAxisLabels({required this.logs, required this.show30Days});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show first, middle, and last labels to avoid crowding
    if (logs.isEmpty) return const SizedBox.shrink();

    final fmt = show30Days ? DateFormat('MM/dd') : DateFormat('EEE');
    final indices = <int>{0, logs.length - 1};
    if (logs.length > 2) indices.add(logs.length ~/ 2);
    final sorted = indices.toList()..sort();

    return Row(
      children: List.generate(logs.length, (i) {
        return Expanded(
          child: sorted.contains(i)
              ? Center(
                  child: Text(
                    fmt.format(logs[i].date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }
}

class _SleepBarChartPainter extends CustomPainter {
  final List<SleepLog> logs;
  final double animation;
  final Color primaryColor;
  final Color surfaceColor;
  final bool show30Days;

  _SleepBarChartPainter({
    required this.logs,
    required this.animation,
    required this.primaryColor,
    required this.surfaceColor,
    required this.show30Days,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    const maxQuality = 5.0;
    final barCount = logs.length;
    final spacing = show30Days ? 2.0 : 4.0;
    final barWidth = (size.width - (spacing * (barCount - 1))) / barCount;

    final bgPaint = Paint()..color = surfaceColor.withAlpha(100);
    final barPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < barCount; i++) {
      final log = logs[i];
      final x = i * (barWidth + spacing);
      final maxH = size.height;

      // Background bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, maxH),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      // Foreground bar (animated)
      final qualityFraction = (log.quality / maxQuality) * animation;
      final barH = maxH * qualityFraction;
      final barY = maxH - barH;

      final color = _qualityColor(log.quality);
      barPaint.color = color;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barY, barWidth, barH),
          const Radius.circular(4),
        ),
        barPaint,
      );
    }
  }

  Color _qualityColor(int quality) {
    switch (quality) {
      case 1:
        return const Color(0xFFEF5350);
      case 2:
        return const Color(0xFFFF8A65);
      case 3:
        return const Color(0xFFFFCA28);
      case 4:
        return const Color(0xFF66BB6A);
      case 5:
        return const Color(0xFF26A69A);
      default:
        return primaryColor;
    }
  }

  @override
  bool shouldRepaint(_SleepBarChartPainter old) =>
      old.animation != animation ||
      old.logs != logs ||
      old.show30Days != show30Days;
}
