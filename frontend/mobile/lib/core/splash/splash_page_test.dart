import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/splash/splash_page.dart';
import 'package:way2move/core/theme/app_theme.dart';
import 'package:way2move/shared/widgets/way2move_logo_mark.dart';

void main() {
  group('SplashPage', () {
    testWidgets('renders mark and wordmark', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SplashPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(Way2MoveLogoMark), findsOneWidget);
      expect(find.text('WAY'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('MOVE'), findsOneWidget);
    });

    testWidgets('wordmark fades in after the mark (staggered entrance)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SplashPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      FadeTransition firstFade(Finder f) => tester.widget<FadeTransition>(find
          .ancestor(
            of: f,
            matching: find.byType(FadeTransition),
          )
          .first);

      // The wordmark's interval starts at 22% of the 900ms timeline, so at
      // 16ms it is still nearly fully hidden.
      final earlyWordmarkOpacity =
          firstFade(find.text('WAY')).opacity.value;
      expect(earlyWordmarkOpacity, lessThan(0.1));

      // After the full entrance the wordmark is fully visible.
      await tester.pump(const Duration(milliseconds: 950));
      final lateWordmarkOpacity =
          firstFade(find.text('WAY')).opacity.value;
      expect(lateWordmarkOpacity, greaterThan(0.9));
    });
  });
}
