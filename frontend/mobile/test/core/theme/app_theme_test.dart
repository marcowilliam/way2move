import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/theme/app_colors.dart';
import 'package:way2move/core/theme/app_spacing.dart';
import 'package:way2move/core/theme/app_theme.dart';

void main() {
  group('AppTheme — light', () {
    testWidgets('brightness is light and primary is Terracotta',
        (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      expect(resolved.brightness, Brightness.light);
      expect(resolved.colorScheme.primary, AppColors.primary);
    });

    testWidgets('scaffold background is Warm Linen', (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      expect(resolved.scaffoldBackgroundColor, AppColors.background);
    });

    testWidgets('card radius is 14 (brand v1 soft curve)', (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      final shape = resolved.cardTheme.shape as RoundedRectangleBorder;
      final radius = shape.borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppSpacing.radiusMd);
    });

    testWidgets(
        'secondary colour is Sage (body-awareness), tertiary is Soft Gold',
        (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      expect(resolved.colorScheme.secondary, AppColors.accent);
      expect(resolved.colorScheme.tertiary, AppColors.reward);
    });
  });

  group('AppTheme — dark', () {
    testWidgets('brightness is dark and background is Warm Charcoal',
        (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      expect(resolved.brightness, Brightness.dark);
      expect(resolved.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    testWidgets('primary remains Terracotta in dark (not a lightened variant)',
        (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      expect(resolved.colorScheme.primary, AppColors.primary);
    });

    testWidgets('dialog radius is 28 (soft modals)', (tester) async {
      late ThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(builder: (c) {
            resolved = Theme.of(c);
            return const Scaffold();
          }),
        ),
      );
      final shape = resolved.dialogTheme.shape as RoundedRectangleBorder;
      final radius = shape.borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppSpacing.radiusXl);
    });
  });
}
