import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/program.dart';

/// Displays a week's training template as 7 vertical day cards.
///
/// When [onDayToggled] is provided the widget is in edit mode — tapping the
/// toggle icon on a rest-day card converts it to a training day and vice
/// versa. When null the widget is read-only and tapping a card expands it
/// inline to show the day's exercises.
class WeekTemplateEditor extends StatefulWidget {
  final WeekTemplate template;
  final void Function(WeekTemplate updated)? onDayToggled;

  const WeekTemplateEditor({
    super.key,
    required this.template,
    this.onDayToggled,
  });

  @override
  State<WeekTemplateEditor> createState() => _WeekTemplateEditorState();
}

class _WeekTemplateEditorState extends State<WeekTemplateEditor> {
  static const _dayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < 7; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
            child: _DayCard(
              label: _dayLabels[i],
              day: widget.template.days[i] ?? DayTemplate.rest,
              expanded: _expandedIndex == i,
              editable: widget.onDayToggled != null,
              onTap: () => setState(() {
                _expandedIndex = _expandedIndex == i ? null : i;
              }),
              onToggle: widget.onDayToggled == null
                  ? null
                  : () => _handleToggle(
                      i, widget.template.days[i] ?? DayTemplate.rest),
              theme: theme,
            ),
          ),
      ],
    );
  }

  void _handleToggle(int index, DayTemplate current) {
    final onDayToggled = widget.onDayToggled;
    if (onDayToggled == null) return;
    final updated = Map<int, DayTemplate>.from(widget.template.days);
    if (current.isRestDay) {
      updated[index] = const DayTemplate(
        focus: 'Training day',
        exerciseEntries: [],
        isRestDay: false,
      );
    } else {
      updated[index] = DayTemplate.rest;
    }
    onDayToggled(WeekTemplate(days: updated));
  }
}

class _DayCard extends StatelessWidget {
  final String label;
  final DayTemplate day;
  final bool expanded;
  final bool editable;
  final VoidCallback onTap;
  final VoidCallback? onToggle;
  final ThemeData theme;

  const _DayCard({
    required this.label,
    required this.day,
    required this.expanded,
    required this.editable,
    required this.onTap,
    required this.onToggle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isRest = day.isRestDay;
    final textColor = isRest ? AppColors.accent : AppColors.textOnPrimary;
    final cardColor = isRest ? Colors.transparent : AppColors.primary;
    final borderColor = isRest ? AppColors.accent : AppColors.primary;

    return AnimatedContainer(
      duration: WayMotion.standard,
      curve: WayMotion.easeStandard,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: isRest ? 1.5 : 0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isRest
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : AppColors.textOnPrimary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          label.substring(0, 1),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isRest ? 'Rest' : (day.focus ?? 'Training day'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRest)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm + 2,
                              vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color:
                                AppColors.textOnPrimary.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            '${day.exerciseEntries.length} ex',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (editable) ...[
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: Icon(
                            isRest
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                            color: textColor,
                          ),
                          onPressed: onToggle,
                          tooltip: isRest ? 'Activate' : 'Set as rest',
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  duration: WayMotion.standard,
                  firstChild: const SizedBox.shrink(),
                  secondChild: isRest
                      ? const SizedBox.shrink()
                      : _ExerciseList(day: day, textColor: textColor),
                  crossFadeState: expanded && !isRest
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  final DayTemplate day;
  final Color textColor;
  const _ExerciseList({required this.day, required this.textColor});

  @override
  Widget build(BuildContext context) {
    if (day.exerciseEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Text(
          'No exercises scheduled.',
          style: TextStyle(color: textColor.withValues(alpha: 0.85)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: textColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in day.exerciseEntries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: textColor),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      entry.exerciseId,
                      style: TextStyle(color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entry.sets}×${entry.reps}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
