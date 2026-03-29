# Phase 1 Continuation Guide

**Branch:** `phase01`
**Worktree:** `/projects/way2move/phase01`
**Last session ended:** 2026-03-29
**Status:** Blocks 0–3 complete and committed. Block 4 started (2 files only).

---

## What Was Completed

### Block 0 — Project Setup ✅
- `pubspec.yaml` updated with all dependencies (Riverpod 2.6, GoRouter 14, fpdart, Firebase suite, Google/Apple sign-in, video_player, crypto)
- `lib/firebase_options.dart` — placeholder for emulator dev (replace with `flutterfire configure` for prod)
- `lib/main.dart` — Firebase init + emulator connection in debug mode + Riverpod ProviderScope
- `lib/core/errors/app_failure.dart` — sealed failure hierarchy (Auth, Server, Network, NotFound, Permission, Cache, Validation)
- `lib/core/constants/app_keys.dart` — all widget Keys for testing
- `lib/core/theme/app_colors.dart` + `app_theme.dart` — full light/dark theme (earth tones, Headspace×Strava aesthetic)
- `lib/core/router/routes.dart` + `app_router.dart` — GoRouter with auth redirect, fade/slide transitions, bottom nav shell
- `lib/core/providers/firebase_providers.dart` — FirebaseAuth, Firestore, Storage providers
- `lefthook.yml` — pre-commit (format+analyze+lint), pre-push (tests)
- Android package name updated to `com.way2move.app`

### Block 1 — Auth ✅
- **Domain:** `AppUser` entity, `AuthRepository` interface, `SignIn`/`SignUp`/`SignOut` use cases
- **Data:** `UserModel` (fromFirestore/toEntity), `FirebaseAuthDatasource` (email, Google, Apple), `AuthRepositoryImpl` with Either error handling
- **Presentation:** `AuthNotifier` (AsyncNotifierProvider), `LoginPage` (fade-in animation), `SignUpPage` (slide animation)
- **Router:** auth redirect, login/signup routes with animations, bottom nav with 5 tabs (Home, Calendar, Exercises, Progress, Profile)
- **Cloud Function:** `onUserCreate` trigger updated — creates `users/{uid}` with `roles: ['athlete'], totalXp: 0`
- **Tests:** 21 tests passing (use case unit tests + widget tests for LoginPage and SignUpPage)

### Block 2 — Exercise Library (Domain + Data) ✅
- **Domain:** `Exercise` entity with full taxonomy (ExerciseDifficulty, ExerciseType, MovementPattern, BodyRegion, SportTag, EquipmentTag), progressionIds/regressionIds
- **Domain:** `ExerciseRepository` interface, `GetExercises`/`SearchExercises`/`AddExercise` use cases
- **Data:** `ExerciseModel` (fromFirestore/fromMap/toEntity), `FirestoreExerciseDatasource`, `ExerciseRepositoryImpl` with in-memory cache (seed data cached permanently)
- **Seed data:** 60+ curated exercises in `exercise_seed_data.dart` — DNS, PRI, mobility, stability, strength, breathing, hypermobility patterns
- **Tests:** 6 use case tests passing

### Block 3 — Exercise Library (Presentation) ✅
- **ExerciseListPage:** search field, filter bottom sheet (type/region/equipment/difficulty), active filter chips, staggered list animation, add custom exercise dialog
- **ExerciseDetailPage:** SliverAppBar, Hero transition on name, coaching cues numbered list, equipment/region tags, progressions/regressions with navigation
- **ExerciseCard widget:** difficulty badge (color-coded), type/region tag chips
- **Providers:** `exerciseListProvider` (reactive search+filter), `exerciseDetailProvider` (family), `addExerciseProvider`
- **Router:** `/exercises/:exerciseId` nested route with slide transition
- **Tests:** 5 widget tests for ExerciseListPage passing

### Block 4 — Assessment System (STARTED — 2 files only) ⚠️
- `assessments/domain/entities/assessment.dart` — Assessment entity, CompensationPattern enum, MovementScore, WeeklyPulse
- `assessments/domain/repositories/assessment_repository.dart` — AssessmentRepository interface

**Everything else in Block 4 is yet to be built.**

---

## What Remains (Blocks 4–10)

