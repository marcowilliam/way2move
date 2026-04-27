import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/home_providers.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final onboardingDone = ref.watch(hasCompletedOnboardingProvider);
    final streak = ref.watch(streakProvider);
    final totalSessions = ref.watch(totalCompletedSessionsProvider);
    final userId = ref.watch(currentUserIdProvider);
    final activeGoalsCount = userId != null
        ? ref.watch(activeGoalsProvider(userId)).valueOrNull?.length ?? 0
        : 0;

    final name = profile?.name ?? '';
    final email = profile?.email ?? '';

    return Scaffold(
      key: AppKeys.profilePage,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.displaySmall),
        centerTitle: false,
        toolbarHeight: 72,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(name: name, email: email),
            const SizedBox(height: AppSpacing.md),
            _StatsRow(
              streak: streak,
              sessions: totalSessions,
              goals: activeGoalsCount,
            ),
            if (!onboardingDone) ...[
              const SizedBox(height: AppSpacing.lg),
              const _OnboardingCta(),
            ],
            const SizedBox(height: AppSpacing.xl),
            _NavGroupCard(
              title: 'Training',
              tiles: [
                _NavEntry(
                  icon: Icons.fitness_center_outlined,
                  label: 'Exercises',
                  subtitle: 'Browse the movement library',
                  onTap: () => context.go(Routes.exercises),
                ),
                _NavEntry(
                  icon: Icons.grid_view_outlined,
                  label: 'My Program',
                  subtitle: 'View and manage training program',
                  onTap: () => context.go(Routes.programs),
                ),
                _NavEntry(
                  icon: Icons.trending_up_outlined,
                  label: 'Progressions',
                  subtitle: 'Auto-progression rules',
                  onTap: () => context.push(Routes.progressionSettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _NavGroupCard(
              title: 'Body awareness',
              tiles: [
                _NavEntry(
                  icon: Icons.assignment_outlined,
                  label: 'Movement Assessment',
                  subtitle: 'Run or view your latest assessment',
                  onTap: () => context.push(Routes.assessment),
                ),
                _NavEntry(
                  icon: Icons.accessibility_new_outlined,
                  label: 'Compensation Profile',
                  subtitle: 'Tracked movement imbalances',
                  onTap: () => context.push(Routes.compensationProfile),
                ),
                _NavEntry(
                  icon: Icons.flag_outlined,
                  label: 'Movement Goals',
                  subtitle: 'Active goals and progress',
                  onTap: () => context.go(Routes.goals),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _NavGroupCard(
              title: 'Daily',
              tiles: [
                _NavEntry(
                  icon: Icons.mic_none_outlined,
                  label: 'Journal',
                  subtitle: 'Voice-first reflections',
                  onTap: () => context.push(Routes.journalHistory),
                ),
                _NavEntry(
                  icon: Icons.restaurant_outlined,
                  label: 'Nutrition',
                  subtitle: 'Meals and gut awareness',
                  onTap: () => context.go(Routes.nutrition),
                ),
                _NavEntry(
                  icon: Icons.nightlight_outlined,
                  label: 'Sleep',
                  subtitle: 'Bed, wake, and quality',
                  onTap: () => context.push(Routes.sleepHistory),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _NavGroupCard(
              title: 'You',
              tiles: [
                _NavEntry(
                  icon: Icons.photo_library_outlined,
                  label: 'Photos',
                  subtitle: 'Progress timeline',
                  onTap: () => context.push(Routes.photoTimeline),
                ),
                _NavEntry(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  subtitle: 'Name, age, height, weight',
                  onTap: () => context.push(Routes.profileEdit),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: TextButton.icon(
                key: AppKeys.signOutButton,
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
                icon: Icon(
                  Icons.logout,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  'Sign Out',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.email});
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.fraunces(
                size: 32,
                weight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name.isNotEmpty ? name : 'Way2Move Athlete',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              email,
              style: AppTypography.manrope(
                size: 13,
                weight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.streak,
    required this.sessions,
    required this.goals,
  });
  final int streak;
  final int sessions;
  final int goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Container(
      width: 1,
      height: 32,
      color: theme.colorScheme.outline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatColumn(value: '$streak', label: 'Day Streak'),
        const SizedBox(width: AppSpacing.lg),
        divider,
        const SizedBox(width: AppSpacing.lg),
        _StatColumn(value: '$sessions', label: 'Sessions'),
        const SizedBox(width: AppSpacing.lg),
        divider,
        const SizedBox(width: AppSpacing.lg),
        _StatColumn(value: '$goals', label: 'Goals'),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.fraunces(
            size: 28,
            weight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// ── Onboarding CTA ────────────────────────────────────────────────────────────

class _OnboardingCta extends StatelessWidget {
  const _OnboardingCta();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => context.push(Routes.onboarding),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.waving_hand_outlined, color: AppColors.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complete your setup',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Finish onboarding to personalise your experience',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav group card ────────────────────────────────────────────────────────────

class _NavEntry {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _NavEntry({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _NavGroupCard extends StatelessWidget {
  const _NavGroupCard({required this.title, required this.tiles});
  final String title;
  final List<_NavEntry> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              0,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTypography.fraunces(
                size: 20,
                weight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant,
                      indent: AppSpacing.xxl,
                    ),
                  _NavTile(entry: tiles[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.entry});
  final _NavEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.minTapTarget),
          child: Row(
            children: [
              Icon(entry.icon, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.label, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
