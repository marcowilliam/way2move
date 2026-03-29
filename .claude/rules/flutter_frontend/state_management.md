# Flutter Frontend — State Management

## Tool: Riverpod 2.x (flutter_riverpod + riverpod_annotation)

Riverpod is the sole state management solution. Never use `setState` for anything beyond purely local, ephemeral UI state (e.g. a text field focus toggle). Never use `Provider` (the package) or BLoC.

## Provider types and when to use each

### Provider — static values and services
For things that don't change: DI, constants, computed values derived from other providers.
```dart
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));
});
```

### StateProvider — simple mutable state
For toggles, counters, simple form field values. No async, no business logic.
```dart
final selectedDisciplineProvider = StateProvider<String?>((ref) => null);
```

### AsyncNotifierProvider — async operations with full lifecycle (preferred for async)
For any state that involves loading/error/data. This is the Riverpod 2.x preferred pattern.
```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<User?> build() async {
    final repo = ref.watch(authRepositoryProvider);
    return repo.currentUser();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authRepositoryProvider).signIn(email, password);
      return result.fold((f) => throw f, (user) => user);
    });
  }
}
```

### StreamProvider — Firestore real-time streams
For live data from Firestore. The stream is subscribed automatically, cancelled on disposal.
```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final userSessionsProvider = StreamProvider.family<List<Session>, String>((ref, userId) {
  return ref.watch(sessionRepositoryProvider).watchSessions(userId);
});
```

### FutureProvider — one-shot async reads
For data that loads once and doesn't change reactively.
```dart
final disciplinesProvider = FutureProvider<List<Discipline>>((ref) {
  return ref.watch(disciplineRepositoryProvider).getDisciplines();
});
```

### NotifierProvider — sync state with complex logic
For synchronous state machines or complex state transitions without async.
```dart
@riverpod
class SessionFormNotifier extends _$SessionFormNotifier {
  @override
  SessionFormState build() => SessionFormState.empty();

  void setDiscipline(String disciplineId) =>
      state = state.copyWith(disciplineId: disciplineId);
}
```

## AsyncValue — always handle all states
When consuming async providers, handle loading/error/data explicitly:
```dart
ref.watch(authStateProvider).when(
  data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
  loading: () => const SplashScreen(),
  error: (e, _) => ErrorScreen(message: e.toString()),
);
```

## Where providers live
- Feature-scoped providers: `features/<name>/presentation/providers/<name>_provider.dart`
- Infrastructure providers (Firebase instances, repositories): `features/<name>/data/`
- App-wide providers: `core/providers/`

## Family providers — parameterized providers
Use `.family` when the provider depends on an external ID:
```dart
final userSkillsProvider = StreamProvider.family<List<UserSkill>, String>((ref, userId) {
  return ref.watch(skillRepositoryProvider).watchUserSkills(userId);
});

// Consumed as:
ref.watch(userSkillsProvider(currentUserId))
```

## Rules
- Never call `ref.read` inside `build()` — use `ref.watch` for reactive dependencies
- Use `ref.read` only in event handlers (button callbacks, etc.)
- Providers are lazy by default — they initialize when first watched
- Avoid provider `autodispose` unless the screen is truly ephemeral (e.g. a modal)
- Test providers with `ProviderContainer` in unit tests (see testing.md)