### Block 4 — Assessment System (continue here)
Files to create:
1. `assessments/domain/usecases/create_assessment.dart`
2. `assessments/domain/usecases/get_latest_assessment.dart`
3. `assessments/domain/usecases/get_assessment_history.dart`
4. `assessments/domain/usecases/create_assessment_test.dart` (TDD — write first)
5. `assessments/data/models/assessment_model.dart`
6. `assessments/data/datasources/firestore_assessment_datasource.dart`
7. `assessments/data/repositories/assessment_repository_impl.dart` (with provider)
8. `assessments/presentation/providers/assessment_providers.dart`
9. `assessments/presentation/pages/initial_assessment_flow.dart` — multi-step: answer questions, view results
10. `assessments/presentation/pages/assessment_history_page.dart`
11. `assessments/presentation/widgets/weekly_pulse_dialog.dart` — 4 sliders: energy, soreness, motivation, sleep
12. Compensation detection logic (rule-based from questionnaire answers — see logic notes below)

**Compensation detection rules** (map questionnaire answers → CompensationPattern):
- Desk job + neck pain → `forwardHeadPosture`, `roundedShoulders`
- Sitting >6h/day → `anteriorPelvicTilt`, `poorCoreStability`
- Lower back pain + sedentary → `anteriorPelvicTilt`, `excessiveLumbarLordosis`
- Knee pain + runner → `kneeValgus`, `weakGluteMed`
- Ankle pain → `limitedDorsiflexion`, `overPronation`
- Shoulder pain overhead → `roundedShoulders`, `limitedThoracicRotation`

### Block 5 — Programs
Files needed:
- Domain: `Program`, `WeekTemplate`, `DayTemplate` entities
- Domain: `ProgramRepository` interface
- Domain: use cases (CreateProgram, GetActiveProgram, UpdateProgram, DeactivateProgram)
- Data: models, datasource, repository impl
- Presentation: `ProgramBuilderPage`, `WeekTemplateEditor`, `ProgramDetailPage`
- Logic: auto-generate starter program from assessment compensation results (map CompensationPattern → corrective exercise IDs from seed data)
- Key mapping (compensation → exercises):
  - `forwardHeadPosture` → `ex_chin_tuck`, `ex_dns_prone_forearm`
  - `roundedShoulders` → `ex_wall_slide`, `ex_ys_ts`, `ex_face_pull`
  - `anteriorPelvicTilt` → `ex_90_90_breathing`, `ex_deadbug`, `ex_couch_stretch`
  - `poorCoreStability` → `ex_deadbug`, `ex_bird_dog`, `ex_plank`, `ex_rkg_plank`
  - `weakGluteMed` → `ex_clamshell`, `ex_single_leg_glute_bridge`
  - `limitedHipInternalRotation` → `ex_hip_90_90`, `ex_hip_90_90_lift`, `ex_hip_car`
  - `limitedDorsiflexion` → `ex_ankle_car`, `ex_calf_stretch`
  - `thoracicKyphosis` → `ex_thoracic_rotation`, `ex_thoracic_extension_bench`, `ex_cat_cow`

