import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/compensation.dart';
import '../providers/compensation_provider.dart';

class CompensationDetailPage extends ConsumerStatefulWidget {
  final String compensationId;
  const CompensationDetailPage({super.key, required this.compensationId});

  @override
  ConsumerState<CompensationDetailPage> createState() =>
      _CompensationDetailPageState();
}

class _CompensationDetailPageState extends ConsumerState<CompensationDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    ));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compensationsAsync = ref.watch(compensationStreamProvider);

    return compensationsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (compensations) {
        final compensation = compensations.cast<Compensation?>().firstWhere(
              (c) => c?.id == widget.compensationId,
              orElse: () => null,
            );

        if (compensation == null) {
          return const Scaffold(
            body: Center(child: Text('Compensation not found')),
          );
        }

        return Scaffold(
          key: AppKeys.compensationDetailPage,
          appBar: AppBar(
            title: Text(compensation.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, compensation, value),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'improving',
                    child: Text('Mark as Improving'),
                  ),
                  const PopupMenuItem(
                    value: 'resolved',
                    child: Text('Mark as Resolved'),
                  ),
                ],
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideIn,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatusCard(compensation: compensation),
                  const SizedBox(height: 16),
                  if (compensation.relatedExerciseIds.isNotEmpty) ...[
                    const _SectionTitle(label: 'Corrective Exercises'),
                    _RelatedExercisesList(
                        exerciseIds: compensation.relatedExerciseIds),
                    const SizedBox(height: 16),
                  ],
                  if (compensation.history.isNotEmpty) ...[
                    const _SectionTitle(label: 'Progress History'),
                    _HistoryTimeline(history: compensation.history),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(
      BuildContext context, Compensation c, String action) async {
    final note = await _showNoteDialog(context,
        title:
            action == 'improving' ? 'What improved?' : 'What resolved this?');
    if (note == null || !mounted) return;

    final notifier = ref.read(compensationNotifierProvider.notifier);
    final result = action == 'improving'
        ? await notifier.markImproving(c.id, note)
        : await notifier.markResolved(c.id, note);

    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update compensation')),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'improving'
                ? 'Marked as improving!'
                : 'Marked as resolved!',
          ),
        ),
      ),
    );
  }

  Future<String?> _showNoteDialog(BuildContext context,
      {required String title}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Add a note (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Compensation compensation;
  const _StatusCard({required this.compensation});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(compensation.status);

    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _statusLabel(compensation.status),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
                const Spacer(),
                _SeverityChip(severity: compensation.severity),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Type',
              value: _typeLabel(compensation.type),
            ),
            _InfoRow(
              label: 'Region',
              value: _regionLabel(compensation.region),
            ),
            _InfoRow(
              label: 'Source',
              value: _sourceLabel(compensation.origin),
            ),
            _InfoRow(
              label: 'Detected',
              value: _formatDate(compensation.detectedAt),
            ),
            if (compensation.resolvedAt != null)
              _InfoRow(
                label: 'Resolved',
                value: _formatDate(compensation.resolvedAt!),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final CompensationSeverity severity;
  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            severity.name[0].toUpperCase() + severity.name.substring(1),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(CompensationSeverity s) {
    switch (s) {
      case CompensationSeverity.mild:
        return AppColors.secondary;
      case CompensationSeverity.moderate:
        return AppColors.accent;
      case CompensationSeverity.severe:
        return AppColors.accentRed;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _RelatedExercisesList extends StatelessWidget {
  final List<String> exerciseIds;
  const _RelatedExercisesList({required this.exerciseIds});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: exerciseIds
          .map((id) => Card(
                elevation: 0,
                color: AppColors.surfaceVariant,
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.fitness_center_outlined,
                      size: 18, color: AppColors.primary),
                  title: Text(id, style: Theme.of(context).textTheme.bodySmall),
                ),
              ))
          .toList(),
    );
  }
}

class _HistoryTimeline extends StatelessWidget {
  final List<CompensationHistoryEntry> history;
  const _HistoryTimeline({required this.history});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(history)..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      children: sorted.asMap().entries.map((entry) {
        final isLast = entry.key == sorted.length - 1;
        final h = entry.value;
        final statusColor = _statusColor(h.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot + line
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.divider,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _statusLabel(h.status),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(h.date),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      if (h.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          h.note,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Helpers
Color _statusColor(CompensationStatus s) {
  switch (s) {
    case CompensationStatus.active:
      return AppColors.accentRed;
    case CompensationStatus.improving:
      return AppColors.accentGreen;
    case CompensationStatus.resolved:
      return AppColors.textSecondary;
  }
}

String _statusLabel(CompensationStatus s) {
  switch (s) {
    case CompensationStatus.active:
      return 'Active';
    case CompensationStatus.improving:
      return 'Improving';
    case CompensationStatus.resolved:
      return 'Resolved';
  }
}

String _typeLabel(CompensationType t) {
  switch (t) {
    case CompensationType.mobilityDeficit:
      return 'Mobility Deficit';
    case CompensationType.stabilityDeficit:
      return 'Stability Deficit';
    case CompensationType.motorControl:
      return 'Motor Control';
    case CompensationType.strengthImbalance:
      return 'Strength Imbalance';
    case CompensationType.posturalPattern:
      return 'Postural Pattern';
  }
}

String _regionLabel(CompensationRegion r) {
  const labels = {
    CompensationRegion.cervicalSpine: 'Cervical Spine (Neck)',
    CompensationRegion.leftShoulder: 'Left Shoulder',
    CompensationRegion.rightShoulder: 'Right Shoulder',
    CompensationRegion.thoracicSpine: 'Thoracic Spine',
    CompensationRegion.lumbarSpine: 'Lumbar Spine (Lower Back)',
    CompensationRegion.pelvis: 'Pelvis',
    CompensationRegion.leftHip: 'Left Hip',
    CompensationRegion.rightHip: 'Right Hip',
    CompensationRegion.core: 'Core',
    CompensationRegion.leftKnee: 'Left Knee',
    CompensationRegion.rightKnee: 'Right Knee',
    CompensationRegion.leftAnkle: 'Left Ankle',
    CompensationRegion.rightAnkle: 'Right Ankle',
    CompensationRegion.leftFoot: 'Left Foot',
    CompensationRegion.rightFoot: 'Right Foot',
  };
  return labels[r] ?? r.name;
}

String _sourceLabel(CompensationOrigin s) {
  switch (s) {
    case CompensationOrigin.assessment:
      return 'Assessment';
    case CompensationOrigin.journal:
      return 'Journal';
    case CompensationOrigin.manual:
      return 'Manual';
  }
}

String _formatDate(DateTime dt) => '${dt.day} ${_month(dt.month)} ${dt.year}';

String _month(int m) => const [
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
    ][m];
