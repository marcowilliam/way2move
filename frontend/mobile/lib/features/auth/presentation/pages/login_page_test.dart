import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:way2move/features/auth/domain/repositories/auth_repository.dart';
import 'package:way2move/features/auth/presentation/pages/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.authStateChanges())
        .thenAnswer((_) => Stream.value(null));
    when(() => mockRepo.currentUser()).thenAnswer((_) async => null);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  group('LoginPage', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(AppKeys.emailField), findsOneWidget);
      expect(find.byKey(AppKeys.passwordField), findsOneWidget);
      expect(find.byKey(AppKeys.submitButton), findsOneWidget);
    });

    testWidgets('shows error when email is empty on submit', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('shows error when email is invalid', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(
          find.byKey(AppKeys.emailField), 'not-an-email');
      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(
          find.byKey(AppKeys.emailField), 'test@way2move.com');
      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows auth error message on wrong password', (tester) async {
      when(() => mockRepo.signIn(any(), any())).thenAnswer(
          (_) async => const Left(AuthFailure('wrong-password')));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(
          find.byKey(AppKeys.emailField), 'test@way2move.com');
      await tester.enterText(find.byKey(AppKeys.passwordField), 'wrongpass');
      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });

    testWidgets('shows create account button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(AppKeys.createAccountButton), findsOneWidget);
    });

    testWidgets('shows Google and Apple sign-in buttons', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(AppKeys.googleSignInButton), findsOneWidget);
      expect(find.byKey(AppKeys.appleSignInButton), findsOneWidget);
    });
  });
}
