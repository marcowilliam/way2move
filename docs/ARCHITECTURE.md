# Way2Move -- Architecture

## System Overview

Way2Move is a movement-first training platform for recreational and longevity athletes.
The system follows the same technical patterns as Way2Fly: Flutter mobile app communicating
directly with Firebase services, no custom REST API until Phase 5+.

```
                        Phase 1-4                          Phase 5+
 ┌──────────────────────────────────────┐   ┌──────────────────────────────────────┐
 │            Flutter App               │   │          Flutter App + Web           │
 │  firebase_auth │ cloud_firestore     │   │  + REST API calls for social/coach   │
 │  firebase_storage │ remote_config    │   │                                      │
 └────────┬───────────┬────────────┬────┘   └────────┬──────────────┬──────────────┘
          │           │            │                  │              │
 ┌────────▼───────────▼────────────▼────┐   ┌────────▼──────────────▼──────────────┐
 │          Firebase Platform           │   │       Firebase + Node.js API         │
 │  Auth │ Firestore │ Functions │ Stor │   │  + PostgreSQL (Supabase) for social  │
 └──────────────────────────────────────┘   └──────────────────────────────────────┘
          ↑ triggered by                             ↑ triggered by
 ┌──────────────────────────────────────┐   ┌──────────────────────────────────────┐
 │   Cloud Functions (TypeScript)       │   │   Cloud Functions + Express API      │
 │  Auth triggers │ Firestore triggers  │   │  + AI API orchestration              │
 │  Callable: program gen, assessment   │   │  + Video processing (assessment)     │
 └──────────────────────────────────────┘   └──────────────────────────────────────┘

 Phase 2+ adds external AI API calls from Cloud Functions:
 ┌──────────────────────────────────────┐
 │         External AI Services         │
 │  Phase 2: Movement assessment AI     │
 │  Phase 3: Nutrition plan generation  │
 └──────────────────────────────────────┘
```

## Monorepo Layout

```
/projects/way2move/
├── .bare/                    # bare git repo (do not touch)
├── .git                      # gitdir pointer to .bare
└── main/                     # main worktree (this folder)
    ├── CLAUDE.md
    ├── .claude/rules/        # detailed architecture rules
    ├── docs/
    │   ├── ARCHITECTURE.md           # this file
    │   ├── DATA_MODEL.md
    │   ├── DEV_WORKFLOW.md
    │   ├── DEVELOPMENT_PLAN_HIGH_LEVEL.md
    │   ├── GENERAL_PROJECT_SPECIFICATION.md
    │   ├── features/                 # feature spec docs
    │   └── phases/                   # phase task files
    ├── frontend/
    │   └── mobile/           # Flutter app (iOS + Android)
    │       ├── lib/
    │       │   ├── core/
    │       │   │   ├── constants/
    │       │   │   ├── errors/
    │       │   │   ├── extensions/
    │       │   │   ├── router/
    │       │   │   ├── theme/
    │       │   │   └── utils/
    │       │   ├── features/
    │       │   │   ├── auth/
    │       │   │   ├── training/
    │       │   │   ├── assessment/
    │       │   │   ├── sleep/
    │       │   │   ├── profile/
    │       │   │   └── nutrition/      # Phase 3
    │       │   └── shared/
    │       │       ├── widgets/
    │       │       └── l10n/
    │       ├── test/
    │       ├── integration_test/
    │       ├── pubspec.yaml
    │       └── analysis_options.yaml
    └── backend/
        └── functions/        # Firebase Cloud Functions (TypeScript)
            ├── src/
            │   ├── auth/
            │   ├── training/
            │   ├── assessment/
            │   ├── sleep/
            │   ├── seed/
            │   └── index.ts
            ├── seeds/
            ├── scripts/
            ├── package.json
            └── tsconfig.json
```

## Monorepo Tooling

