import 'package:flutter/material.dart';

import 'package:way2move/features/assessments/domain/entities/assessment.dart';
import 'package:way2move/features/assessments/domain/entities/assessment_comparison_result.dart';
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';

/// Displays a summary card for a single [CompensationChange].
///
/// Shows the pattern name, before/after severity badges, and a trend arrow.
class CompensationImprovementCard extends StatelessWidget {
  final CompensationChange change;

  const CompensationImprovementCard({
    super.key,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patternDisplayName(change.pattern),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (change.beforeSeverity != null)
                      _SeverityBadge(severity: change.beforeSeverity!)
                    else
                      const _AbsentBadge(label: 'Not detected'),
                    const SizedBox(width: 8),
                    _trendArrow(context),
                    const SizedBox(width: 8),
                    if (change.afterSeverity != null)
                      _SeverityBadge(severity: change.afterSeverity!)
                    else
                      const _AbsentBadge(label: 'Resolved'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _changeTypeIcon(context),
        ],
      ),
    );
  }

  Widget _trendArrow(BuildContext context) {
    return Icon(
      Icons.arrow_forward,
      size: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _changeTypeIcon(BuildContext context) {
    final (icon, color) = switch (change.changeType) {
      CompensationChangeType.resolved => (Icons.check_circle, Colors.green),
      CompensationChangeType.improved => (Icons.trending_down, Colors.green),
      CompensationChangeType.worsened => (Icons.trending_up, Colors.red),
      CompensationChangeType.newlyDetected => (Icons.add_circle, Colors.orange),
      CompensationChangeType.unchanged => (Icons.remove, Colors.grey),
    };
    return Icon(icon, color: color, size: 22);
  }

  String _patternDisplayName(CompensationPattern pattern) {
    // Convert camelCase enum name to readable title
    final raw = pattern.name;
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final ch = raw[i];
      if (ch == ch.toUpperCase() && i > 0) {
        buffer.write(' ');
      }
      buffer.write(i == 0 ? ch.toUpperCase() : ch);
    }
    return buffer.toString();
  }
}

class _SeverityBadge extends StatelessWidget {
  final CompensationSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (severity) {
      CompensationSeverity.mild => (
          'Mild',
          const Color(0xFFFFF9C4),
          const Color(0xFFF57F17),
        ),
      CompensationSeverity.moderate => (
          'Moderate',
          const Color(0xFFFFE0B2),
          const Color(0xFFE65100),
        ),
      CompensationSeverity.significant => (
          'Significant',
          const Color(0xFFFFCDD2),
          const Color(0xFFB71C1C),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AbsentBadge extends StatelessWidget {
  final String label;
  const _AbsentBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
