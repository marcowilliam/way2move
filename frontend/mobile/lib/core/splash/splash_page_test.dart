import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/splash/splash_page.dart';
import 'package:way2move/core/theme/app_theme.dart';
import 'package:way2move/shared/widgets/way2move_logo_mark.dart';

void main() {
  group('SplashPage', () {
    testWidgets('renders mark, wordmark, and tagline', (tester) async {
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
      expect(find.text('Train from the ground up.'), findsOneWidget);
    });

    testWidgets('tagline fades in after the mark (staggered entrance)',
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

      // The tagline's interval starts at 56% of the 900ms timeline, so at
      // 16ms it is still fully hidden.
      final earlyTaglineOpacity =
          firstFade(find.text('Train from the ground up.')).opacity.value;
      expect(earlyTaglineOpacity, lessThan(0.05));

      // After the full entrance the tagline is fully visible.
      await tester.pump(const Duration(milliseconds: 950));
      final lateTaglineOpacity =
          firstFade(find.text('Train from the ground up.')).opacity.value;
      expect(lateTaglineOpacity, greaterThan(0.9));
    });
  });
}
