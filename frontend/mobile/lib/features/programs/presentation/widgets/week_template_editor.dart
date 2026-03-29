import 'package:flutter/material.dart';
import '../../domain/entities/program.dart';

/// Displays a week's training template.
///
/// When [onDayToggled] is provided the widget is in edit mode — tapping a day
/// toggles it between rest and training (preserving existing exercise entries).
/// When null the widget is read-only.
class WeekTemplateEditor extends StatelessWidget {
  final WeekTemplate template;

  /// Called with the updated template whenever the user toggles a day.
  final void Function(WeekTemplate updated)? onDayToggled;

  const WeekTemplateEditor({
    super.key,
    required this.template,
    this.onDayToggled,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < 7; i++)
              _DayChip(
                label: _dayLabels[i],
                day: template.days[i] ?? DayTemplate.rest,
                onTap: onDayToggled == null
                    ? null
                    : () =>
                        _handleToggle(i, template.days[i] ?? DayTemplate.rest),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 7; i++)
          if (!(template.days[i] ?? DayTemplate.rest).isRestDay)
            _DayDetailCard(
              dayLabel: _dayLabels[i],
              day: template.days[i]!,
              theme: theme,
            ),
      ],
    );
  }

  void _handleToggle(int index, DayTemplate current) {
    if (onDayToggled == null) return;
    final updated = Map<int, DayTemplate>.from(template.days);
    if (current.isRestDay) {
      updated[index] = const DayTemplate(
        focus: 'Training Day',
        exerciseEntries: [],
        isRestDay: false,
      );
    } else {
      updated[index] = DayTemplate.rest;
    }
    onDayToggled!(WeekTemplate(days: updated));
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final DayTemplate day;
  final VoidCallback? onTap;

  const _DayChip({
    required this.label,
    required this.day,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = !day.isRestDay;
    final bgColor = isActive
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fgColor = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label.substring(0, 1),
            style: theme.textTheme.labelMedium?.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayDetailCard extends StatelessWidget {
  final String dayLabel;
  final DayTemplate day;
  final ThemeData theme;

  const _DayDetailCard({
    required this.dayLabel,
    required this.day,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  dayLabel.substring(0, 1),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.focus ?? dayLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (day.exerciseEntries.isNotEmpty)
                    Text(
                      '${day.exerciseEntries.length} exercise${day.exerciseEntries.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
