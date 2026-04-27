import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My program'),
        centerTitle: false,
        elevation: 0,
        actions: programAsync.maybeWhen(
          data: (program) => program == null
              ? []
              : [
                  _ProgramOverflowMenu(program: program),
                ],
          orElse: () => [],
        ),
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

class _ProgramOverflowMenu extends ConsumerWidget {
  final Program program;
  const _ProgramOverflowMenu({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        if (v == 'deactivate') _confirmDeactivate(context, ref);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'deactivate',
          child: Text('Deactivate program'),
        ),
      ],
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate program'),
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

class _ProgramBody extends ConsumerWidget {
  final Program program;
  final ThemeData theme;

  const _ProgramBody({super.key, required this.program, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingDays =
        program.weekTemplate.days.values.where((d) => !d.isRestDay).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program.name,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                '${program.durationWeeks} weeks',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.self_improvement,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                '$trainingDays days/week',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          if (program.goal.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                program.goal,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Weekly schedule',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          WeekTemplateEditor(template: program.weekTemplate),
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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.self_improvement,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No active program',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete your movement assessment to generate a program, or build one manually.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
