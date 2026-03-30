import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/progress_photo.dart';
import '../providers/progress_providers.dart';
import '../widgets/photo_comparison_view.dart';

class PhotoTimelinePage extends ConsumerWidget {
  const PhotoTimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photoTimelineNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Timeline')),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Text('No progress photos yet. Start capturing!'),
            );
          }
          final grouped = _groupByDate(photos);
          final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dates.length,
            itemBuilder: (_, i) {
              final date = dates[i];
              final datePhotos = grouped[date]!;
              return _DateGroup(
                date: date,
                photos: datePhotos,
                theme: theme,
              );
            },
          );
        },
      ),
      floatingActionButton: photosAsync.valueOrNull != null &&
              photosAsync.valueOrNull!.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => _openComparison(context, photosAsync.value!),
              icon: const Icon(Icons.compare),
              label: const Text('Compare'),
            )
          : null,
    );
  }

  Map<DateTime, List<ProgressPhoto>> _groupByDate(List<ProgressPhoto> photos) {
    final map = <DateTime, List<ProgressPhoto>>{};
    for (final p in photos) {
      final key = DateTime(p.date.year, p.date.month, p.date.day);
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  void _openComparison(BuildContext context, List<ProgressPhoto> photos) {
    if (photos.length < 2) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Compare', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Expanded(
                child: PhotoComparisonView(
                  photoA: photos.first,
                  photoB: photos[1],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<ProgressPhoto> photos;
  final ThemeData theme;

  const _DateGroup({
    required this.date,
    required this.photos,
    required this.theme,
  });

  String _angleLabel(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.sideLeft:
        return 'Side L';
      case PhotoAngle.sideRight:
        return 'Side R';
      case PhotoAngle.back:
        return 'Back';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            DateFormat('EEEE, d MMM yyyy').format(date),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final photo = photos[i];
              return GestureDetector(
                onTap: () => _openFullScreen(context, photo),
                child: SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photo.photoUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _angleLabel(photo.angle),
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _openFullScreen(BuildContext context, ProgressPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhoto(photo: photo),
      ),
    );
  }
}

class _FullScreenPhoto extends StatelessWidget {
  final ProgressPhoto photo;
  const _FullScreenPhoto({required this.photo});

  String _angleLabel(PhotoAngle angle) {
    switch (angle) {
      case PhotoAngle.front:
        return 'Front';
      case PhotoAngle.sideLeft:
        return 'Side L';
      case PhotoAngle.sideRight:
        return 'Side R';
      case PhotoAngle.back:
        return 'Back';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          '${_angleLabel(photo.angle)} — ${DateFormat('d MMM yyyy').format(photo.date)}',
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            photo.photoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 64),
          ),
        ),
      ),
    );
  }
}
