import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/theme/app_colors.dart';
import 'package:way2move/core/theme/app_theme.dart';

/// Typography is exercised through the full theme via widget tests. Google
/// Fonts performs async asset loading that conflicts with unit-level tests,
/// but rendering a widget and inspecting the resolved TextStyle via
/// DefaultTextStyle.of / Theme.of works cleanly.
void main() {
  group('AppTypography (through theme)', () {
    testWidgets('dark theme exposes display sizes 52 / 40 / 32',
        (tester) async {
      late TextTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = Theme.of(context).textTheme;
              return const Scaffold();
            },
          ),
        ),
      );
      expect(resolved.displayLarge?.fontSize, 52);
      expect(resolved.displayMedium?.fontSize, 40);
      expect(resolved.displaySmall?.fontSize, 32);
    });

    testWidgets('dark theme exposes headline sizes 28 / 22 / 18',
        (tester) async {
      late TextTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = Theme.of(context).textTheme;
              return const Scaffold();
            },
          ),
        ),
      );
      expect(resolved.headlineLarge?.fontSize, 28);
      expect(resolved.headlineMedium?.fontSize, 22);
      expect(resolved.headlineSmall?.fontSize, 18);
    });

    testWidgets('label tracking increases with smaller size', (tester) async {
      late TextTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = Theme.of(context).textTheme;
              return const Scaffold();
            },
          ),
        ),
      );
      expect(resolved.labelLarge?.letterSpacing, 0.4);
      expect(resolved.labelMedium?.letterSpacing, 0.6);
      expect(resolved.labelSmall?.letterSpacing, 0.8);
    });

    testWidgets('body primary uses brand text color in dark mode',
        (tester) async {
      late TextTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = Theme.of(context).textTheme;
              return const Scaffold();
            },
          ),
        ),
      );
      expect(resolved.bodyLarge?.color, AppColors.textPrimaryDark);
      expect(resolved.bodyMedium?.color, AppColors.textSecondaryDark);
    });

    testWidgets('display weights are all 700 (bold serif hero)',
        (tester) async {
      late TextTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = Theme.of(context).textTheme;
              return const Scaffold();
            },
          ),
        ),
      );
      for (final style in [
        resolved.displayLarge,
        resolved.displayMedium,
        resolved.displaySmall,
      ]) {
        expect(style?.fontWeight, FontWeight.w700);
      }
    });
  });
}
