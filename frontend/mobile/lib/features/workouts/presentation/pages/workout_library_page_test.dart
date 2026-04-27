import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';
import '../providers/workouts_provider.dart';
import 'workout_library_page.dart';

void main() {
  group('WorkoutLibraryPage', () {
    testWidgets('renders empty state when there are no workouts',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u1'),
            workoutsProvider(null)
                .overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(home: WorkoutLibraryPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workout_library_empty')), findsOneWidget);
    });

    testWidgets('renders workout cards when workouts are present',
        (tester) async {
      const workout = Workout(
        id: 'ground-up',
        userId: 'u1',
        name: 'From the Ground Up',
        kind: WorkoutKind.fromGroundUp,
        focus: 'Foot, hip, posterior chain',
        iconEmoji: '🌱',
        estimatedMinutes: 25,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWith((ref) => 'u1'),
            workoutsProvider(null)
                .overrideWith((ref) => Stream.value(const [workout])),
          ],
          child: const MaterialApp(home: WorkoutLibraryPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('From the Ground Up'), findsOneWidget);
      expect(find.byKey(const Key('workout_library_list')), findsOneWidget);
    });
  });
}