| Tool | Purpose |
|---|---|
| Nx | Monorepo task orchestration (test, build, lint across packages) |
| Melos | Flutter workspace management (multi-package Flutter projects) |
| pnpm | JavaScript/TypeScript package management (root workspaces) |
| npm | Cloud Functions only (Firebase Functions requires npm) |
| Lefthook | Git hooks: pre-commit (format + lint), pre-push (tests) |
| GitHub Actions | CI/CD: Android builds, Firebase deploy, test runners |
| Codemagic | iOS builds -> TestFlight |

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (stable channel), Dart |
| Web (Phase 5+) | React + Vite + TypeScript (not started) |
| Backend (Phase 1-4) | Firebase: Auth, Firestore, Functions, Storage |
| Backend (Phase 5+) | Node.js API + PostgreSQL (Supabase) for social features |
| AI (Phase 2) | External AI API for movement assessment (called from Cloud Functions) |
| AI (Phase 3) | External AI API for nutrition plan generation (called from Cloud Functions) |
| State management | Riverpod 2.x (flutter_riverpod + riverpod_annotation) |
| Routing | GoRouter |
| Error handling | fpdart Either<Failure, T> |
| Monorepo | Nx (root), Melos (Flutter), pnpm workspaces (JS) |
| Git hooks | Lefthook |
| CI/CD | GitHub Actions (Android + Firebase), Codemagic (iOS -> TestFlight) |
| Observability | Sentry (free tier) |
| Feature flags | Firebase Remote Config |

---

## Layer Architecture: Clean Architecture

Every feature follows Clean Architecture with three layers. The dependency rule is strict:
**Presentation -> Domain <- Data**. The domain layer has zero Flutter or Firebase imports.

```
┌─────────────────────────────────────────────────┐
│                 Presentation                     │
│   Pages, Widgets, Riverpod Providers             │
│   (Flutter + Riverpod, thin UI layer)            │
└──────────────────┬──────────────────────────────┘
                   │ depends on
┌──────────────────▼──────────────────────────────┐
│                   Domain                         │
│   Entities, Repository Interfaces, Use Cases     │
│   (Pure Dart, zero external dependencies)        │
└──────────────────▲──────────────────────────────┘
                   │ implements
┌──────────────────┴──────────────────────────────┐
│                    Data                          │
│   Models, Datasources, Repository Impls          │
│   (Firebase SDK, JSON serialization)             │
└─────────────────────────────────────────────────┘
```

### Feature folder structure

```
features/<feature_name>/
├── data/
│   ├── datasources/        # Firebase SDK calls (raw data only)
│   ├── models/             # fromFirestore/toFirestore, JSON mapping
│   └── repositories/       # implements domain interfaces, owns caching
├── domain/
│   ├── entities/           # pure Dart classes, no deps
│   ├── repositories/       # abstract interfaces only
│   └── usecases/           # one call() method per class
└── presentation/
    ├── pages/              # full screens
    ├── widgets/            # feature-scoped reusable widgets
    └── providers/          # Riverpod providers (ViewModel layer)
```

### Feature implementation order (mandatory)

Every feature is built in this exact sequence:

1. **Domain entities** -- immutable Dart classes (no Flutter/Firebase imports)
2. **Domain repository interfaces** -- abstract classes only
3. **Domain use cases** -- one `call()` method, depends only on abstract interfaces
4. **Unit tests for use cases** -- mock the repository, test all paths (red -> green)
5. **Data models** -- `fromFirestore`/`toFirestore`, no business logic
6. **Datasources** -- stateless Firebase SDK wrappers
7. **Repository implementations** -- consume datasources, handle caching, return `Either<Failure, T>`
8. **Integration tests for repositories** -- hit the Firebase emulator (red -> green)
9. **Riverpod providers** -- wire use cases to UI state
10. **Widgets** -- lean, state-driven, no logic in `build()`
11. **Widget tests** -- pump with `ProviderScope` overrides (red -> green)

---

## Testing Strategy

### Philosophy
Tests discover bugs, they do not prove code works. TDD is mandatory: red -> green -> refactor.

### Test types

| Type | Location | What it tests | Dependencies |
|---|---|---|---|
| Unit | `*_test.dart` (co-located) | Use cases, entities, models | Mocked (mocktail) |
| Widget | `*_test.dart` (co-located) | UI states, interactions | ProviderScope overrides |
| Integration | `*_int_test.dart` (co-located) | Repositories + real Firestore | Firebase emulator |
| E2E | `integration_test/` | Full user flows | Real device + emulator |

### Coverage targets

