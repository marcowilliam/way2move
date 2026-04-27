# Handoff — Training Week Organizer (MVP shipped, finish-the-rest)

**Date prepared:** 2026-04-27 (evening)
**Owner of the request:** Marco (single-user app)
**Branch:** `feature/training-week-organizer-mvp`
**Worktree on disk:** `/projects/my-projects/personal/way2move/feature/training-week-organizer-mvp`
**Status:** MVP for tonight is **shipped**: data layer, basic rules + indexes, in-app seed, providers, Workout Library + Detail, Today protocol pin, Sensation card. **0 analyze issues, 781/781 tests passing.**

This handoff is paste-ready for a fresh agent. Marco can use the new training flow tonight (after the emulator caveat below). Phases 3A, 4, 5 (full), 6 remain.

---

## Critical things Marco must do BEFORE running tonight

1. **The Firestore emulator is currently running with stale rules** — rooted at `/projects/my-projects/way2move/main/firestore.rules`, which does NOT contain rules for `protocols`, `workouts`, `weekPlans`. That means any write the app tries against the new collections will be DENIED.

   **Fix (one of):**
   - Restart the emulator pointing at this worktree's rules:
     ```bash
     # Stop the running emulator (kill the java process on :8080)
     # Then in this worktree:
     cd /projects/my-projects/personal/way2move/feature/training-week-organizer-mvp
     firebase emulators:start --only firestore,auth,functions
     ```
   - Or copy the new rules + indexes back to main and let the existing emulator hot-reload them:
     ```bash
     cp /projects/my-projects/personal/way2move/feature/training-week-organizer-mvp/firestore.rules \
        /projects/my-projects/personal/way2move/main/firestore.rules
     cp /projects/my-projects/personal/way2move/feature/training-week-organizer-mvp/firestore.indexes.json \
        /projects/my-projects/personal/way2move/main/firestore.indexes.json
     # Firebase emulator hot-reloads rules; indexes are no-ops on emulator anyway.
     ```

2. **Run the app in chrome (debug → emulator):**
   ```bash
   cd /projects/my-projects/personal/way2move/feature/training-week-organizer-mvp/frontend/mobile
   flutter run -d chrome
   ```
   Sign in with whatever credentials Marco normally uses against the local Auth emulator.

3. **Seed From-the-Ground-Up:** navigate to `/workouts` (Workout Library), tap the **"Seed Ground Up"** floating action button. SnackBar confirms. After that, the workout appears in the list AND a "Daily routine" Sage card appears on Today above the focal card.

4. **Run the routine:** tap the Daily routine card → starts a session, lands in `/session/active`. Log sets, RPE, complete. On the summary page, fill the Sensation card → tap "Save sensation".