### Block 6 — Sessions
Files needed:
- Domain: `Session`, `ExerciseBlock` entities
- Domain: `SessionRepository` interface
- Domain: use cases (CreateSession, CompleteSession, GetSessionsByDate, GetSessionHistory)
- Data: models, datasource, repository impl
- Presentation: `SessionView` (today's workout — exercise list with sets/reps, mark complete, RPE input), `SessionSummaryPage`, `CreateStandaloneSessionPage`
- Logic: generate session from active program's weekly template for today's date
- Tests: unit tests for session generation logic + widget tests

### Block 7 — Sleep Logging
Files needed:
- Domain: `SleepLog` entity
- Domain: `SleepRepository` interface + use cases (LogSleep, GetSleepLogs, GetAverageSleepQuality)
- Data: model, datasource, repository impl
- Presentation: `SleepLogEntryWidget` (bed time, wake time, quality 1-5, notes), `SleepHistoryChart` (7-day and 30-day)

### Block 8 — Auto-Progression
Files needed:
- Domain: `ProgressionRule` entity, `ProgressionService`
- Logic: check 3x completions + sleep average + pulse composite score
- Progression actions: increase reps, increase load, advance via progressionIds
- Deload triggers: poor sleep trend, low pulse, pain reported
- Presentation: `ProgressionSettingsPage`, `ProgressionSuggestionCard` (post-session)

### Block 9 — Calendar
Files needed:
- Presentation: CalendarPage with month/week toggle, color-coded sessions
- Logic: tap day → view/create session, Google/Apple Calendar sync

### Block 10 — Dashboard & Navigation
Files needed:
- Replace placeholder Home with real `DashboardPage`: today's session card, program progress bar, streak counter, weekly overview
- Replace placeholder Profile with `ProfilePage`: edit name/avatar, training preferences, sign out
- Replace placeholder Progress with `ProgressPage`: consistency charts, assessment score history
- Update bottom nav with real pages wired in

---

## Architecture Patterns (follow exactly)

All code follows Clean Architecture — see `.claude/rules/flutter_frontend/architecture.md`.

**Feature implementation order (mandatory):**
1. Domain entities → 2. Repository interfaces → 3. Use cases → **4. Tests (TDD — write test FIRST)** → 5. Data models → 6. Datasources → 7. Repository impl → 8. Integration tests → 9. Riverpod providers → 10. Widgets → 11. Widget tests

**Every use case test must go before the implementation.** The project CLAUDE.md is strict about TDD.

**Zero lint warnings before committing.** Run `flutter analyze` from `frontend/mobile/` before every commit. Common issues: `prefer_const_constructors`, `unused_import`.

**Commit after each block.** Format: `feat(block-N): short description`

---

## Running the App

```bash
# Start Firebase emulators first (in a separate terminal)
cd /projects/way2move/phase01 && firebase emulators:start

# Run Flutter app on Chrome (fast iteration)
cd /projects/way2move/phase01/frontend/mobile && flutter run -d chrome

# Run all tests
cd /projects/way2move/phase01/frontend/mobile && flutter test lib/ test/
```

## Running Tests

```bash
cd /projects/way2move/phase01/frontend/mobile

# All tests
flutter test lib/ test/

# Single block
flutter test lib/features/exercises/

# With coverage
flutter test --coverage lib/
```

---

## Key Files Map

| File | Purpose |
|---|---|
| `lib/main.dart` | App entry, Firebase init, emulator connect |
| `lib/firebase_options.dart` | Placeholder options — replace with `flutterfire configure` for prod |
| `lib/core/errors/app_failure.dart` | Sealed failure hierarchy |
| `lib/core/constants/app_keys.dart` | Widget Keys for testing |
| `lib/core/theme/app_colors.dart` | Color palette |
| `lib/core/theme/app_theme.dart` | Light + dark ThemeData |
| `lib/core/router/app_router.dart` | GoRouter instance — add routes here |
| `lib/core/router/routes.dart` | Route path constants |
| `lib/core/providers/firebase_providers.dart` | Firebase singleton providers |
| `lib/features/auth/...` | Full auth feature |
| `lib/features/exercises/...` | Full exercise library feature |
| `lib/features/assessments/domain/...` | Assessment domain (partial) |

---

## Current Test Count: 32 tests passing

- Auth use cases: 7
- Auth widget tests: 14
- Exercise use cases: 6
- Exercise widget tests: 5
- Placeholder: 1

---

## Important Notes for Next AI

1. **The `exerciseDetailPage` Key** is defined in `core/constants/app_keys.dart`. Do not redefine it locally in any page file.

2. **Route helper** — `Routes.exerciseDetail(id)` is a static method (not a constant) that returns `'/exercises/$id'`. Follow the same pattern for new parameterized routes.

3. **Seed exercises** are in `lib/features/exercises/data/datasources/exercise_seed_data.dart` — 60+ exercises. When building Program auto-generation, reference exercise IDs from this file.

4. **Firebase options** are placeholder values pointing to `way2move-dev` project. The emulator works without real credentials in debug mode.

5. **Tests co-located with source** in `lib/` (not `test/`). Run with `flutter test lib/`. The `analysis_options.yaml` suppresses `depend_on_referenced_packages` for this reason.

6. **`AppUser`** is the domain entity name (not `User` to avoid conflict with `firebase_auth.User`).

7. **Bottom nav** tabs are: Home(0), Calendar(1), Exercises(2), Progress(3), Profile(4) — wired in `_AppScaffold` inside `app_router.dart`. Blocks 5–10 will replace placeholder pages for each tab.
