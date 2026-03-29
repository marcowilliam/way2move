import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../domain/entities/program.dart';
import '../providers/program_providers.dart';
import '../widgets/week_template_editor.dart';

class ProgramDetailPage extends ConsumerWidget {
  const ProgramDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final programAsync = ref.watch(activeProgramProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Program'),
        centerTitle: true,
        elevation: 0,
      ),
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Something went wrong')),
        data: (program) {
          if (program == null) {
            return const _EmptyState();
          }
          return _ProgramBody(
            key: AppKeys.programDetailPage,
            program: program,
            theme: theme,
          );
        },
      ),
    );
  }
}

class _ProgramBody extends ConsumerWidget {
  final Program program;
  final ThemeData theme;

  const _ProgramBody({super.key, required this.program, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeactivating = ref.watch(deactivateProgramProvider).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  program.goal,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoBadge(
                      icon: Icons.calendar_today_outlined,
                      label: '${program.durationWeeks} weeks',
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _InfoBadge(
                      icon: Icons.fitness_center_outlined,
                      label: _countTrainingDays(program.weekTemplate),
                      theme: theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Week template ──────────────────────────────────────────────
          Text(
            'Weekly Schedule',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          WeekTemplateEditor(template: program.weekTemplate),
          const SizedBox(height: 32),

          // ── Deactivate ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isDeactivating
                  ? null
                  : () => _confirmDeactivate(context, ref),
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Deactivate Program'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _countTrainingDays(WeekTemplate template) {
    final count = template.days.values.where((d) => !d.isRestDay).length;
    return '$count days/week';
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Program'),
        content: const Text(
            'This will deactivate your current program. You can create a new one at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(deactivateProgramProvider.notifier).deactivate(program.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _InfoBadge(
      {required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No active program',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your movement assessment to generate a program, or build one manually.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