| Layer | Target |
|---|---|
| Domain (use cases, entities) | 100% |
| Data (models, repositories) | >80% |
| Presentation | Widget tests for all meaningful UI states |
| Cloud Functions | >80% on business logic |

### Running tests

```bash
# Flutter unit + widget tests
cd frontend/mobile && flutter test

# Flutter tests with coverage
cd frontend/mobile && flutter test --coverage

# Flutter integration tests (Firebase emulator must be running)
cd frontend/mobile && flutter test integration_test/ -d <device_id>

# Cloud Functions tests
cd backend/functions && npm test

# Lint + analyze
cd frontend/mobile && flutter analyze && dart format .
```

### Firebase emulator for tests

All integration and E2E tests run against the Firebase Local Emulator Suite.
Never hit real Firebase in tests.

```bash
# Start emulators
firebase emulators:start

# Or via Docker
docker compose up emulators
```

---

## Error Handling

All repository and use case returns use `Either<Failure, T>` from fpdart.
Exceptions are caught at the data layer boundary and converted to typed failures.

```dart
sealed class AppFailure {}
class AuthFailure extends AppFailure { final String code; AuthFailure(this.code); }
class NetworkFailure extends AppFailure {}
class NotFoundFailure extends AppFailure {}
class ValidationFailure extends AppFailure { final String message; ValidationFailure(this.message); }
class ServerFailure extends AppFailure { final String code; ServerFailure(this.code); }
```

---

## State Management: Riverpod 2.x

Riverpod is the sole state management solution. No setState (except ephemeral UI toggles),
no Provider package, no BLoC.

| Provider type | Use case |
|---|---|
| `Provider` | DI, constants, computed values |
| `StateProvider` | Simple toggles, selections |
| `AsyncNotifierProvider` | Async operations with loading/error/data lifecycle |
| `StreamProvider` | Firestore real-time streams |
| `FutureProvider` | One-shot async reads |
| `NotifierProvider` | Sync state with complex logic |

Always handle all `AsyncValue` states: loading, error, data.

---

## Key Differences from Way2Fly

| Aspect | Way2Fly | Way2Move |
|---|---|---|
| Domain | Bodyflight (skydiving + tunnel) | Movement training (recreational + longevity athletes) |
| Web app | Phase 3 (debrief screen) | Phase 5+ (social/coaching dashboard) |
| AI integration | None in current phases | Phase 2 (assessment AI), Phase 3 (nutrition AI) |
| Coach role | Phase 1 (per-session tagging) | Phase 5 (not in MVP) |
| XP/Gamification | Core to Phase 1 | Not in Phase 1 (focus on training progression) |
| Progression model | Skill tree (disciplines -> skills -> levels) | Exercise progression (regressions/progressions per exercise) |
| Real-time data | Session streams, skill updates | Session streams, sleep logs, assessment results |
| External APIs | None | AI APIs for assessment and nutrition (Cloud Functions proxy) |

### AI API Architecture (Phase 2+)

AI API calls are always proxied through Cloud Functions -- the Flutter app never calls
external AI services directly. This keeps API keys server-side and allows request
validation, rate limiting, and response caching.

```
Flutter App
    │
    ▼ (httpsCallable)
Cloud Function (callable)
    │
    ├── Validate auth + input
    ├── Call external AI API
    ├── Parse + validate response
    ├── Store results in Firestore
    └── Return result to client
```

---

## Navigation: GoRouter

GoRouter is the sole navigation solution. Declarative routing with auth guards.

```
core/router/
├── app_router.dart         # GoRouter instance (Provider)
├── routes.dart             # route path constants
└── guards/
    └── auth_guard.dart     # redirect for unauthenticated users
```

Navigation by ID, not by object. Pass the ID, load the entity on the destination screen.

---

## Environments

| Environment | Backend | Notes |
|---|---|---|
| Development | Firebase Local Emulator Suite | All services emulated locally |
| Staging | Firebase project (way2move-staging) | For QA and beta testing |
| Production | Firebase project (way2move-prod) | Live users |

Docker Compose is available for one-command emulator setup:

```bash
docker compose up emulators    # Auth:9099 Firestore:8080 Functions:5001 Storage:9199 UI:4000
```
