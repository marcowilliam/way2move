import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:way2move/features/auth/domain/repositories/auth_repository.dart';
import 'package:way2move/features/auth/presentation/pages/sign_up_page.dart';

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
      child: const MaterialApp(home: SignUpPage()),
    );
  }

  group('SignUpPage', () {
    testWidgets('shows all required fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(AppKeys.nameField), findsOneWidget);
      expect(find.byKey(AppKeys.emailField), findsOneWidget);
      expect(find.byKey(AppKeys.passwordField), findsOneWidget);
      expect(find.byKey(AppKeys.confirmPasswordField), findsOneWidget);
      expect(find.byKey(AppKeys.submitButton), findsOneWidget);
    });

    testWidgets('shows error when name is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(find.byKey(AppKeys.nameField), 'Test User');
      await tester.enterText(
          find.byKey(AppKeys.emailField), 'test@way2move.com');
      await tester.enterText(find.byKey(AppKeys.passwordField), 'Password1!');
      await tester.enterText(
          find.byKey(AppKeys.confirmPasswordField), 'DifferentPass!');
      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(find.byKey(AppKeys.nameField), 'Test User');
      await tester.enterText(
          find.byKey(AppKeys.emailField), 'test@way2move.com');
      await tester.enterText(find.byKey(AppKeys.passwordField), 'short');
      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();

      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows email-in-use error from repository', (tester) async {
      when(() => mockRepo.signUp(any(), any(), any())).thenAnswer(
          (_) async => const Left(AuthFailure('email-already-in-use')));

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.enterText(find.byKey(AppKeys.nameField), 'Test User');
      await tester.enterText(
          find.byKey(AppKeys.emailField), 'existing@way2move.com');
      await tester.enterText(find.byKey(AppKeys.passwordField), 'Password1!');
      await tester.enterText(
          find.byKey(AppKeys.confirmPasswordField), 'Password1!');
      await tester.tap(find.byKey(AppKeys.submitButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('An account with this email already exists.'),
          findsOneWidget);
    });
  });
}
