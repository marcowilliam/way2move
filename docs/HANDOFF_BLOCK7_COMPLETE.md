# Handoff Summary — Block 7 Complete (2026-03-29)

## Current State

- **Branch:** `phase01` (git worktree at `/projects/way2move/phase01`)
- **Main branch:** pushed and up to date on `origin/main`
- **Test count:** 131 passing (0 failures, 0 lint warnings)
- **Last commit:** `docs: mark Block 7 complete, add UI testing guide (131 tests passing)`

## What Was Done This Session

### 1. Merged main into phase01
Main had uncommitted doc changes from a brainstorm expansion (journaling, voice-first, gait cycle, nutrition, compensation profile, goals). These expanded Phase 1 from 10 blocks to 17 blocks. The merge conflict in `phase01-tasks.md` was resolved:
- Blocks 0-6 (already built) kept as-is with `✅` status
- New brainstorm features added as Blocks 7-17

### 2. Built Block 7 — User Profile & Onboarding (32 new tests)

**Domain layer:**
- `UserProfile` entity with fields: id, name, email, avatarUrl, age, height, weight, activityLevel, trainingGoal, sportsTags, trainingDaysPerWeek, availableEquipment, injuries, onboardingComplete, createdAt
- `Injury` entity + enums: `InjurySeverity`, `ActivityLevel`, `TrainingGoal`
- `ProfileRepository` interface (getProfile, updateProfile, watchProfile)
- `GetProfile` and `UpdateProfile` use cases

**Data layer:**
- `UserProfileModel` + `InjuryModel` with fromFirestore/toFirestore/toEntity (handles both camelCase and snake_case from Firestore)
- `FirestoreProfileDatasource` (reads/writes to `users` collection)
- `ProfileRepositoryImpl` with providers

**Presentation layer:**
- `ProfileNotifier` (AsyncNotifier with updateProfile, completeOnboarding)
- `profileStreamProvider` (real-time stream of current user's profile)
- `hasCompletedOnboardingProvider` (bool convenience provider)
- `OnboardingFlow` — 6-step animated PageView: Welcome → Basic Info → Goal → Activity Level → Sports → Equipment
- `ProfileEditPage` — full form to edit all profile fields with Save action

**Routes added:**
- `/onboarding` → OnboardingFlow (slide transition, outside shell)
- `/profile/edit` → ProfileEditPage (slide transition, outside shell)

**Tests (32 total):**
- 7 use case unit tests (GetProfile: 3, UpdateProfile: 4)
- 9 model tests (UserProfileModel: 6, InjuryModel: 3)
- 8 OnboardingFlow widget tests (welcome screen, step navigation, back button, goal selection, sports chips, skip functionality, last step)
- 7 ProfileEditPage widget tests (loading/data, pre-fill, save, sections)
- 1 removed placeholder test (net: 131 - 99 = 32 new)

**Keys added to AppKeys:**
`profileEditPage`, `onboardingFlow`, `onboardingNextButton`, `onboardingBackButton`, `onboardingSkipButton`, `onboardingDoneButton`, `onboardingNameField`, `onboardingAgeField`, `onboardingHeightField`, `onboardingWeightField`

## What Is NOT Done Yet (Potential Gaps)

1. **Onboarding redirect** — The router does NOT yet auto-redirect new users to `/onboarding`. The `hasCompletedOnboardingProvider` exists but is not wired into the router's `redirect` function. This should be added when the flow is ready for real use (check `onboardingComplete` field on the user doc and redirect to `/onboarding` if false).

2. **Injury management UI** — The `Injury` entity exists in the domain/data layers, but the OnboardingFlow does NOT yet have an injury input step. The ProfileEditPage also doesn't have injury editing. This was deferred to keep scope manageable.

3. **Profile page (bottom nav)** — The `/profile` route in the shell still shows a `_PlaceholderPage`. It should be replaced with a real ProfilePage that shows the user's profile data and has an "Edit Profile" button linking to `/profile/edit`.

4. **`onboardingComplete` field** — This field is written by the Flutter client on the `users` doc. The Cloud Function `onUserCreate` does NOT set this field (it doesn't exist in the function code yet). The model defaults it to `false` when missing, so this works correctly.

## Next Block: Block 8 — Compensation Profile

Per `docs/phases/phase01-tasks.md`, the next block is:

- Domain: Compensation entity (id, userId, name, type, region, severity, status, source, relatedGoalIds, relatedExerciseIds, history, detectedAt, resolvedAt)
- Domain: CompensationRepository interface
- Domain: CreateCompensation, UpdateCompensation, GetActiveCompensations, MarkCompensationImproving, MarkCompensationResolved use cases
- Data: CompensationModel, datasource, repo impl
- Presentation: CompensationProfilePage (body map), CompensationDetailPage, CompensationBodyMap widget
- Logic: parse journal entries for compensation mentions (keyword-based)
- Tests: unit + widget

**Architecture order (mandatory):** Domain entities → Repository interfaces → Use cases → Tests (TDD) → Data models → Datasources → Repo impl → Providers → Widgets → Widget tests

## File Locations

| What | Path |
|---|---|
| Phase tasks | `docs/phases/phase01-tasks.md` |
| Profile feature | `frontend/mobile/lib/features/profile/` |
| App keys | `frontend/mobile/lib/core/constants/app_keys.dart` |
| Routes | `frontend/mobile/lib/core/router/routes.dart` |
| Router | `frontend/mobile/lib/core/router/app_router.dart` |
| Data model spec | `docs/DATA_MODEL.md` |

## How to Run

```bash
cd /projects/way2move/phase01/frontend/mobile

# Run all tests
flutter test lib/

# Analyze (must show "No issues found!")
flutter analyze

# Format
dart format .
```
