# Testing Rules

## Philosophy
Tests exist to **discover bugs**, not to prove code works. Design each test to challenge one specific scenario — a boundary condition, an error path, an edge case. If a test only ever passes, it's not doing its job.

---

## TDD workflow (mandatory)
1. Write a failing test that describes the expected behavior (red)
2. Write the minimum code to make it pass (green)
3. Refactor without breaking tests (refactor)

Never write implementation code before a test exists for it.

---

## Test types and file naming

### Unit tests — `*_test.dart` / `*.test.ts`
Test a single unit of logic in complete isolation. Any external dependency (database, HTTP, Firebase, file system, third-party SDK) is replaced with a mock or fake.

- Dart: `auth_service_test.dart` (co-located with `auth_service.dart`)
- TypeScript: `calculateXp.test.ts` (co-located with `calculateXp.ts`)

**When to mock:** Only mock things that cross a process or network boundary — databases, HTTP calls, Firebase SDKs, file system. Pure functions, value objects, domain entities, and models have no external deps and are tested directly without mocking.

```dart
// auth_service_test.dart — external Firebase dep is mocked
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

test('returns AuthFailure on wrong-password error code', () async {
  when(() => mockAuth.signInWithEmailAndPassword(email: any(), password: any()))
      .thenThrow(FirebaseAuthException(code: 'wrong-password'));

  final result = await authService.signIn('a@b.com', 'bad');

  expect(result, Left(AuthFailure('wrong-password')));
});
```

```dart
// session_model_test.dart — pure Dart model, no mocks needed
test('fromFirestore maps date timestamp to DateTime', () {
  final doc = fakeFirestoreDoc({'date': Timestamp(1700000000, 0), ...});
  final model = SessionModel.fromFirestore(doc);
  expect(model.date, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
});
```

---

### Integration tests — `*_int_test.dart` / `*.int.test.ts`
Test a unit together with its real external dependencies. The same artifact (e.g., `SessionRepository`) can and should have both a unit test file and an integration test file — they test different things.

- Dart: `session_repository_int_test.dart`
- TypeScript: `onSessionCreate.int.test.ts`

Integration tests run against the **Firebase Local Emulator** — never against production.

The integration test verifies that the code works end-to-end with the real dependency: the correct documents are written to Firestore, the correct auth state is set, the correct XP events are created.

```dart
// session_repository_int_test.dart
// Emulator must be running: firebase emulators:start

void main() {
  setUpAll(() async {
    await setupFirebaseEmulators(); // connects to localhost emulator
  });

  tearDown(() async {
    await clearFirestoreEmulator(); // wipe data between tests
  });

  test('logSession writes document to sessions collection', () async {
    final repo = SessionRepositoryImpl(FirebaseFirestore.instance);
    final input = SessionInput(date: DateTime.now(), disciplineId: 'aff', flyerIds: ['user1']);

    final result = await repo.logSession(input);

    expect(result.isRight(), true);
    final doc = await FirebaseFirestore.instance.collection('sessions').doc(result.getRight().id).get();
    expect(doc.exists, true);
    expect(doc.data()!['flyerIds'], contains('user1'));
  });

  test('logSession returns NotFoundFailure when discipline does not exist', () async {
    final repo = SessionRepositoryImpl(FirebaseFirestore.instance);
    final input = SessionInput(date: DateTime.now(), disciplineId: 'nonexistent', flyerIds: ['user1']);

    final result = await repo.logSession(input);

    expect(result, Left(NotFoundFailure()));
  });
}
```

```typescript
// onSessionCreate.int.test.ts
// Emulator must be running

describe('onSessionCreate trigger', () => {
  beforeEach(async () => {
    await clearFirestoreEmulator();
  });

  it('creates an xpEvent document for each flyer', async () => {
    const db = admin.firestore();
    await db.collection('sessions').doc('sess1').set({
      flyerIds: ['user1', 'user2'],
      coachIds: [],
      date: admin.firestore.Timestamp.now(),
    });

    // wait for the trigger to fire
    await waitFor(() => db.collection('xpEvents').where('userId', '==', 'user1').get()
      .then(snap => expect(snap.size).toBe(1)));
  });

  it('does not create xpEvent for coaches', async () => {
    const db = admin.firestore();
    await db.collection('sessions').doc('sess2').set({
      flyerIds: ['user1'],
      coachIds: ['coach1'],
      date: admin.firestore.Timestamp.now(),
    });

    await waitFor(() => db.collection('xpEvents').where('userId', '==', 'user1').get()
      .then(snap => expect(snap.size).toBe(1)));

    const coachEvents = await db.collection('xpEvents').where('userId', '==', 'coach1').get();
    expect(coachEvents.size).toBe(0);
  });
});
```

---

### E2E tests — `integration_test/` (Flutter) / `e2e/` (web + functions)
Test the complete system as a user would experience it. Prepare real database state, interact through the real interface (UI or HTTP), and validate outputs — response body, status codes, error shapes, database side-effects.

