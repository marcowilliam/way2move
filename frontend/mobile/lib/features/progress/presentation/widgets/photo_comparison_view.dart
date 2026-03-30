import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/progress_photo.dart';

class PhotoComparisonView extends StatelessWidget {
  final ProgressPhoto photoA;
  final ProgressPhoto photoB;

  const PhotoComparisonView({
    super.key,
    required this.photoA,
    required this.photoB,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Row(
      children: [
        Expanded(
            child: _PhotoPanel(photo: photoA, dateFmt: dateFmt, theme: theme)),
        const SizedBox(width: 4),
        Expanded(
            child: _PhotoPanel(photo: photoB, dateFmt: dateFmt, theme: theme)),
      ],
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  final ProgressPhoto photo;
  final DateFormat dateFmt;
  final ThemeData theme;

  const _PhotoPanel({
    required this.photo,
    required this.dateFmt,
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
          style: theme.textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          dateFmt.format(photo.date),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
