import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../recovery/presentation/widgets/recovery_banner.dart';
import '../../../goals/domain/entities/goal.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/presentation/providers/session_providers.dart';
import '../../../assessments/presentation/providers/assessment_providers.dart';
import '../providers/home_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: AppKeys.homeScreen,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _GreetingAppBar(ref: ref),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _TodaySessionCard(ref: ref),
                const SizedBox(height: 12),
                const RecoveryBanner(),
                const SizedBox(height: 16),
                _WeekStrip(ref: ref),
                const SizedBox(height: 16),
                _MonthlyHeatMap(ref: ref),
                const SizedBox(height: 16),
                _GoalProgressSection(ref: ref),
                const SizedBox(height: 16),
                _QuickActionsGrid(ref: ref),
                const SizedBox(height: 16),
                _TrackTodayGrid(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Greeting SliverAppBar ─────────────────────────────────────────────────────

class _GreetingAppBar extends ConsumerWidget {
  const _GreetingAppBar({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final profile = widgetRef.watch(profileStreamProvider).valueOrNull;
    final streak = widgetRef.watch(streakProvider);
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final firstName = profile?.name.split(' ').first ?? '';

    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting${firstName.isNotEmpty ? ', $firstName' : ''}.',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(now),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (streak > 0) ...[
              const SizedBox(width: 8),
              _StreakBadge(streak: streak),
            ],
          ],
        ),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today's Session Card ──────────────────────────────────────────────────────

class _TodaySessionCard extends ConsumerWidget {
  const _TodaySessionCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final todayAsync = widgetRef.watch(todaySessionsProvider);
    final missedYesterday = widgetRef.watch(missedYesterdayProvider);

    return todayAsync.when(
      loading: () => const _SessionCardSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        final completed =
            sessions.where((s) => s.status == SessionStatus.completed).toList();
        final planned =
            sessions.where((s) => s.status == SessionStatus.planned).toList();
        final inProgress = sessions
            .where((s) => s.status == SessionStatus.inProgress)
            .toList();

        if (inProgress.isNotEmpty) {
          return _ActiveSessionBanner(session: inProgress.first);
        }
        if (completed.isNotEmpty) {
          return _CompletedTodayCard(sessions: completed);
        }
        if (planned.isNotEmpty) {
          return _PlannedSessionCard(session: planned.first);
        }
        return _NoSessionCard(showMissedBanner: missedYesterday);
      },
    );
  }
}

class _SessionCardSkeleton extends StatelessWidget {
  const _SessionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14, width: 120, color: AppColors.surfaceVariant),
                  const SizedBox(height: 6),
                  Container(
                      height: 12, width: 80, color: AppColors.surfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  const _ActiveSessionBanner({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: ListTile(
        leading: const Icon(Icons.fitness_center,
            color: AppColors.textOnPrimary, size: 28),
        title: Text(
          session.focus ?? 'Session in progress',
          style: const TextStyle(
              color: AppColors.textOnPrimary, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Tap to continue',
          style: TextStyle(color: AppColors.textOnPrimary, fontSize: 12),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textOnPrimary),
        onTap: () => context.push(Routes.sessionActive),
      ),
    );
  }
}

class _PlannedSessionCard extends StatelessWidget {
  const _PlannedSessionCard({required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Session",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Text(
                        session.focus ?? 'Training',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const _StatusChip(
                    label: 'Planned', color: AppColors.sessionPlanned),
              ],
            ),
            if (session.exerciseBlocks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${session.exerciseBlocks.length} exercise${session.exerciseBlocks.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(Routes.sessionActive),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedTodayCard extends StatelessWidget {
  const _CompletedTodayCard({required this.sessions});
  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    final first = sessions.first;
    return Card(
      color: AppColors.accentGreen.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accentGreen.withAlpha(77)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.accentGreen, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Great work today!',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: AppColors.accentGreen),
                  ),
                  Text(
                    first.focus != null
                        ? '${first.focus} completed'
                        : '${sessions.length} session${sessions.length == 1 ? '' : 's'} done',
                    style: Theme.of(context).textTheme.bodySmall,
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

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard({required this.showMissedBanner});
  final bool showMissedBanner;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMissedBanner) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Back on track — every session counts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: AppColors.textSecondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No session today',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Ready when you are',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push(Routes.sessionStandalone),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Start Session'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week Strip ────────────────────────────────────────────────────────────────

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.ref});
  final WidgetRef ref;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final activeDays = widgetRef.watch(weeklyCompletedDaysProvider);
    final todayWeekday = DateTime.now().weekday; // 1=Mon…7=Sun

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (i) {
                final weekday = i + 1; // 1=Mon…7=Sun
                final isActive = activeDays.contains(weekday);
                final isToday = weekday == todayWeekday;

                return Column(
                  children: [
                    Text(
                      _dayLabels[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.accentGreen
                            : isToday
                                ? AppColors.primary.withAlpha(26)
                                : AppColors.surfaceVariant,
                        border: isToday
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: isActive
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Progress Section ─────────────────────────────────────────────────────

class _GoalProgressSection extends ConsumerWidget {
  const _GoalProgressSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final userId = widgetRef.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final goalsAsync = widgetRef.watch(activeGoalsProvider(userId));

    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (goals) {
        if (goals.isEmpty) {
          return _NoGoalsCard();
        }
        final display = goals.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Goals',
                    style: Theme.of(context).textTheme.titleSmall),
                TextButton(
                  onPressed: () => context.go(Routes.goals),
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4)),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...display.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _GoalMiniCard(goal: g),
                )),
          ],
        );
      },
    );
  }
}

