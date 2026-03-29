import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:way2move/features/profile/domain/entities/user_profile.dart';
import 'package:way2move/features/profile/domain/repositories/profile_repository.dart';
import 'package:way2move/features/profile/presentation/pages/profile_edit_page.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

final tProfile = UserProfile(
  id: 'uid1',
  name: 'Test User',
  email: 'test@way2move.com',
  age: 30,
  height: 175.0,
  weight: 70.0,
  activityLevel: ActivityLevel.moderatelyActive,
  trainingGoal: TrainingGoal.generalFitness,
  sportsTags: ['running'],
  trainingDaysPerWeek: 3,
  availableEquipment: ['bodyweight', 'dumbbells'],
  onboardingComplete: true,
  createdAt: DateTime(2024),
);

Widget _buildTestWidget({required ProfileRepository repo}) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWithValue('uid1'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Scaffold(body: Text('Profile')),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, __) => const ProfileEditPage(),
              ),
            ],
          ),
        ],
        redirect: (context, state) {
          if (state.matchedLocation == '/profile') {
            return '/profile/edit';
          }
          return null;
        },
      ),
    ),
  );
}

void main() {
  late MockProfileRepository mockRepo;
  late StreamController<UserProfile?> profileStream;

  setUp(() {
    mockRepo = MockProfileRepository();
    profileStream = StreamController<UserProfile?>();
    when(() => mockRepo.watchProfile(any()))
        .thenAnswer((_) => profileStream.stream);
    when(() => mockRepo.getProfile(any()))
        .thenAnswer((_) async => Right(tProfile));
  });

  tearDown(() {
    profileStream.close();
  });

  setUpAll(() {
    registerFallbackValue(tProfile);
  });

  group('ProfileEditPage', () {
    testWidgets('shows loading initially then form with profile data',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pump();

      // Emit profile data
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.profileEditPage), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Training Goal'), findsOneWidget);
      expect(find.text('Activity Level'), findsOneWidget);
    });

    testWidgets('pre-fills name from existing profile', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      // Name field should have existing value
      final nameField = tester.widget<TextField>(find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.controller?.text == 'Test User' &&
            w.decoration?.labelText == 'Display Name',
      ));
      expect(nameField, isNotNull);
    });

    testWidgets('shows Save button in app bar', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('tapping Save calls updateProfile', (tester) async {
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => Right(tProfile));

      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepo.updateProfile(any())).called(1);
    });

    testWidgets('shows training days selector with current value',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      // Training days per week section exists
      expect(find.text('Training Days per Week'), findsOneWidget);
      // Numbers 1-7 should be visible
      expect(find.text('1'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows sports section with filter chips', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      expect(find.text('Sports & Activities'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Climbing'), findsOneWidget);
    });

    testWidgets('shows equipment section with filter chips', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      profileStream.add(tProfile);
      await tester.pumpAndSettle();

      expect(find.text('Available Equipment'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);
      expect(find.text('Dumbbells'), findsOneWidget);
    });
  });
}
