import 'package:flutter/material.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/compensation.dart';

/// Maps a [CompensationRegion] to a normalised [Offset] on the body
/// silhouette (0.0 to 1.0, where origin is top-left of the widget).
const Map<CompensationRegion, Offset> _regionOffsets = {
  CompensationRegion.cervicalSpine: Offset(0.50, 0.10),
  CompensationRegion.leftShoulder: Offset(0.30, 0.17),
  CompensationRegion.rightShoulder: Offset(0.70, 0.17),
  CompensationRegion.thoracicSpine: Offset(0.50, 0.22),
  CompensationRegion.lumbarSpine: Offset(0.50, 0.33),
  CompensationRegion.pelvis: Offset(0.50, 0.42),
  CompensationRegion.leftHip: Offset(0.35, 0.44),
  CompensationRegion.rightHip: Offset(0.65, 0.44),
  CompensationRegion.core: Offset(0.50, 0.37),
  CompensationRegion.leftKnee: Offset(0.36, 0.65),
  CompensationRegion.rightKnee: Offset(0.64, 0.65),
  CompensationRegion.leftAnkle: Offset(0.36, 0.88),
  CompensationRegion.rightAnkle: Offset(0.64, 0.88),
  CompensationRegion.leftFoot: Offset(0.36, 0.95),
  CompensationRegion.rightFoot: Offset(0.64, 0.95),
};

Color _severityColor(CompensationSeverity severity) {
  switch (severity) {
    case CompensationSeverity.mild:
      return AppColors.severityMild;
    case CompensationSeverity.moderate:
      return AppColors.severityModerate;
    case CompensationSeverity.severe:
      return AppColors.severitySignificant;
  }
}

Color _statusGlow(CompensationStatus status, CompensationSeverity severity) {
  switch (status) {
    case CompensationStatus.active:
      return _severityColor(severity);
    case CompensationStatus.improving:
      return AppColors.severityImproving;
    case CompensationStatus.resolved:
      return AppColors.severityResolved;
  }
}

/// Displays a simplified body silhouette with coloured dot markers for each
/// compensation. Tapping a dot calls [onRegionTap].
class CompensationBodyMap extends StatelessWidget {
  final List<Compensation> compensations;
  final void Function(Compensation)? onRegionTap;

  const CompensationBodyMap({
    super.key,
    required this.compensations,
    this.onRegionTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isInfinite
            ? width * 2.0
            : constraints.maxHeight;

        return SizedBox(
          key: AppKeys.compensationBodyMap,
          width: width,
          height: height,
          child: Stack(
            children: [
              // Body silhouette
              Positioned.fill(
                child: CustomPaint(painter: _BodySilhouettePainter()),
              ),
              // Compensation markers
              ...compensations.map((c) {
                final offset = _regionOffsets[c.region];
                if (offset == null) return const SizedBox.shrink();
                final x = offset.dx * width;
                final y = offset.dy * height;
                return Positioned(
                  left: x - 14,
                  top: y - 14,
                  child: _CompensationDot(
                    compensation: c,
                    onTap: onRegionTap != null ? () => onRegionTap!(c) : null,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _CompensationDot extends StatelessWidget {
  final Compensation compensation;
  final VoidCallback? onTap;

  const _CompensationDot({required this.compensation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final glow = _statusGlow(compensation.status, compensation.severity);
    final opacity = switch (compensation.status) {
      CompensationStatus.active => 0.85,
      CompensationStatus.improving => 0.75,
      CompensationStatus.resolved => 0.5,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: glow.withValues(alpha: opacity),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _statusIcon(compensation.status),
          color: AppColors.textOnPrimary,
          size: 14,
        ),
      ),
    );
  }

  IconData _statusIcon(CompensationStatus status) {
    switch (status) {
      case CompensationStatus.active:
        return Icons.circle;
      case CompensationStatus.improving:
        return Icons.trending_up_rounded;
      case CompensationStatus.resolved:
        return Icons.check_rounded;
    }
  }
}

/// Simplified body silhouette drawn with canvas primitives.
class _BodySilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceRaisedDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Head
    final headCenter = Offset(w * 0.5, h * 0.055);
    final headRadius = w * 0.085;
    canvas.drawCircle(headCenter, headRadius, paint);
    canvas.drawCircle(headCenter, headRadius, strokePaint);

    // Torso
    final torsoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.12, w * 0.40, h * 0.32),
      const Radius.circular(12),
    );
    canvas.drawRRect(torsoRect, paint);
    canvas.drawRRect(torsoRect, strokePaint);

    // Left arm
    _drawLimb(canvas, paint, strokePaint, Offset(w * 0.28, h * 0.14),
        Offset(w * 0.15, h * 0.40), w * 0.055);
    // Right arm
    _drawLimb(canvas, paint, strokePaint, Offset(w * 0.72, h * 0.14),
        Offset(w * 0.85, h * 0.40), w * 0.055);

    // Left thigh + shin
    _drawLimb(canvas, paint, strokePaint, Offset(w * 0.415, h * 0.44),
        Offset(w * 0.38, h * 0.70), w * 0.065);
    _drawLimb(canvas, paint, strokePaint, Offset(w * 0.38, h * 0.70),
        Offset(w * 0.36, h * 0.92), w * 0.055);

    // Right thigh + shin
    _drawLimb(canvas, paint, strokePaint, Offset(w * 0.585, h * 0.44),
        Offset(w * 0.62, h * 0.70), w * 0.065);
    _drawLimb(canvas, paint, strokePaint, Offset(w * 0.62, h * 0.70),
        Offset(w * 0.64, h * 0.92), w * 0.055);
  }

  void _drawLimb(Canvas canvas, Paint fill, Paint stroke, Offset top,
      Offset bottom, double radius) {
    final path = _roundedLimb(top, bottom, radius);
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  Path _roundedLimb(Offset top, Offset bottom, double radius) {
    final dx = radius * 0.5 * (bottom.dy - top.dy).sign;
    final path = Path();
    path.moveTo(top.dx - dx, top.dy);
    path.lineTo(bottom.dx - dx, bottom.dy);
    path.arcToPoint(
      Offset(bottom.dx + dx, bottom.dy),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(top.dx + dx, top.dy);
    path.arcToPoint(
      Offset(top.dx - dx, top.dy),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