**Flutter E2E** (runs on real emulator, hits Firebase emulator):
```dart
// integration_test/auth_flow_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupFirebaseEmulators();
    await clearFirestoreEmulator();
  });

  testWidgets('user signs up, sees home screen, XP starts at 0', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Tap "Create account"
    await tester.tap(find.byKey(Keys.createAccountButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Keys.emailField), 'test@way2fly.com');
    await tester.enterText(find.byKey(Keys.passwordField), 'Pass1234!');
    await tester.tap(find.byKey(Keys.submitButton));
    await tester.pumpAndSettle();

    // Assert: home screen is shown
    expect(find.byKey(Keys.homeScreen), findsOneWidget);

    // Assert: Firestore user doc was created with xp = 0
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    expect(doc.data()!['totalXp'], 0);
    expect(doc.data()!['roles'], contains('flyer'));
  });
}
```

**Cloud Functions E2E** (callable functions via HTTP):
```typescript
// e2e/calculateXp.e2e.test.ts
// Tests the Callable function as a client would call it

import { getFunctions, httpsCallable, connectFunctionsEmulator } from 'firebase/functions';

describe('calculateXp (E2E)', () => {
  let functions: Functions;

  beforeAll(() => {
    functions = getFunctions();
    connectFunctionsEmulator(functions, 'localhost', 5001);
  });

  beforeEach(async () => {
    await clearFirestoreEmulator();
    await signInTestUser(); // authenticate via Auth emulator
  });

  it('returns xp value for a valid session', async () => {
    // Prepare: seed a session document
    await seedSession({ id: 'sess1', flyerIds: [testUserId], disciplineId: 'aff' });

    // Act: call the function
    const fn = httpsCallable(functions, 'calculateXp');
    const result = await fn({ sessionId: 'sess1' });

    // Assert: response shape and value
    expect(result.data).toMatchObject({ xp: expect.any(Number) });
    expect((result.data as any).xp).toBeGreaterThan(0);
  });

  it('returns UNAUTHENTICATED error when called without auth', async () => {
    await signOut();

    const fn = httpsCallable(functions, 'calculateXp');

    await expect(fn({ sessionId: 'sess1' }))
      .rejects.toMatchObject({ code: 'functions/unauthenticated' });
  });

  it('returns INVALID_ARGUMENT error when sessionId is missing', async () => {
    const fn = httpsCallable(functions, 'calculateXp');

    await expect(fn({}))
      .rejects.toMatchObject({ code: 'functions/invalid-argument' });
  });

  it('returns NOT_FOUND error when session does not exist', async () => {
    const fn = httpsCallable(functions, 'calculateXp');

    await expect(fn({ sessionId: 'does-not-exist' }))
      .rejects.toMatchObject({ code: 'functions/not-found' });
  });
});
```

---

## One scenario per test
Each test covers exactly one scenario. Tests must be independent — they do not share state, they do not rely on execution order, and a failure in one test must not affect any other.

**Wrong — multiple scenarios, shared state:**
```dart
test('sign up then log session then check XP', () async {
  // signs up, logs a session, and checks XP in one test
  // if the sign-up step fails, we learn nothing about session logging
});
```

**Right — one scenario each:**
```dart
test('sign up creates user document with default flyer role', ...);
test('logging a session awards base XP to the flyer', ...);
test('XP total on user document reflects sum of all xpEvents', ...);
```

Each test must:
1. Set up its own preconditions (arrange)
2. Perform exactly one action (act)
3. Assert only the outcome of that action (assert)
4. Clean up or rely on `tearDown`/`beforeEach` to reset state

---

## Test file summary

| Test type | Dart file name | TypeScript file name | What is mocked |
|---|---|---|---|
| Unit | `foo_test.dart` | `foo.test.ts` | External deps (DB, HTTP, Firebase) |
| Integration | `foo_int_test.dart` | `foo.int.test.ts` | Nothing — uses real emulator |
| E2E | `integration_test/*.dart` | `e2e/*.e2e.test.ts` | Nothing — full system |

---

## Running tests

```bash
# Flutter unit + widget tests
flutter test

# Flutter unit tests with coverage
flutter test --coverage

# Flutter integration tests (emulator must be running)
flutter test integration_test/ -d <emulator_id>

# Cloud Functions unit tests
cd backend/functions && npm test

# Cloud Functions integration tests (emulator must be running)
cd backend/functions && npm run test:int

# Cloud Functions E2E tests (full emulator stack must be running)
cd backend/functions && npm run test:e2e
```

---

## Pre-commit vs pre-push

| Hook | Runs | Why fast/slow |
|---|---|---|
| pre-commit | Format + lint | No tests — must be < 5s |
| pre-push | Unit + integration tests | Full confidence before remote |

E2E tests run in CI only (GitHub Actions), not on pre-push.

Never skip hooks (`--no-verify`) — if a hook fails, fix the underlying issue.

---

## Coverage targets

| Layer | Target |
|---|---|
| Domain (use cases, entities) | 100% |
| Data (models, repositories) | >80% |
| Presentation | Widget tests for all meaningful UI states |
| Cloud Functions | >80% on business logic functions |
