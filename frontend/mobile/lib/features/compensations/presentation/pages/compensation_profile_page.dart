import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/compensation.dart';
import '../providers/compensation_provider.dart';
import '../widgets/compensation_body_map.dart';

class CompensationProfilePage extends ConsumerWidget {
  const CompensationProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compensationsAsync = ref.watch(compensationStreamProvider);

    final theme = Theme.of(context);
    return Scaffold(
      key: AppKeys.compensationProfilePage,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Body awareness',
          style: theme.textTheme.displaySmall,
        ),
        centerTitle: false,
        toolbarHeight: 72,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add compensation',
            onPressed: () => context.push(Routes.compensationAdd),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: compensationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading compensations: $e'),
        ),
        data: (compensations) => compensations.isEmpty
            ? _EmptyState(onAdd: () => context.push(Routes.compensationAdd))
            : _CompensationBody(compensations: compensations),
      ),
    );
  }
}

class _CompensationBody extends StatelessWidget {
  final List<Compensation> compensations;
  const _CompensationBody({required this.compensations});

  @override
  Widget build(BuildContext context) {
    final active = compensations
        .where((c) => c.status == CompensationStatus.active)
        .toList();
    final improving = compensations
        .where((c) => c.status == CompensationStatus.improving)
        .toList();
    final resolved = compensations
        .where((c) => c.status == CompensationStatus.resolved)
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AspectRatio(
              aspectRatio: 0.5,
              child: CompensationBodyMap(
                compensations: compensations,
                onRegionTap: (c) =>
                    context.push(Routes.compensationDetail(c.id)),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Active',
                  count: active.length,
                  color: AppColors.severityModerate,
                ),
                ...active.map((c) => _CompensationTile(compensation: c)),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (improving.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Improving',
                  count: improving.length,
                  color: AppColors.severityImproving,
                ),
                ...improving.map((c) => _CompensationTile(compensation: c)),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (resolved.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Resolved',
                  count: resolved.length,
                  color: AppColors.severityResolved,
                ),
                ...resolved.map((c) => _CompensationTile(compensation: c)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label ($count)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompensationTile extends StatelessWidget {
  final Compensation compensation;
  const _CompensationTile({required this.compensation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(Routes.compensationDetail(compensation.id)),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              _SeverityBadge(severity: compensation.severity),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compensation.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _regionLabel(compensation.region),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final CompensationSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Color _severityColor(CompensationSeverity s) {
    switch (s) {
      case CompensationSeverity.mild:
        return AppColors.severityMild;
      case CompensationSeverity.moderate:
        return AppColors.severityModerate;
      case CompensationSeverity.severe:
        return AppColors.severitySignificant;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No compensations tracked',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Track movement imbalances to build a personalised corrective programme.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Compensation'),
            ),
          ],
        ),
      ),
    );
  }
}

String _regionLabel(CompensationRegion r) {
  switch (r) {
    case CompensationRegion.cervicalSpine:
      return 'Cervical Spine (Neck)';
    case CompensationRegion.leftShoulder:
      return 'Left Shoulder';
    case CompensationRegion.rightShoulder:
      return 'Right Shoulder';
    case CompensationRegion.thoracicSpine:
      return 'Thoracic Spine (Upper Back)';
    case CompensationRegion.lumbarSpine:
      return 'Lumbar Spine (Lower Back)';
    case CompensationRegion.pelvis:
      return 'Pelvis';
    case CompensationRegion.leftHip:
      return 'Left Hip';
    case CompensationRegion.rightHip:
      return 'Right Hip';
    case CompensationRegion.core:
      return 'Core';
    case CompensationRegion.leftKnee:
      return 'Left Knee';
    case CompensationRegion.rightKnee:
      return 'Right Knee';
    case CompensationRegion.leftAnkle:
      return 'Left Ankle';
    case CompensationRegion.rightAnkle:
      return 'Right Ankle';
    case CompensationRegion.leftFoot:
      return 'Left Foot';
    case CompensationRegion.rightFoot:
      return 'Right Foot';
  }
}
