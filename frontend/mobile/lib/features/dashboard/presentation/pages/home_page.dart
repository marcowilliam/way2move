import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../goals/domain/entities/goal.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../protocols/domain/entities/protocol.dart';
import '../../../protocols/presentation/providers/active_protocols_provider.dart';
import '../../../sessions/data/repositories/session_repository_impl.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/presentation/providers/session_providers.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../../../workouts/domain/usecases/start_session_from_workout.dart';
import '../../../workouts/presentation/providers/workouts_provider.dart';
import '../providers/home_providers.dart';

/// Way2Move home dashboard. Six sections, top → bottom:
/// 1. Greeting header (Fraunces display + streak chip)
/// 2. Today focal card (single hero — replaces session card + recovery banner)
/// 3. Week strip (7 × 32px circles)
/// 4. Monthly heat map
/// 5. Active goals (cap at 2)
/// 6. Quick log pill row (Journal · Meal · Sleep · Photo)
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: AppKeys.homeScreen,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _GreetingHeader(),
                const SizedBox(height: AppSpacing.lg),
                const _DailyRoutineProtocolCard(),
                const _TodayFocalCard(),
                const SizedBox(height: AppSpacing.lg),
                const _WeekStrip(),
                const SizedBox(height: AppSpacing.lg),
                const _MonthlyHeatMap(),
                const SizedBox(height: AppSpacing.lg),
                const _GoalProgressSection(),
                const SizedBox(height: AppSpacing.lg),
                const _QuickLogPillRow(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 1. Greeting header ───────────────────────────────────────────────────────

class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final streak = ref.watch(streakProvider);
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final firstName = profile?.name.split(' ').first ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting${firstName.isNotEmpty ? ', $firstName' : ''}.',
                style: Theme.of(context).textTheme.displaySmall,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat('EEEE, MMMM d').format(now),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (streak > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          _StreakBadge(streak: streak),
        ],
      ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm * 2),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department,
              size: 14, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ── 2. Today focal card ──────────────────────────────────────────────────────

/// Hero card driving the morning routine. One card, four states.
/// Replaces the old _TodaySessionCard + RecoveryBanner slot + missed-yesterday
/// banner — collapses three competing surfaces into one focal moment.
enum _FocalState { active, completed, planned, noSession }

class _TodayFocalCard extends ConsumerWidget {
  const _TodayFocalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todaySessionsProvider);
    final missedYesterday = ref.watch(missedYesterdayProvider);

    return todayAsync.when(
      loading: () => const _FocalSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        final inProgress = sessions
            .where((s) => s.status == SessionStatus.inProgress)
            .toList();
        final completed =
            sessions.where((s) => s.status == SessionStatus.completed).toList();
        final planned =
            sessions.where((s) => s.status == SessionStatus.planned).toList();

        if (inProgress.isNotEmpty) {
          return _FocalCardShell(
            state: _FocalState.active,
            session: inProgress.first,
          );
        }
        if (completed.isNotEmpty) {
          return _FocalCardShell(
            state: _FocalState.completed,
            session: completed.first,
            extraSessionCount: completed.length,
          );
        }
        if (planned.isNotEmpty) {
          return _FocalCardShell(
            state: _FocalState.planned,
            session: planned.first,
          );
        }
        return _FocalCardShell(
          state: _FocalState.noSession,
          showMissedBanner: missedYesterday,
        );
      },
    );
  }
}

class _FocalCardShell extends StatelessWidget {
  const _FocalCardShell({
    required this.state,
    this.session,
    this.showMissedBanner = false,
    this.extraSessionCount = 1,
  });

  final _FocalState state;
  final Session? session;
  final bool showMissedBanner;
  final int extraSessionCount;

  bool get _isCompleted => state == _FocalState.completed;
  bool get _isActive => state == _FocalState.active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color surface;
    final Color borderColor;
    if (_isActive) {
      surface = AppColors.primary.withValues(alpha: 0.08);
      borderColor = AppColors.primary.withValues(alpha: 0.6);
    } else if (_isCompleted) {
      surface = AppColors.accent.withValues(alpha: 0.08);
      borderColor = AppColors.accent.withValues(alpha: 0.5);
    } else {
      surface = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outline;
    }