class _NoGoalsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined,
                color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active goals',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    'Complete an assessment to get goal suggestions',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push(Routes.assessment),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  const _GoalMiniCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressFraction;

    return InkWell(
      onTap: () => context.push(Routes.goalDetail(goal.id)),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${goal.currentValue.toStringAsFixed(goal.currentValue.truncateToDouble() == goal.currentValue ? 0 : 1)} / ${goal.targetValue.toStringAsFixed(goal.targetValue.truncateToDouble() == goal.targetValue ? 0 : 1)} ${goal.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Monthly Heat Map ──────────────────────────────────────────────────────────

class _MonthlyHeatMap extends ConsumerWidget {
  const _MonthlyHeatMap({required this.ref});
  final WidgetRef ref;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final sessions = widgetRef.watch(currentMonthSessionsProvider);
    final now = DateTime.now();
    final monthName = const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][now.month];

    // Build a set of day-of-month numbers that have completed sessions.
    final completedDays = sessions
        .where((s) => s.status == SessionStatus.completed)
        .map((s) => s.date.day)
        .toSet();
    final plannedDays = sessions
        .where((s) => s.status == SessionStatus.planned)
        .map((s) => s.date.day)
        .toSet();

    final firstDay = DateTime(now.year, now.month, 1);
    // weekday: 1=Mon…7=Sun; leading empty cells so day 1 lands on correct column
    final leadingBlanks = firstDay.weekday - 1;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Card(
      key: AppKeys.monthlyHeatMap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName ${now.year}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${completedDays.length} session${completedDays.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Day of week header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _dayLabels
                  .map(
                    (l) => SizedBox(
                      width: 28,
                      child: Text(
                        l,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Day grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final day = index - leadingBlanks + 1;
                final isToday = day == now.day;
                final isDone = completedDays.contains(day);
                final isPlanned = plannedDays.contains(day);
                final isFuture = day > now.day;

                Color bgColor;
                Color? borderColor;
                Widget? child;

                if (isDone) {
                  bgColor = AppColors.accentGreen;
                  child =
                      const Icon(Icons.check, size: 10, color: Colors.white);
                } else if (isPlanned && !isFuture) {
                  bgColor = AppColors.sessionPlanned.withAlpha(51);
                  borderColor = AppColors.sessionPlanned;
                } else if (isToday) {
                  bgColor = AppColors.primary.withAlpha(26);
                  borderColor = AppColors.primary;
                } else {
                  bgColor =
                      isFuture ? Colors.transparent : AppColors.surfaceVariant;
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: borderColor != null
                        ? Border.all(color: borderColor, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: child ??
                        Text(
                          '$day',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontSize: 9,
                                color: isDone
                                    ? Colors.white
                                    : isFuture
                                        ? AppColors.textSecondary.withAlpha(102)
                                        : isToday
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                        ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              children: [
                const _HeatMapLegendDot(color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text('Done', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(width: 12),
                const _HeatMapLegendDot(color: AppColors.surfaceVariant),
                const SizedBox(width: 4),
                Text('Rest', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatMapLegendDot extends StatelessWidget {
  const _HeatMapLegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── Quick Actions Grid ────────────────────────────────────────────────────────

class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid({required this.ref});
  final WidgetRef ref;

  void _onMovementScan(BuildContext context, WidgetRef widgetRef) {
    final userId = widgetRef.read(currentUserIdProvider);
    if (userId == null) return;

    final latestAssessment =
        widgetRef.read(latestAssessmentProvider).valueOrNull;

    if (latestAssessment == null) {
      // No assessment yet — guide user to complete questionnaire first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Complete a movement assessment first to get started.'),
          action: SnackBarAction(
            label: 'Start',
            onPressed: () => context.push(Routes.assessment),
          ),
        ),
      );
      return;
    }

    context.push(
      Routes.movementRecording,
      extra: {'assessmentId': latestAssessment.id, 'userId': userId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            _QuickActionTile(
              icon: Icons.add_circle_outline,
              label: 'New Session',
              onTap: () => context.push(Routes.sessionStandalone),
            ),
            _QuickActionTile(
              icon: Icons.assignment_outlined,
              label: 'Assessment',
              onTap: () => context.push(Routes.assessment),
            ),
            _QuickActionTile(
              icon: Icons.videocam_outlined,
              label: 'Movement Scan',
              onTap: () => _onMovementScan(context, widgetRef),
            ),
            _QuickActionTile(
              icon: Icons.calendar_view_week_outlined,
              label: 'My Program',
              onTap: () => context.go(Routes.programs),
            ),
            _QuickActionTile(
              icon: Icons.fitness_center_outlined,
              label: 'Exercises',
              onTap: () => context.go(Routes.exercises),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Track Today Grid ──────────────────────────────────────────────────────────

class _TrackTodayGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      key: AppKeys.trackTodayGrid,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Track Today', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            _QuickActionTile(
              key: AppKeys.quickActionLogJournal,
              icon: Icons.mic_outlined,
              label: 'Journal',
              onTap: () => context.push(Routes.journalEntry),
            ),
            _QuickActionTile(
              key: AppKeys.quickActionLogMeal,
              icon: Icons.restaurant_outlined,
              label: 'Log Meal',
              onTap: () => context.push(Routes.mealLog),
            ),
            _QuickActionTile(
              key: AppKeys.quickActionLogSleep,
              icon: Icons.bedtime_outlined,
              label: 'Log Sleep',
              onTap: () => context.push(Routes.sleep),
            ),
            _QuickActionTile(
              key: AppKeys.quickActionProgressPhoto,
              icon: Icons.camera_alt_outlined,
              label: 'Progress Photo',
              onTap: () => context.push(Routes.photoCapture),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
