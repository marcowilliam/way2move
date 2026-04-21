import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Way2Move logo mark — "The Rooted 2".
///
/// Source: docs/branding/logo/mark.svg. A single continuous stroke — a
/// symmetric arch at the top, a diagonal down-left, a long horizontal base
/// forming a subtle pedestal. Rendered as a [CustomPaint] so the mark scales
/// crisply at any size without bundling SVGs or pulling in flutter_svg.
class Way2MoveLogoMark extends StatelessWidget {
  const Way2MoveLogoMark({
    super.key,
    this.size = 96,
    this.color,
  });

  final double size;

  /// Override the stroke color. Defaults to [AppColors.primary] (terracotta)
  /// on light surfaces and [AppColors.textPrimaryDark] (warm paper) on dark
  /// surfaces — callers should pass an explicit color when they already know
  /// the contrast target.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final resolved = color ??
        (brightness == Brightness.dark
            ? AppColors.textPrimaryDark
            : AppColors.primary);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RootedTwoPainter(color: resolved),
      ),
    );
  }
}

class _RootedTwoPainter extends CustomPainter {
  _RootedTwoPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Reference canvas is 256×256 (matches docs/branding/logo/mark.svg).
    final scale = size.width / 256;
    final stroke = 22.0 * scale;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // M 64 94  C 64 38, 192 38, 192 94  L 52 214  L 224 214
    final path = Path()
      ..moveTo(64 * scale, 94 * scale)
      ..cubicTo(
        64 * scale, 38 * scale, // ctrl 1
        192 * scale, 38 * scale, // ctrl 2
        192 * scale, 94 * scale, // end
      )
      ..lineTo(52 * scale, 214 * scale)
      ..lineTo(224 * scale, 214 * scale);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RootedTwoPainter old) => old.color != color;
}
