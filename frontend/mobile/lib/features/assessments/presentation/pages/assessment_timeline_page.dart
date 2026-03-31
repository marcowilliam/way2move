import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/entities/re_assessment_schedule.dart';
import '../providers/assessment_providers.dart';
import '../providers/re_assessment_schedule_providers.dart';

class AssessmentTimelinePage extends ConsumerStatefulWidget {
  const AssessmentTimelinePage({super.key});

  @override
  ConsumerState<AssessmentTimelinePage> createState() =>
      _AssessmentTimelinePageState();
}

class _AssessmentTimelinePageState extends ConsumerState<AssessmentTimelinePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(assessmentHistoryProvider);
    final scheduleAsync = ref.watch(reAssessmentScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Timeline'),
        centerTitle: false,
        actions: [
          IconButton(
            key: const Key('scheduleSettingsButton'),
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Schedule Settings',
            onPressed: () => _showIntervalPicker(context, scheduleAsync),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(assessmentHistoryProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final prev =
                    index < history.length - 1 ? history[index + 1] : null;
                final trend = _computeTrend(entry, prev);

                final itemDelay = index * 0.08;
                final itemInterval = Interval(
                  itemDelay.clamp(0.0, 0.9),
                  (itemDelay + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                );

                return AnimatedBuilder(
                  animation: _listController,
                  builder: (_, child) {
                    final t = CurvedAnimation(
                            parent: _listController, curve: itemInterval)
                        .value;
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 24 * (1 - t)),
                        child: child,
                      ),
                    );
                  },
                  child: _TimelineItem(
                    assessment: entry,
                    trend: trend,
                    isFirst: index == 0,
                    onTap: () => context.push(Routes.assessmentHistory),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Failed to load timeline. Pull to retry.'),
        ),
      ),
    );
  }

  _TrendDirection _computeTrend(Assessment current, Assessment? previous) {
    if (previous == null) return _TrendDirection.neutral;
    final diff = current.overallScore - previous.overallScore;
    if (diff > 0.25) return _TrendDirection.up;
    if (diff < -0.25) return _TrendDirection.down;
    return _TrendDirection.neutral;
  }

  Future<void> _showIntervalPicker(
    BuildContext context,
    AsyncValue<ReAssessmentSchedule?> scheduleAsync,
  ) async {
    final current = scheduleAsync.valueOrNull?.intervalWeeks ?? 4;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _IntervalPickerSheet(
        currentInterval: current,
        onSelect: (weeks) async {
          Navigator.of(context).pop();
          await ref
              .read(reAssessmentScheduleProvider.notifier)
              .updateInterval(weeks);
        },
      ),
    );
  }
}

// ── Timeline item ─────────────────────────────────────────────────────────────

enum _TrendDirection { up, down, neutral }

class _TimelineItem extends StatelessWidget {
  final Assessment assessment;
  final _TrendDirection trend;
  final bool isFirst;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.assessment,
    required this.trend,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    // Overall score expressed as % frames without compensation
    final scorePercent = (assessment.overallScore / 10.0 * 100).round();

    final (trendIcon, trendColor) = switch (trend) {
      _TrendDirection.up => (Icons.arrow_upward_rounded, Colors.green),
      _TrendDirection.down => (Icons.arrow_downward_rounded, Colors.red),
      _TrendDirection.neutral => (Icons.arrow_forward_rounded, Colors.grey),
    };

    return GestureDetector(
      onTap: onTap,
      child: Card(
        key: Key('timelineItem_${assessment.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Score ring
              _ScoreRing(scorePercent: scorePercent),
              const SizedBox(width: 16),
              // Date + compensations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dateFormat.format(assessment.date),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (isFirst) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Latest',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${assessment.compensationResults.length} compensation${assessment.compensationResults.length == 1 ? '' : 's'} detected',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Trend arrow
              Icon(trendIcon, color: trendColor, size: 22),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.black38,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int scorePercent;
  const _ScoreRing({required this.scorePercent});

  @override
  Widget build(BuildContext context) {
    final color = scorePercent >= 80
        ? AppColors.accentGreen
        : scorePercent >= 60
            ? Colors.orange
            : Colors.red;

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: scorePercent / 100,
            strokeWidth: 5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Center(
            child: Text(
              '$scorePercent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interval picker sheet ─────────────────────────────────────────────────────

class _IntervalPickerSheet extends StatelessWidget {
  final int currentInterval;
  final void Function(int weeks) onSelect;

  const _IntervalPickerSheet({
    required this.currentInterval,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Re-assessment Interval',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'How often should you re-assess your movement?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...kAssessmentIntervalOptions.map(
              (weeks) => _IntervalOption(
                weeks: weeks,
                isSelected: weeks == currentInterval,
                onTap: () => onSelect(weeks),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntervalOption extends StatelessWidget {
  final int weeks;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntervalOption({
    required this.weeks,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        key: Key('intervalOption_$weeks'),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Text(
              'Every $weeks weeks',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Assessments Yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first movement assessment to start tracking your timeline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
