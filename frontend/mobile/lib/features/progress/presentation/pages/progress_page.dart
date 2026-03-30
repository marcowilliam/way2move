import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/progress_photo.dart';
import '../providers/progress_providers.dart';
import '../widgets/weight_log_entry.dart';
import '../widgets/weight_trend_chart.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final photosAsync = ref.watch(photoTimelineNotifierProvider);
    final weightAsync = ref.watch(weightLogsNotifierProvider);

    return Scaffold(
      key: AppKeys.progressPage,
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Photos section ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Photos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
              TextButton(
                onPressed: () => context.push(Routes.photoTimeline),
                child: const Text('View Timeline'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PhotoAngleGrid(
            photos: photosAsync.valueOrNull ?? [],
            onCapture: () => context.push(Routes.photoCapture),
          ),
          const SizedBox(height: 24),

          // ── Weight section ──────────────────────────────────────────────
          Text('Weight',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 8),
          WeightLogEntry(
            onLog: (weight, unit, notes) {
              if (userId == null) return;
              ref
                  .read(weightLogsNotifierProvider.notifier)
                  .addWeight(weight, unit, userId, notes: notes);
            },
          ),
          const SizedBox(height: 16),
          weightAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (logs) => WeightTrendChart(logs: logs),
          ),
        ],
      ),
    );
  }
}

class _PhotoAngleGrid extends StatelessWidget {
  final List<ProgressPhoto> photos;
  final VoidCallback onCapture;

  const _PhotoAngleGrid({required this.photos, required this.onCapture});

  ProgressPhoto? _latestFor(PhotoAngle angle) {
    final matches = photos.where((p) => p.angle == angle).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    const angles = [
      (PhotoAngle.front, 'Front'),
      (PhotoAngle.sideLeft, 'Side L'),
      (PhotoAngle.sideRight, 'Side R'),
      (PhotoAngle.back, 'Back'),
    ];
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: angles.map((entry) {
        final (angle, label) = entry;
        final photo = _latestFor(angle);
        return GestureDetector(
          onTap: onCapture,
          child: Container(
            key: Key('progress_photo_angle_${angle.name}'),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: photo != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          photo.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 32, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }).toList(),
    );
  }
}
