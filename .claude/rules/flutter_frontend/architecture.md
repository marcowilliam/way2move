# Flutter Frontend — Architecture

## Pattern: Clean Architecture + Feature-based structure

Flutter code follows Clean Architecture with three layers per feature.
The dependency rule is strict: **Presentation → Domain ← Data**. Domain has zero Flutter/Firebase imports.

```
frontend/mobile/lib/
├── core/
│   ├── constants/          # app-wide constants (routes, keys, config)
│   ├── errors/             # Failure classes (AppFailure, NetworkFailure, etc.)
│   ├── extensions/         # Dart extension methods
│   ├── router/             # GoRouter definition (see navigation.md)
│   ├── theme/              # ThemeData, colors, typography
│   └── utils/              # pure helper functions
├── features/
│   └── <feature_name>/     # e.g. auth, exercises, programs, sessions, assessments, sleep, profile
│       ├── data/
│       │   ├── datasources/        # FirebaseAuthDatasource, FirestoreDatasource
│       │   ├── models/             # UserModel, SessionModel — JSON ↔ entity conversion
│       │   └── repositories/       # AuthRepositoryImpl, SessionRepositoryImpl
│       ├── domain/
│       │   ├── entities/           # User, Session, Skill — pure Dart classes, no deps
│       │   ├── repositories/       # abstract AuthRepository, abstract SessionRepository
│       │   └── usecases/           # SignIn, SignUp, LogSession — one class per use case
│       └── presentation/
│           ├── pages/              # full screens: LoginPage, ProfilePage
│           ├── widgets/            # reusable widgets scoped to this feature
│           └── providers/          # Riverpod providers for this feature
└── shared/
    ├── widgets/                    # truly app-wide widgets (buttons, loaders, etc.)
    └── l10n/                       # localisation (when needed)
```

## Layer responsibilities

### Domain layer (pure Dart, zero external deps)
- **Entities**: plain Dart classes representing business concepts. No `fromJson`/`toJson` here.
- **Repositories**: abstract interfaces only. `abstract class AuthRepository { Future<User> signIn(...); }`
- **Use cases**: one public method `call()`. Contain all business logic. Depend only on abstract repositories.

```dart
// domain/usecases/sign_in.dart
class SignIn {
  final AuthRepository _repo;
  SignIn(this._repo);

  Future<Either<AppFailure, User>> call(String email, String password) =>
      _repo.signIn(email, password);
}
```

### Data layer (implements domain interfaces)
- **Models**: extend or wrap entities, add `fromJson`/`toJson`/`fromFirestore`.
- **Datasources**: raw Firebase calls only. No business logic. Each datasource maps Firestore documents to models.
- **Repository implementations**: orchestrate datasources, handle exceptions, map to `Either<Failure, T>`.

```dart
// data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;
  AuthRepositoryImpl(this._datasource);

  @override
  Future<Either<AppFailure, User>> signIn(String email, String password) async {
    try {
      final model = await _datasource.signIn(email, password);
      return Right(model.toEntity());
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    }
  }
}
```

### Presentation layer (Flutter widgets + Riverpod)
- Pages are thin — they only read state from providers and dispatch events.
- Widgets handle UI only; no business logic inside `build()`.
- Providers wire use cases to UI state (see state_management.md).

## Naming conventions
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private fields: `_camelCase`
- Test files: `<source_file>_test.dart`, co-located with source
- Use case classes: verb + noun — `SignIn`, `CreateSession`, `CompleteExercise`
- Repository interfaces: `AuthRepository` (no "I" prefix)
- Repository implementations: `AuthRepositoryImpl`
- Datasources: `FirebaseAuthDatasource`, `FirestoreSessionDatasource`

## Error handling
Use `Either<Failure, T>` from `fpdart` or `dartz` for all repository/use case returns.
Never throw exceptions across layer boundaries — catch at the data layer, return `Left(failure)`.

Define a sealed failure hierarchy in `core/errors/`:
```dart
sealed class AppFailure {}
class AuthFailure extends AppFailure { final String code; AuthFailure(this.code); }
class NetworkFailure extends AppFailure {}
class NotFoundFailure extends AppFailure {}
```

## Feature implementation order (mandatory)

Every feature is built in this exact sequence. Never skip layers or build out of order:

1. **Domain models** — immutable Dart entities (no Flutter/Firebase imports)
2. **Domain repository interfaces** — abstract classes only
3. **Domain use cases** — one `call()` method, depends only on abstract interfaces
4. **Unit tests for use cases** — mock the repository interface, test all paths (red → green)
5. **Data models** — `fromFirestore`/`toFirestore`, no business logic
6. **Datasources** — stateless Firebase SDK wrappers, raw data only
7. **Repository implementations** — consume datasources, handle caching, return `Either<Failure, T>`
8. **Integration tests for repositories** — hit the Firebase emulator (red → green)
9. **Riverpod providers** — wire use cases to UI state (`AsyncNotifierProvider` = ViewModel)
10. **Widgets** — lean, state-driven, no logic in `build()`
11. **Widget tests** — pump with `ProviderScope` overrides (red → green)

Layer communication rule: **Presentation → Domain ← Data**. Presentation never imports from `data/`. Data never imports from `presentation/`. Domain has zero Flutter/Firebase imports.

## Caching responsibility

Repositories are the single source of truth. They own caching — not datasources, not providers.

```dart
class ExerciseRepositoryImpl implements ExerciseRepository {
  final FirestoreExerciseDatasource _datasource;
  List<Exercise>? _exercisesCache; // repository-level cache

  @override
  Future<Either<AppFailure, List<Exercise>>> getExercises() async {
    if (_exercisesCache != null) return Right(_exercisesCache!);
    try {
      final models = await _datasource.fetchExercises();
      _exercisesCache = models.map((m) => m.toEntity()).toList();
      return Right(_exercisesCache!);
    } on FirebaseException catch (e) {
      return Left(ServerFailure(e.code));
    }
  }
}
```

Seed data (built-in exercises) must be cached permanently after first load — no network call on subsequent reads.

## Dependency injection
Use Riverpod providers for DI — no service locator (get_it) needed.
Define providers close to their layer:
- Datasource providers in `data/datasources/`
- Repository providers in `data/repositories/`
- Use case providers in `domain/usecases/`
- State providers in `presentation/providers/`
- App-wide Firebase instance providers in `core/providers/`

```dart
// data/repositories/auth_repository_provider.dart
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));
});
```
