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
import 'package:way2move/features/profile/presentation/pages/onboarding_flow.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

Widget _buildTestWidget({ProfileRepository? repo}) {
  final mockRepo = repo ?? MockProfileRepository();
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingFlow(),
          ),
          GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(body: Text('Home')),
          ),
        ],
      ),
    ),
  );
}

void main() {
  late MockProfileRepository mockRepo;

  setUp(() {
    mockRepo = MockProfileRepository();
  });

  setUpAll(() {
    registerFallbackValue(UserProfile(
      id: 'fallback',
      name: 'Fallback',
      email: 'f@f.com',
      createdAt: DateTime(2024),
    ));
  });

  group('OnboardingFlow', () {
    testWidgets('shows welcome screen with Welcome title', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.onboardingFlow), findsOneWidget);
      expect(find.text('Welcome to Way2Move'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('tapping Continue advances to basic info step', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      expect(find.text('About You'), findsOneWidget);
      expect(find.byKey(AppKeys.onboardingNameField), findsOneWidget);
      expect(find.byKey(AppKeys.onboardingAgeField), findsOneWidget);
    });

    testWidgets('back button appears after first step', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      // No back button on welcome
      expect(find.byKey(AppKeys.onboardingBackButton), findsNothing);

      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      // Back button now visible
      expect(find.byKey(AppKeys.onboardingBackButton), findsOneWidget);
    });

    testWidgets('navigates back when back button is tapped', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      // Go to step 2
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byKey(AppKeys.onboardingBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Way2Move'), findsOneWidget);
    });

    testWidgets('goal step shows all training goal options', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      // Advance to welcome -> basic info -> goal (step 2)
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      expect(find.text("What's your main goal?"), findsOneWidget);
      expect(find.text('General Fitness'), findsOneWidget);
      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Mobility'), findsOneWidget);
      expect(find.text('Longevity'), findsOneWidget);
      expect(find.text('Sport-Specific'), findsOneWidget);
      expect(find.text('Rehab'), findsOneWidget);
    });

    testWidgets('Continue disabled on goal step until goal selected',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      // Navigate to goal step
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      // Continue button disabled
      final button =
          tester.widget<FilledButton>(find.byKey(AppKeys.onboardingNextButton));
      expect(button.onPressed, isNull);

      // Select a goal
      await tester.tap(find.text('Strength'));
      await tester.pump();

      // Continue now enabled
      final buttonAfter =
          tester.widget<FilledButton>(find.byKey(AppKeys.onboardingNextButton));
      expect(buttonAfter.onPressed, isNotNull);
    });

    testWidgets('sports step shows filter chips for sport selection',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      // Navigate to sports step (step 4): welcome -> basic -> goal -> activity -> sports
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(AppKeys.onboardingNextButton));
        await tester.pumpAndSettle();
      }
      // Select goal
      await tester.tap(find.text('Strength'));
      await tester.pump();
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      // Select activity level
      await tester.tap(find.text('Moderately Active'));
      await tester.pump();
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      expect(find.text('What sports or activities do you do?'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Climbing'), findsOneWidget);
    });

    testWidgets('skip button calls completeOnboarding and navigates home',
        (tester) async {
      when(() => mockRepo.updateProfile(any()))
          .thenAnswer((_) async => Right(UserProfile(
                id: 'test-uid',
                name: 'Athlete',
                email: '',
                onboardingComplete: true,
                createdAt: DateTime(2024),
              )));

      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.onboardingSkipButton));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      verify(() => mockRepo.updateProfile(any())).called(1);
    });

    testWidgets('last step shows Get Started button', (tester) async {
      await tester.pumpWidget(_buildTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      // Navigate through all steps
      // Step 0: welcome
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      // Step 1: basic info
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      // Step 2: goal — select one
      await tester.tap(find.text('Mobility'));
      await tester.pump();
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      // Step 3: activity level — select one
      await tester.tap(find.text('Lightly Active'));
      await tester.pump();
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();
      // Step 4: sports
      await tester.tap(find.byKey(AppKeys.onboardingNextButton));
      await tester.pumpAndSettle();

      // Step 5: equipment — should show "Get Started"
      expect(
          find.text('What equipment do you have access to?'), findsOneWidget);
      expect(find.byKey(AppKeys.onboardingDoneButton), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