    return Stack(
      children: [
        AnimatedContainer(
          duration: WayMotion.standard,
          curve: WayMotion.easeStandard,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: _FocalBody(
            state: state,
            session: session,
            showMissedBanner: showMissedBanner,
            extraSessionCount: extraSessionCount,
          ),
        ),
        if (!_isCompleted)
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FocalBody extends StatelessWidget {
  const _FocalBody({
    required this.state,
    required this.session,
    required this.showMissedBanner,
    required this.extraSessionCount,
  });

  final _FocalState state;
  final Session? session;
  final bool showMissedBanner;
  final int extraSessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (state) {
      case _FocalState.active:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('In progress',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              session?.focus ?? 'Session in progress',
              style: AppTypography.fraunces(
                size: 24,
                weight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _FocalCta(
              label: 'Continue Session',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push(Routes.sessionActive),
            ),
          ],
        );

      case _FocalState.planned:
        final blocks = session?.exerciseBlocks.length ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Today's session",
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              session?.focus ?? 'Training',
              style: AppTypography.fraunces(
                size: 24,
                weight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (blocks > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$blocks exercise${blocks == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _FocalCta(
              label: 'Start Session',
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.push(Routes.sessionActive),
            ),
          ],
        );

      case _FocalState.completed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 20, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Great work today!',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: AppColors.accent),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              session?.focus != null
                  ? '${session!.focus} completed'
                  : '$extraSessionCount session${extraSessionCount == 1 ? '' : 's'} done',
              style: AppTypography.fraunces(
                size: 22,
                weight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
                style: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Rest now — tomorrow keeps the streak.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );

      case _FocalState.noSession:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMissedBanner) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_outlined,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Back on track — every session counts.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text('Today',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No session today',
              style: AppTypography.fraunces(
                size: 24,
                weight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Rest day — log your journal or start something fresh.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            _FocalCta(
              label: 'Start Session',
              icon: Icons.add_rounded,
              onPressed: () => context.push(Routes.sessionStandalone),
            ),
          ],
        );
    }
  }
}

class _FocalCta extends StatelessWidget {
  const _FocalCta({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

class _FocalSkeleton extends StatelessWidget {
  const _FocalSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 120,
                    color: theme.colorScheme.surfaceContainerHighest),
                const SizedBox(height: AppSpacing.xs + 2),
                Container(
                    height: 12,
                    width: 80,
                    color: theme.colorScheme.surfaceContainerHighest),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Week strip ────────────────────────────────────────────────────────────

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeDays = ref.watch(weeklyCompletedDaysProvider);
    final todayWeekday = DateTime.now().weekday; // 1=Mon … 7=Sun

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final isCompleted = activeDays.contains(weekday);
              final isToday = weekday == todayWeekday;
              final isPast = weekday < todayWeekday;
              final isMissed = isPast && !isCompleted;

              return Column(
                children: [
                  Text(
                    _dayLabels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isToday
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  AnimatedContainer(
                    duration: WayMotion.standard,
                    curve: WayMotion.easeStandard,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isCompleted ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: isToday
                            ? AppColors.primary
                            : isCompleted
                                ? AppColors.accent
                                : theme.colorScheme.outline,
                        width: isToday ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 16, color: AppColors.textOnPrimary)
                          : isMissed
                              ? Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accent,
                                  ),
                                )
                              : null,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── 4. Monthly heat map ──────────────────────────────────────────────────────

class _MonthlyHeatMap extends ConsumerWidget {
  const _MonthlyHeatMap();

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sessions = ref.watch(currentMonthSessionsProvider);
    final now = DateTime.now();
    final monthName = DateFormat('MMM').format(now);

    final completedDays = sessions
        .where((s) => s.status == SessionStatus.completed)
        .map((s) => s.date.day)
        .toSet();
    final plannedDays = sessions
        .where((s) => s.status == SessionStatus.planned)
        .map((s) => s.date.day)
        .toSet();

    final firstDay = DateTime(now.year, now.month, 1);
    final leadingBlanks = firstDay.weekday - 1;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      key: AppKeys.monthlyHeatMap,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName ${now.year}',
                style: theme.textTheme.titleSmall,
              ),
              Text(
                '${completedDays.length} session${completedDays.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _dayLabels
                .map(
                  (l) => SizedBox(
                    width: 28,
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xs),
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
                bgColor = AppColors.accent;
                child = const Icon(Icons.check,
                    size: 10, color: AppColors.textOnPrimary);
              } else if (isPlanned && !isFuture) {
                bgColor = AppColors.sessionPlanned.withValues(alpha: 0.2);
                borderColor = AppColors.sessionPlanned;
              } else if (isToday) {
                bgColor = AppColors.primary.withValues(alpha: 0.1);
                borderColor = AppColors.primary;
              } else {
                bgColor = isFuture
                    ? Colors.transparent
                    : theme.colorScheme.surfaceContainerHighest;
              }

              return AnimatedContainer(
                duration: WayMotion.standard,
                curve: WayMotion.easeStandard,
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
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: isDone
                              ? AppColors.textOnPrimary
                              : isFuture
                                  ? theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4)
                                  : isToday
                                      ? AppColors.primary
                                      : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── 5. Goal progress section ────────────────────────────────────────────────

class _GoalProgressSection extends ConsumerWidget {
  const _GoalProgressSection();

  static const _maxVisible = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const SizedBox.shrink();

    final goalsAsync = ref.watch(activeGoalsProvider(userId));

    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (goals) {
        if (goals.isEmpty) {
          return const _NoGoalsCard();
        }
        final display = goals.take(_maxVisible).toList();
        final hasMore = goals.length > _maxVisible;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Goals', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            ...display.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _GoalMiniCard(goal: g),
                )),
            if (hasMore)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go(Routes.goals),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  ),
                  icon: const Text('See all goals'),
                  label: const Icon(Icons.chevron_right, size: 18),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NoGoalsCard extends StatelessWidget {
  const _NoGoalsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined,
              color: theme.colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No active goals', style: theme.textTheme.titleSmall),
                Text(
                  'Complete an assessment to get goal suggestions',
                  style: theme.textTheme.bodySmall,
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
    );
  }
}

class _GoalMiniCard extends StatelessWidget {
  const _GoalMiniCard({required this.goal});
  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal.progressFraction;

    return InkWell(
      onTap: () => context.push(Routes.goalDetail(goal.id)),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_fmt(goal.currentValue)} / ${_fmt(goal.targetValue)} ${goal.unit}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v.truncateToDouble() == v ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

// ── 6. Quick log pill row ───────────────────────────────────────────────────

/// Horizontal scroller with 4 outlined pills. Replaces the old 2×2
/// _QuickActionsGrid + 2×2 _TrackTodayGrid (8 tiles, two sections) with one
/// compact row focused on the daily-logging surface area.
class _QuickLogPillRow extends StatelessWidget {
  const _QuickLogPillRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: AppKeys.trackTodayGrid,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Track today', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            children: [
              _LogPill(
                key: AppKeys.quickActionLogJournal,
                icon: Icons.mic_outlined,
                label: 'Journal',
                onTap: () => context.push(Routes.journalEntry),
              ),
              const SizedBox(width: AppSpacing.sm),
              _LogPill(
                key: AppKeys.quickActionLogMeal,
                icon: Icons.restaurant_outlined,
                label: 'Meal',
                onTap: () => context.push(Routes.mealLog),
              ),
              const SizedBox(width: AppSpacing.sm),
              _LogPill(
                key: AppKeys.quickActionLogSleep,
                icon: Icons.bedtime_outlined,
                label: 'Sleep',
                onTap: () => context.push(Routes.sleep),
              ),
              const SizedBox(width: AppSpacing.sm),
              _LogPill(
                key: AppKeys.quickActionProgressPhoto,
                icon: Icons.camera_alt_outlined,
                label: 'Photo',
                onTap: () => context.push(Routes.photoCapture),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogPill extends StatelessWidget {
  const _LogPill({
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
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.45)),
        foregroundColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      icon: Icon(icon, size: 18, color: AppColors.accent),
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: AppColors.accent),
      ),
    );
  }
}

// ── Daily routine (protocol pin) ───────────────────────────────────────────

/// Renders one card per active Protocol's pinned workout above the focal
/// card. Tap → starts a `flexible`-slot session for today and navigates
/// straight into the active session view.
///
/// Hidden when there are no active protocols (returns SizedBox.shrink to
/// preserve the parent's spacing without leaving a visible gap).
class _DailyRoutineProtocolCard extends ConsumerWidget {
  const _DailyRoutineProtocolCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProtocols = ref.watch(activeProtocolsProvider);
    return asyncProtocols.maybeWhen(
      data: (protocols) {
        final now = DateTime.now();
        final relevant = protocols.where((p) => p.isActiveOn(now)).toList();
        if (relevant.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            for (final protocol in relevant)
              for (final workoutId in protocol.workoutIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ProtocolWorkoutTile(
                    protocol: protocol,
                    workoutId: workoutId,
                  ),
                ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ProtocolWorkoutTile extends ConsumerStatefulWidget {
  final Protocol protocol;
  final String workoutId;

  const _ProtocolWorkoutTile({
    required this.protocol,
    required this.workoutId,
  });

  @override
  ConsumerState<_ProtocolWorkoutTile> createState() =>
      _ProtocolWorkoutTileState();
}

class _ProtocolWorkoutTileState extends ConsumerState<_ProtocolWorkoutTile> {
  bool _starting = false;

  Future<void> _start(Workout workout) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _starting = true);
    try {
      final useCase = StartSessionFromWorkout(
        ref.read(sessionRepositoryProvider),
      );
      final result = await useCase(
        workout: workout,
        userId: userId,
        date: DateTime.now(),
        slot: SessionSlot.flexible,
      );
      if (!mounted) return;
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start: $failure')),
          );
        },
        (session) {
          ref
              .read(activeSessionProvider.notifier)
              .loadSession(session.copyWith(status: SessionStatus.inProgress));
          context.go(Routes.sessionActive);
        },
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncWorkout = ref.watch(workoutByIdProvider(widget.workoutId));
    final dayIndex = widget.protocol.dayIndexFor(DateTime.now());

    return asyncWorkout.maybeWhen(
      data: (workout) {
        if (workout == null) return const SizedBox.shrink();
        final activeCount = workout.activeBlocks.length;
        return Material(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            key: const Key('daily_routine_card'),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: _starting ? null : () => _start(workout),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25),
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      workout.iconEmoji ?? '🌱',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily routine',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.accent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          workout.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dayIndex != null
                              ? 'Day $dayIndex of ${widget.protocol.durationWeeks * 7} · $activeCount exercises'
                              : '$activeCount exercises',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _starting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
