import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../exercises/presentation/providers/exercise_providers.dart';
import '../../domain/entities/session.dart';
import '../providers/session_providers.dart';

class SessionSummaryPage extends ConsumerStatefulWidget {
  final String sessionId;
  const SessionSummaryPage({super.key, required this.sessionId});

  @override
  ConsumerState<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends ConsumerState<SessionSummaryPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebController;
  late Animation<double> _celebScale;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _celebController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebScale = CurvedAnimation(
      parent: _celebController,
      curve: Curves.elasticOut,
    );
    _fadeIn = CurvedAnimation(
      parent: _celebController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _celebController.forward();
  }

  @override
  void dispose() {
    _celebController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(sessionHistoryProvider);

    return historyAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (sessions) {
        final session =
            sessions.where((s) => s.id == widget.sessionId).firstOrNull;

        if (session == null) {
          // Session not yet in history (latency) — show minimal summary
          return _buildSummaryScaffold(context, null);
        }

        return _buildSummaryScaffold(context, session);
      },
    );
  }

  Widget _buildSummaryScaffold(BuildContext context, Session? session) {
    final theme = Theme.of(context);
    final completedBlocks =
        session?.exerciseBlocks.where((b) => b.isStarted).toList() ?? [];
    final totalSets =
        completedBlocks.fold<int>(0, (sum, b) => sum + b.completedSetsCount);

    return Scaffold(
      key: AppKeys.sessionSummaryPage,
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Celebration icon
                    ScaleTransition(
                      scale: _celebScale,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentGreen.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          size: 52,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        children: [
                          Text(
                            'Workout Complete!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            session?.focus ?? 'Great work!',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Stats row
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Row(
                        children: [
                          _StatTile(
                            label: 'Exercises',
                            value: '${completedBlocks.length}',
                          ),
                          _StatTile(
                            label: 'Sets Done',
                            value: '$totalSets',
                          ),
                          _StatTile(
                            label: 'Duration',
                            value: session?.durationMinutes != null
                                ? '${session!.durationMinutes}m'
                                : '--',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (session?.notes?.isNotEmpty == true) ...[
                      FadeTransition(
                        opacity: _fadeIn,
                        child: _NotesCard(notes: session!.notes!),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
            if (session != null && completedBlocks.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final block = completedBlocks[index];
                      return FadeTransition(
                        opacity: _fadeIn,
                        child: _ExerciseSummaryTile(block: block),
                      );
                    },
                    childCount: completedBlocks.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: FilledButton(
            key: AppKeys.sessionDoneButton,
            onPressed: () => context.go(Routes.home),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Back to Home'),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(notes, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ExerciseSummaryTile extends ConsumerWidget {
  final ExerciseBlock block;
  const _ExerciseSummaryTile({required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final exercisesAsync = ref.watch(exerciseListProvider);
    final exercise = exercisesAsync.maybeWhen(
      data: (list) => list.where((e) => e.id == block.exerciseId).firstOrNull,
      orElse: () => null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise?.name ?? block.exerciseId,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${block.completedSetsCount} sets done'
                  '${block.rpe != null ? ' · RPE ${block.rpe}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Planned vs actual
          Text(
            '${block.plannedSets}→${block.completedSetsCount}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: block.completedSetsCount >= block.plannedSets
                  ? AppColors.accentGreen
                  : AppColors.accentRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
