# Flutter Frontend — Testing

## Tools
- `flutter_test` — unit and widget tests (built into Flutter SDK)
- `mocktail` — mock generation (not mockito; no code generation required)
- `integration_test` — end-to-end tests on real emulator + Firebase emulator
- `riverpod` test utilities — `ProviderContainer` for testing providers in isolation

## Test file location
Co-locate test files with source files:
```
features/auth/domain/usecases/sign_in.dart
features/auth/domain/usecases/sign_in_test.dart   ← next to source
```
Integration tests live in `integration_test/` at the package root.

## TDD workflow
1. Write the failing test (red)
2. Write the minimum implementation to pass (green)
3. Refactor without breaking tests (refactor)

Never write implementation before the test exists.

## Unit tests — use cases and repositories

Test use cases by mocking the abstract repository interface:
```dart
// sign_in_test.dart
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SignIn signIn;

  setUp(() {
    mockRepo = MockAuthRepository();
    signIn = SignIn(mockRepo);
  });

  group('SignIn', () {
    test('returns User on success', () async {
      final user = User(id: '1', email: 'test@test.com', name: 'Test');
      when(() => mockRepo.signIn(any(), any())).thenAnswer((_) async => Right(user));

      final result = await signIn('test@test.com', 'password');

      expect(result, Right(user));
    });

    test('returns AuthFailure on wrong password', () async {
      when(() => mockRepo.signIn(any(), any()))
          .thenAnswer((_) async => Left(AuthFailure('wrong-password')));

      final result = await signIn('test@test.com', 'wrong');

      expect(result.isLeft(), true);
    });
  });
}
```

## Unit tests — Riverpod providers

Use `ProviderContainer` to test providers without a widget tree:
```dart
test('authNotifier starts in loading state', () async {
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(mockRepo),
  ]);
  addTearDown(container.dispose);

  final state = container.read(authNotifierProvider);
  expect(state, const AsyncLoading<User?>());
});
```

## Widget tests

Test widgets by pumping them in isolation with `WidgetTester`:
```dart
testWidgets('LoginPage shows error message on invalid email', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      child: const MaterialApp(home: LoginPage()),
    ),
  );

  await tester.enterText(find.byKey(Keys.emailField), 'not-an-email');
  await tester.tap(find.byKey(Keys.submitButton));
  await tester.pump();

  expect(find.text('Enter a valid email'), findsOneWidget);
});
```

Rules for widget tests:
- Find widgets by `Key` (set meaningful keys in production code) or semantic label
- Never find by widget type alone unless it's truly unique (`find.byType(CircularProgressIndicator)`)
- Never find by display text that will change with translations
- Pump after every user interaction: `await tester.pump()`

## Integration tests

Integration tests run on a real Android emulator and connect to the Firebase emulator:
```dart
// integration_test/auth_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can sign up and see home screen', (tester) async {
    await tester.pumpWidget(const App());
    // ... interact with real UI, assertions on real Firebase emulator data
  });
}
```

Run integration tests:
```bash
# Firebase emulator must be running first
flutter test integration_test/auth_flow_test.dart -d <emulator_id>
```

## Coverage requirements
- Domain layer (entities, use cases, repository interfaces): 100%
- Data layer (models, datasources, repository impls): >80%
- Presentation layer: widget tests for all meaningful UI states
- Integration: one happy-path test per major user flow

## What NOT to test
- Flutter framework internals (widget rendering, Material animations)
- Trivial getters/setters
- `fromJson`/`toJson` that are auto-generated

## Mock conventions (mocktail)
```dart
// Define mock at top of test file
class MockSessionRepository extends Mock implements SessionRepository {}

// Register fallback values for custom types (required by mocktail)
setUpAll(() {
  registerFallbackValue(Session.empty());
});

// Stub
when(() => mockRepo.logSession(any())).thenAnswer((_) async => Right(session));

// Verify
verify(() => mockRepo.logSession(captureAny())).called(1);
```
