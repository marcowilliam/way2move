import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/home_providers.dart';
import '../../../goals/presentation/providers/goal_providers.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileStreamProvider).valueOrNull;
    final onboardingDone = ref.watch(hasCompletedOnboardingProvider);
    final streak = ref.watch(streakProvider);
    final totalSessions = ref.watch(totalCompletedSessionsProvider);
    final userId = ref.watch(currentUserIdProvider);
    final activeGoalsCount = userId != null
        ? ref.watch(activeGoalsProvider(userId)).valueOrNull?.length ?? 0
        : 0;

    return Scaffold(
      key: AppKeys.profilePage,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () => context.push(Routes.profileEdit),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _ProfileHeader(
            name: profile?.name ?? '',
            email: profile?.email ?? '',
            trainingGoal: profile?.trainingGoal,
          ),

          // ── Onboarding CTA ───────────────────────────────────────────────
          if (!onboardingDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                color: AppColors.secondary.withAlpha(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.secondary.withAlpha(77)),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.waving_hand, color: AppColors.secondary),
                  title: const Text('Complete your setup'),
                  subtitle: const Text(
                      'Finish onboarding to personalise your experience'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.onboarding),
                ),
              ),
            ),

          // ── Stats Row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                        child:
                            _StatCell(value: '$streak', label: 'Day Streak')),
                    _StatDivider(),
                    Expanded(
                        child: _StatCell(
                            value: '$totalSessions', label: 'Sessions')),
                    _StatDivider(),
                    Expanded(
                        child: _StatCell(
                            value: '$activeGoalsCount', label: 'Goals')),
                  ],
                ),
              ),
            ),
          ),

          // ── Training section ─────────────────────────────────────────────
          const _SectionHeader(label: 'Training'),
          _NavTile(
            icon: Icons.grid_view_outlined,
            label: 'My Program',
            subtitle: 'View and manage training program',
            onTap: () => context.go(Routes.programs),
          ),
          _NavTile(
            icon: Icons.assignment_outlined,
            label: 'Movement Assessment',
            subtitle: 'Run or view your latest assessment',
            onTap: () => context.push(Routes.assessment),
          ),
          _NavTile(
            icon: Icons.history_outlined,
            label: 'Assessment History',
            subtitle: 'Past assessment scores',
            onTap: () => context.push(Routes.assessmentHistory),
          ),

          // ── Movement section ─────────────────────────────────────────────
          const _SectionHeader(label: 'Movement'),
          _NavTile(
            icon: Icons.accessibility_new_outlined,
            label: 'Compensation Profile',
            subtitle: 'Track movement imbalances',
            onTap: () => context.push(Routes.compensationProfile),
          ),
          _NavTile(
            icon: Icons.flag_outlined,
            label: 'Goals',
            subtitle: 'Active goals and progress',
            onTap: () => context.go(Routes.goals),
          ),

          // ── Account section ──────────────────────────────────────────────
          const _SectionHeader(label: 'Account'),
          _NavTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            subtitle: 'Name, age, height, weight',
            onTap: () => context.push(Routes.profileEdit),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: AppKeys.signOutButton,
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentRed,
                side: const BorderSide(color: AppColors.accentRed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    this.trainingGoal,
  });
  final String name;
  final String email;
  final dynamic trainingGoal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withAlpha(38),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Way2Move Athlete',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (email.isNotEmpty)
                  Text(email, style: Theme.of(context).textTheme.bodySmall),
                if (trainingGoal != null) ...[
                  const SizedBox(height: 4),
                  _GoalBadge(label: _goalLabel(trainingGoal)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(dynamic goal) {
    return switch (goal.toString().split('.').last) {
      'generalFitness' => 'General Fitness',
      'strength' => 'Strength',
      'mobility' => 'Mobility',
      'longevity' => 'Longevity',
      'sportSpecific' => 'Sport-Specific',
      'rehab' => 'Rehab',
      _ => '',
    };
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