If anything fails at the rules layer (you'll see "permission-denied" in the console), it's almost certainly the emulator-rules-mismatch above. Rules-test deferred — see Phase 1E-full below.

---

## What this MVP shipped

### Data layer (Phase 1D — done)
- `lib/features/workouts/data/models/workout_model.dart` — `WorkoutModel` (reuses `ExerciseBlockModel` from session_model.dart so block schema stays unified between template and instance)
- `lib/features/workouts/data/datasources/firestore_workout_datasource.dart`
- `lib/features/workouts/data/repositories/workout_repository_impl.dart` — exposes `workoutRepositoryProvider` + `firestoreWorkoutDatasourceProvider`
- `lib/features/protocols/data/models/protocol_model.dart`
- `lib/features/protocols/data/datasources/firestore_protocol_datasource.dart`
- `lib/features/protocols/data/repositories/protocol_repository_impl.dart` — `protocolRepositoryProvider`
- `lib/features/week_plan/data/models/week_plan_model.dart` (+ `PlannedSlotModel`)
- `lib/features/week_plan/data/datasources/firestore_week_plan_datasource.dart` — uses deterministic doc id `${userId}_${isoYearWeek}`
- `lib/features/week_plan/data/repositories/week_plan_repository_impl.dart` — `weekPlanRepositoryProvider`
- **Extended** `lib/features/sessions/data/models/session_model.dart`:
  - `ExerciseBlockModel` now serializes `phase`, `level`, `category`, `directions`, `cuesOverride`, `currentlyIncluded`, `order`, `plannedSeconds`, `restSeconds`, `plannedWeight` (all optional).
  - New `SensationFeedbackModel`.
  - `SessionModel` now serializes `workoutId`, `kind`, `slot`, `durationCategory`, `place`, `sensationFeedback`.

**Tests (4 model round-trip tests, all passing):**
- `workout_model_test.dart` — round-trip preserves all fields including extended ExerciseBlock fields, parked block round-trip
- `protocol_model_test.dart` — round-trip preserves prescription, dates, workoutIds
- `week_plan_model_test.dart` — round-trip preserves intent, focusAreas, plannedSlots

### Rules + indexes (Phase 1E — basic, no rules tests yet)
- `firestore.rules` — added owner-only RW + isValidSource + isAssistantMetaImmutable for `workouts/`, `protocols/`, `weekPlans/`. Mirrors the existing `sessions/` and `journals/` blocks exactly.
- `firestore.indexes.json` — added composite indexes:
  - `sessions(userId ASC, workoutId ASC, date DESC)` — for "all sessions for this workout"
  - `workouts(userId ASC, kind ASC)` — for kind filter
  - `protocols(userId ASC, status ASC, endDate ASC)` — for active-protocol query

### Seed (Phase 1F — cut to ground-up only)
- `lib/features/protocols/domain/usecases/seed_ground_up_for_user.dart` — `SeedGroundUpForUser` use case. Idempotent: re-runs are no-ops once the workout + active protocol exist. Hand-written with all 11 exercises from Marco's 2026-04-26 chat (categories, directions, cues, planned seconds where applicable). Skips Notion CSV import entirely — that's deferred.
- Wired in via `seedGroundUpProvider` (in `active_protocols_provider.dart`).
- Triggered by the **"Seed Ground Up"** FAB on `WorkoutLibraryPage`. Tap it once; safe to tap again.

### Providers (Phase 2A — done)
- `lib/features/workouts/presentation/providers/workouts_provider.dart`:
  - `workoutsProvider` — `StreamProvider.family<List<Workout>, WorkoutKind?>`
  - `workoutByIdProvider` — `FutureProvider.family<Workout?, String>`
- `lib/features/protocols/presentation/providers/active_protocols_provider.dart`:
  - `activeProtocolsProvider` — `StreamProvider<List<Protocol>>`
  - `seedGroundUpProvider` — `Provider<SeedGroundUpForUser>`

### Pages (Phase 2B — done, with widget test)
- `lib/features/workouts/presentation/pages/workout_library_page.dart` — segmented kind filter (All / Ground Up / ABCDE / Snacks / Bodybuilding / Themed), vertical card list, empty state with seed-prompt, FAB to seed ground-up.
- `lib/features/workouts/presentation/pages/workout_library_page_test.dart` — 2 widget tests (empty state + populated list).
- `lib/features/workouts/presentation/pages/workout_detail_page.dart` — header + grouped-by-phase block list (warm-up / main / cool-down). Each block shows level chip, category as title, directions, cuesOverride bullets. Bottom bar: 56px Terracotta "Start session" → calls `StartSessionFromWorkout` and navigates to `/session/active`.
- Routes added in `lib/core/router/routes.dart`: `Routes.workouts`, `Routes.workoutDetail(id)`. Wired in `lib/core/router/app_router.dart` inside the `ShellRoute` (so the bottom nav stays visible). **No bottom-nav tab added yet** — Marco navigates via `/workouts` URL. Adding a tab is a tiny edit; flagged below.

### Today (Phase 2C — single-slot only, multi-slot deferred)
- `_DailyRoutineProtocolCard` widget appended to `lib/features/dashboard/presentation/pages/home_page.dart`.
- Renders ABOVE the focal card. One Sage-tinted card per active protocol's pinned workout.
- Shows Day X of Y + exercise count. Tap → starts a `flexible`-slot session and lands in `/session/active`.
- Hidden when no active protocols.
- **NOT shipped:** the multi-slot rendering of `_TodayFocalCard` (handoff Phase 2C-full). For tonight the existing `_TodayFocalCard` still shows the single most-recent session — that's fine for the daily-routine flow.

### Sensation capture (Phase 2D — done)
- `_SensationCard` appended to `lib/features/sessions/presentation/pages/session_summary_page.dart`.
- Sage-tinted (`AppColors.accent` background at 8% alpha, border at 25%). Never Terracotta — Sage is body-listening.
- Two chip-input fields (good areas, struggling areas), 1-5 slider, free-text notes, Save button.
- Persists via `UpdateSession(session.copyWith(sensationFeedback: ...))`.
- Reads existing `session.sensationFeedback` if present (initialState pre-fills).

### One small UX fix
- `session_view.dart` and `session_summary_page.dart` now fall back to `block.category ?? block.exerciseId` for the exercise title (instead of just the slug). That's why Ground-Up exercises render as "Foam Roller Bridge — Double Legged" instead of `gu-foam-roller-bridge` even though no canonical Exercise doc exists.

---

## Known shortcuts taken to ship tonight

| Shortcut | Why | What to fix in next pass |
|---|---|---|
| Seed runs in-app via FAB instead of a Cloud Function script | App-internal flow is faster to wire, no functions deploy needed | Phase 1F-full: write `backend/functions/scripts/import_notion_export.ts` per the original handoff. Read all CSVs, build all workouts (ABCDE, Snacks, Bodybuilding), seed sessions from Notion log. Idempotent via `idempotencyKey: "notion:<page-id>"`. |
| No canonical `Exercise` docs created for the 11 ground-up moves | Avoids the existing `exercises` rules-vs-model mismatch (rules check `createdBy` + `isBuiltIn`, model writes `createdByUserId` and never sets `isBuiltIn`) | Either fix the rules/model mismatch and write proper Exercise docs in the seed, or extend `ExerciseBlock` with a `displayName` field so blocks self-describe |
| Block titles fall back to `category` instead of querying Exercise | Same reason as above | Once Exercise docs exist, the existing `exercise?.name ?? block.category ?? block.exerciseId` chain just works |
| No rules unit tests | Time | Phase 1E-full: write `backend/functions/test/rules/training_week_rules_test.ts` per the original handoff §Phase 1E. Use `@firebase/rules-unit-testing` against the emulator. |
| No integration tests for the new datasources/repos | Time | Phase 1D-full: write `*_int_test.dart` files for each repo against the Firestore emulator. Pattern: `lib/features/sessions/data/repositories/session_repository_int_test.dart` if it exists, otherwise mirror `.claude/rules/testing.md` §Integration. |
| FAB on Workout Library is a debug-style affordance | Marco needs the seed to work tonight; an admin-only entrypoint is overkill | Once the Notion-CSV import lands and seeding is automatic on first sign-in (Cloud Function), remove the FAB. |
| `_TodayFocalCard` still shows single-session view | Multi-slot rendering is the bulk of Phase 2C-full | See Phase 2C-full below. |
| No bottom-nav tab for `/workouts` | Marco can type `/workouts` or context.push from anywhere | Add a tab — see `lib/core/router/app_router.dart` `_locationToTabIndex` (~line 587) and the bottom-nav row to know where. |
| Week Planner + Weekly Review (Phase 3A) not built | Out of scope for tonight | See Phase 3A below. |
| Web-recorder type sync (Phase 4) not done | Optional for the mobile-first MVP | See Phase 4 below. |
| Feature flag wiring + CNS updates + DATA_MODEL/FEATURES doc updates (Phase 5) skipped | Time | See Phase 5 below. |
| E2E (Phase 6) not built | Time | See Phase 6 below. |

---

## Mandatory reads before continuing (from the original handoff)

1. `CLAUDE.md` (worktree root) — non-negotiables: TDD, Clean Architecture + Riverpod + GoRouter, theme tokens always, zero analyze warnings, never push to main without explicit user OK, 48px tap targets, **Sage is never CTA color**.
2. `.claude/rules/flutter_frontend/architecture.md` — feature implementation order.
3. `.claude/rules/firebase_backend/firestore.md` — repository pattern.
4. `.claude/rules/firebase_backend/security_rules.md` — rules + emulator testing.
5. `.claude/rules/firebase_backend/assistant_ingest.md` — `source` + `idempotencyKey` contract. **Already updated rules to extend it to the 3 new collections; you should also add them to the "Where this applies" list in the doc.**
6. `.claude/rules/testing.md` — unit / integration / E2E file naming, one-scenario-per-test rule.
7. `docs/branding/brand-identity-plan.md` — Terracotta/Sage/Soft-Gold palette. Use tokens, never hex.
8. `docs/DATA_MODEL.md` — append the new collections + extended Session/ExerciseBlock fields here.
9. `~/.claude/rules/commit-hygiene.md` — **NEVER add `Co-Authored-By: Claude` trailers**. Standing rule.
10. The original handoff still in this folder (`handoff-2026-04-27.md`) — references the architectural decisions that ARE settled (don't relitigate).

---

## What's left — Phase-by-phase

### Phase 1D-full — Integration tests for the 3 new repos

For each of `WorkoutRepositoryImpl`, `ProtocolRepositoryImpl`, `WeekPlanRepositoryImpl`, write a `*_int_test.dart` against the Firestore emulator. Pattern: per `.claude/rules/testing.md` §Integration:

- `setUpAll` connects to emulator via `useFirestoreEmulator('localhost', 8080)`
- `tearDown` clears emulator state
- One scenario per test: create writes the doc / update mutates it / get returns null when absent / kind filter only returns matching docs / the auto-completed-protocol behavior (when the daily-flip Cloud Function exists)

Don't forget to also test the "extended SessionModel" round-trip with the new fields against Firestore.

### Phase 1E-full — Rules unit tests + assistant_ingest doc update

- `backend/functions/test/rules/training_week_rules_test.ts` (or whatever the project convention is — check existing rules tests). Use `@firebase/rules-unit-testing`:
  - User can read/write own `workouts/`, `protocols/`, `weekPlans/`; another user cannot.
  - User cannot mutate `source` after create.
  - User cannot create a doc without a valid `source` (empty / wrong-enum string).
  - Same for all 3 collections.
- `.claude/rules/firebase_backend/assistant_ingest.md` — append `protocols`, `workouts`, `weekPlans` to the "Where this applies" list. (Currently only updated in `firestore.rules`, not the doc.)

### Phase 1F-full — Notion-CSV import script

The original handoff §Phase 1F lays this out completely. Build `backend/functions/scripts/import_notion_export.ts` taking `--user-id` and `--export-dir` args. It should:

1. Parse `Workout database 2e31bcd4707a80d4bfdccd7e91758321_all.csv` → `workouts/`
2. Parse the master `Workout_Exercise database 2e41bcd4707a8027a0cbf0a00aaf18e3_all.csv` → embed blocks on workouts; create custom Exercise docs for any unseen exercise name
3. Parse `Workouts/Workout log database 2e31bcd4707a8085a4c2e4c6bc39925c_all.csv` → `sessions/` (status `completed`)
4. Read the per-workout MD files for long-form notes
5. Stamp every doc with `source: "assistant-ingest"` and `idempotencyKey: "notion:<page-id>"`
6. Idempotent on re-run

Run against emulator first, validate ~10 workouts + ~70 exercise blocks, then prod.

**Bonus consideration:** while you're in there, fix the existing `exercises` rules-vs-model mismatch (`createdBy` vs `createdByUserId`, missing `isBuiltIn` field on writes). Otherwise the Exercise docs the import creates will be denied by the rules.

### Phase 2C-full — Multi-slot Today rendering

Extend `_TodayFocalCard` (in `home_page.dart` ~line 165) so it groups today's sessions by `slot` (morning / midday / afternoon / evening / flexible) and renders all of them, not just the first one. Use `WatchSessionsByDate(userId, today)` (already wired via `todaySessionsProvider`).

The `_DailyRoutineProtocolCard` already pins the protocol routine above. The focal card just needs to multi-render the rest.

### Phase 3A — Week Planner + Weekly Review

Build per the original handoff §Phase 3A:
- `lib/features/week_plan/presentation/providers/current_week_plan_provider.dart` — `FutureProvider<WeekPlan>` calling a `GetOrCreateCurrentWeekPlan` use case (already exists in domain layer per the original handoff).
- `lib/features/week_plan/presentation/pages/week_plan_page.dart` — top: editable intent + focus-area chips. Below: 7-day × 4-slot grid. Drag/long-press to assign workouts. Auto-fill ABCDE on first read.
- `lib/features/week_plan/presentation/pages/week_review_page.dart` — totals, focus-area heatmap, save review.
- Routes: `/week`, `/week/review`. Add bottom-nav tab.

### Phase 4 — Web-recorder type sync

Already mapped in the original handoff. The Svelte sibling at `frontend/web-recorder/` needs:
- `src/lib/types.ts` extended with optional `phase`, `level`, `category`, `directions`, `cuesOverride`, `currentlyIncluded` on `ExerciseBlock`; `workoutId?`, `kind?`, `slot?`, `place?`, `sensationFeedback?` on `Session`.
- `Builder.svelte` and `ActiveSession.svelte` group blocks by phase and show level chip.
- `Settings.svelte` paste-and-import workouts JSON for now.
- Forward-compat read of older localStorage blobs (default missing fields to `undefined`, never crash).

### Phase 5 — Feature flag + docs + CNS

- Add to `docs/FEATURE_FLAGS_INVENTORY.md`:
  ```
  | feature_training_week_v2 | Training Week Organizer | High | Phase 5 |
  ```
- Wire it through Firebase Remote Config; gate the new screens (`/workouts`, `/week`, `/week/review`) behind it. Pattern: existing `feature_nutrition`/`feature_journal`.
- Append to `docs/DATA_MODEL.md`: `protocols`, `workouts`, `weekPlans`, extended `Session` / `ExerciseBlock`.
- Append to `docs/FEATURES.md`: "Training Week Organizer" entry.
- `marco-cns/projects/way2move/STATUS.md` — record feature shipped/in-flight.
- `marco-cns/projects/way2move/DECISIONS.md` — capture: "Introduced `protocols`, `workouts`, `weekPlans` as new vocabulary distinct from `programs`."
- `marco-cns/projects/way2move/LEARNINGS.md` — multi-slot pattern, sensation feedback shape, the `category`-as-display-name fallback we used to avoid the Exercise rules mismatch.
- `docs/screens/training-week-organizer/spec.md` — flows, states, edge cases.
- `docs/screens/training-week-organizer/test-cases.md` — scenarios.

### Phase 6 — E2E + final verification

`frontend/mobile/integration_test/training_week_organizer_e2e_test.dart` — at minimum:
1. Open Workout Library → tap Ground Up → Start session → log RPE + sensation → see in Today.
2. Plan a snack to morning slot → assert it shows on Today before noon (needs Phase 3A).
3. Save Weekly Review → assert next-week banner appears (needs Phase 3A).

Run order:
```bash
firebase emulators:start --only firestore,auth,functions &
cd backend/functions && npm test                                   # rules + functions
cd frontend/mobile && flutter test test lib                        # all unit + widget
cd frontend/mobile && flutter test integration_test/ -d <device>   # E2E
flutter analyze                                                    # zero issues
dart format .                                                      # zero diff
flutter run -d chrome                                              # web smoke
```

---

## Quick file map (where everything lives)

```
firestore.rules                                      # extended for 3 collections
firestore.indexes.json                               # extended for 3 collections

frontend/mobile/lib/features/
├── workouts/
│   ├── domain/                                      # already there from prior agent
│   │   ├── entities/{workout.dart, workout_enums.dart}
│   │   ├── repositories/workout_repository.dart
│   │   └── usecases/{get_workouts, get_workout_by_id, watch_workouts, start_session_from_workout}.dart (+ tests)
│   ├── data/                                        # NEW (this MVP)
│   │   ├── models/{workout_model.dart, workout_model_test.dart}
│   │   ├── datasources/firestore_workout_datasource.dart
│   │   └── repositories/workout_repository_impl.dart
│   └── presentation/                                # NEW (this MVP)
│       ├── providers/workouts_provider.dart
│       └── pages/{workout_library_page.dart (+ test), workout_detail_page.dart}
│
├── protocols/
│   ├── domain/                                      # entity + repo from prior agent;
│   │   └── usecases/seed_ground_up_for_user.dart    # NEW (this MVP)
│   ├── data/                                        # NEW (this MVP)
│   │   ├── models/{protocol_model.dart, protocol_model_test.dart}
│   │   ├── datasources/firestore_protocol_datasource.dart
│   │   └── repositories/protocol_repository_impl.dart
│   └── presentation/                                # NEW (this MVP)
│       └── providers/active_protocols_provider.dart
│
├── week_plan/
│   ├── domain/                                      # already from prior agent
│   └── data/                                        # NEW (this MVP)
│       ├── models/{week_plan_model.dart, week_plan_model_test.dart}
│       ├── datasources/firestore_week_plan_datasource.dart
│       └── repositories/week_plan_repository_impl.dart
│
├── sessions/
│   ├── data/models/session_model.dart               # EXTENDED (this MVP) — block + session new fields, SensationFeedbackModel
│   └── presentation/pages/
│       ├── session_view.dart                        # tweaked: block title fallback now uses block.category
│       └── session_summary_page.dart                # EXTENDED (this MVP) — appended _SensationCard widget
│
└── dashboard/presentation/pages/home_page.dart      # EXTENDED (this MVP) — _DailyRoutineProtocolCard injected above _TodayFocalCard
```

---

## Definition of done (full feature)

Marco can:
- Sign in
- See his "From the Ground Up" Daily routine card on Today
- Tap it → start the session → log all 11 exercises with sets/reps/RPE
- Fill the Sensation card → save
- See the session in his history with the sensation feedback persisted
- Tap "Plan next week" (Phase 3A), see the auto-filled ABCDE, edit intent + focus areas, save (Phase 3A)
- Open Weekly Review at week-end, see totals + sensation average + focus-area heatmap (Phase 3A)
- Use the web-recorder against the same data shape (Phase 4)
- Toggle the whole feature off via `feature_training_week_v2` Remote Config flag (Phase 5)
- All E2E green (Phase 6)

For tonight's MVP, only the first 5 bullets are reachable.

---

## Non-negotiables (re-read before you start)

1. **TDD first** — failing test, then impl. (We cut corners on integration tests for tonight; the model unit tests are TDD.)
2. **No `Co-Authored-By: Claude` trailers.** Standing rule across all of Marco's repos.
3. **Theme tokens only** — no hex, no raw `Duration(milliseconds:...)`, no raw font sizes. (One last sweep is worth doing on the new pages.)
4. **Zero analyze warnings** at every commit.
5. **Don't push without explicit user OK.** This MVP is committed locally; Marco hasn't asked for a push to origin.
6. **Don't refactor unrelated code.**
7. **Don't extend `programs` to fit this feature** — settled.
8. **Sage is not a CTA color.** Terracotta = action.
9. **`flutter test test lib` and `flutter analyze` after every meaningful file change.**
10. **Update `.claude/rules/firebase_backend/assistant_ingest.md`** when adding the new collections (still TODO — Phase 5).

---

Good luck. The architecture is settled, the domain + data layers are wired, and Marco has a working ground-up flow tonight. The remaining work is Notion-CSV import, week planner, and the polish phases.
