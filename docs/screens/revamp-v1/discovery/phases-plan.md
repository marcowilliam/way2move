# Way2Move Revamp v1 — Missing Phases Plan

**Created:** 2026-04-24
**Source of truth for completed work:** `plan.md` (same folder)

---

## Pre-flight ground truth (read before planning anything)

These facts come from grepping the actual code on 2026-04-24 — they correct several assumptions a fresh reader would make from `plan.md` alone:

- **Home page:** 1 file, 1059 lines, **8 sections** (not 9 as the plan implies):
  `_GreetingHeader · _TodaySessionCard · RecoveryBanner · _WeekStrip · _MonthlyHeatMap · _GoalProgressSection · _QuickActionsGrid · _TrackTodayGrid`.
  The card-state branching for "today" already lives in 4 sub-widgets inside `_TodaySessionCard`: `_ActiveSessionBanner`, `_PlannedSessionCard`, `_CompletedTodayCard`, `_NoSessionCard`. **9 widget tests.**
- **Home providers:** `home_providers.dart` already exports everything the new design needs:
  `streakProvider · missedYesterdayProvider · weeklyCompletedDaysProvider · totalCompletedSessionsProvider · currentMonthSessionsProvider`. No new providers needed for C1.
- **Onboarding flow:** 1 file, 804 lines, **already a 6-step `PageView`** with `_buildWelcomeStep` → `_buildBasicInfoStep` → `_buildGoalStep` → `_buildActivityLevelStep` → `_buildSportsStep` → `_buildEquipmentStep`. All `TextEditingController`s, `TrainingGoal`/`ActivityLevel` enums, multi-select sets, and `_pageController` are already wired. **9 widget tests.** Welcome step (step 0) was already revamped in v1.0.
- **Journal test:** 10 failures. The test **already wires** `ProviderScope` overrides for `journalRepositoryProvider` and `currentUserIdProvider`. The "Firebase not initialized" error is therefore from a transitively-imported provider not yet overridden — most likely `voice_input_widget.dart` pulling a Firebase-backed dependency. Diagnosis pending; fix is test-only.
- **`phase01-tasks.md`:** still shows `[ ] Screens 6–20 — deferred to revamp v1.1` even though `plan.md` shows them all `[x]`. Needs syncing.

---

## What's already done (visual revamp)

- All 20 brand screens shipped (theme tokens → widgets, dark-mode-first)
- 721 widget tests passing + 20 theme-token tests
- 10 pre-existing journal failures (Phase D below)

---

## Phase breakdown

Each phase lists: **scope** · **inputs** · **outputs** · **definition of done** · **risk** · **rough effort**.

Effort is "fresh agent context-window units" — 1 unit ≈ a single focused Sonnet session before context bloat.

---

### Phase A — Housekeeping (single agent, 1 unit, ~10 min)

**Scope.** Sync the task tracker with shipped reality.

- Update `docs/phases/phase01-tasks.md`: replace `[ ] Screens 6–20 — deferred to revamp v1.1` with `[x] Screens 6–20 — shipped per docs/screens/revamp-v1/discovery/plan.md`. Add one bullet per screen group (Auth · Session · Exercise · Assessment · Body Awareness · Daily · Profile) with the file paths that landed.
- Spot-check `plan.md` checkboxes for screens 1–20: every `[x]` should match a file under `lib/features/...`. Flag any mismatch.

**DoD.** `git diff docs/phases/phase01-tasks.md` shows the sync; no code changes.
**Risk.** None.

---

### Phase B — Full Specs (parallel across 7 screen groups, 7 units total)

**Scope.** Way2Fly revamp produced `spec.md` + `test-cases.md` per screen group (see `way2fly/.../revamp-v1/calendar/`). Way2Move shipped widgets without specs. This phase fills the gap.

**Inputs per group:** the relevant section of `plan.md`, the actual Flutter file(s), the existing widget test file(s).

**Outputs per group:** new subfolder `docs/screens/revamp-v1/<group>/` with:
- `spec.md` — user flows · states · edge cases · animation triggers · a11y notes (semantic labels, contrast, tap-target audit)
- `test-cases.md` — unit · widget · integration · E2E scenarios mapped to `.claude/rules/testing.md`

**Group split (all 7 independent — dispatch in parallel):**

| Group | Screens | Folder |
|---|---|---|
| B1 — Auth | Splash · Sign In · Sign Up · Onboarding Welcome | `auth/` |
| B2 — Session | Home Dashboard · Active Session · Session Summary | `session/` |
| B3 — Exercise/Program | Exercise Library · Exercise Detail · Program Detail | `exercise/` |
| B4 — Assessment/AI | Assessment Flow · Results · AI Recommendation Review | `assessment/` |
| B5 — Body Awareness | Compensation Profile · Goals List · Goal Detail | `body-awareness/` |
| B6 — Daily Logging | Journal Entry · Nutrition · Sleep | `daily-logging/` |
| B7 — Profile | Profile | `profile/` |

**DoD per group.** `spec.md` references the actual widget file path and at least 3 edge cases each spec author had to look at the code to find. `test-cases.md` includes ≥1 currently-failing scenario each (so the spec discovers gaps, not just describes existing behavior).

**Risk.** Specs that just paraphrase `plan.md` add no value. Mitigation: each group must add the "edge cases I had to dig out of the code" section.
**Effort.** ~1 unit per group, 7 in parallel.

---

### Phase C — Deeper Restructures (2 parallel code tasks, ~2 units each)

These were explicitly deferred from v1.0 to v1.1 in `plan.md`. Both are contained Flutter changes with no backend impact.

#### C1 — Home Dashboard: 8-section → 6-section collapse

**Status:** ✅ shipped 2026-04-26 — see `handoff-2026-04-26.md`

**File.** `frontend/mobile/lib/features/dashboard/presentation/pages/home_page.dart` (1059 lines)
**Test.** `frontend/mobile/lib/features/dashboard/presentation/pages/home_page_test.dart` (9 tests)
**Providers (no new ones needed).** All state already lives in `home_providers.dart`.

**Target layout (6 sections, top→bottom):**
1. `_GreetingHeader` — keep as-is (already revamped)
2. `_TodayFocalCard` — **NEW**, replaces `_TodaySessionCard` + `RecoveryBanner` + the missed-yesterday banner. Single hero card, terracotta 4px left strip, 120px+ tall, terracotta `FilledButton` CTA. Folds the 4 existing sub-widgets (`_ActiveSessionBanner` · `_PlannedSessionCard` · `_CompletedTodayCard` · `_NoSessionCard`) into one component with a `TodayFocalState` enum.
3. `_WeekStrip` — refactor existing `_WeekStrip` to 7 × 32px circles (sage-fill completed · terracotta-ring today · sage-dot missed · neutral hollow future), driven by `weeklyCompletedDaysProvider`.
4. `_MonthlyHeatMap` — keep, ensure it uses theme tokens (no hardcoded colors).
5. `_GoalProgressSection` — cap visible goals at 2; add a "See all goals →" `TextButton` if more.
6. `_QuickLogPillRow` — **NEW**, replaces `_QuickActionsGrid` + `_TrackTodayGrid` (collapsing two 2×2 grids into one 4-pill horizontal scroller: Journal · Meal · Sleep · Photo).

**DoD.**
- `git diff` shows `_TodaySessionCard`, `RecoveryBanner` slot, `_QuickActionsGrid`, `_TrackTodayGrid` removed from the build tree (or repurposed); 6 sections in the build tree.
- 9 existing widget tests: ≥7 stay passing without modification; ≤2 may need test-side updates if they targeted `_QuickActionsGrid` etc. by type — the **production code goal** is preserved (semantic equivalent), the **test selectors** can be updated.
- One new widget test for `_TodayFocalCard` covering all 4 states (active · planned · completed · no-session+missed-banner · no-session+rest-day).
- `flutter analyze lib/features/dashboard/...` zero warnings.

**Risk.** Existing tests use `find.byType(_QuickActionsGrid)` — those will fail and look like regressions. Mitigation: read every test before deleting a widget; update assertions to match new components rather than restoring the old.

#### C2 — Onboarding Steps 1–5: visual revamp (NOT a rewrite)

**Status:** ✅ shipped 2026-04-26 — see `handoff-2026-04-26.md`

**File.** `frontend/mobile/lib/features/profile/presentation/pages/onboarding_flow.dart` (804 lines)
**Test.** `frontend/mobile/lib/features/profile/presentation/pages/onboarding_flow_test.dart` (9 tests)

**This is a visual refactor of the existing `_build*Step` methods.** The flow is already a 6-step `PageView` with all state, controllers, and validation in place. Welcome step (`_buildWelcomeStep`, lines ~289–319) is already revamped — leave it alone.

**Steps to re-skin** (preserving every TextEditingController, enum value, and onTap handler):

| Step | Method | New visual treatment |
|---|---|---|
| 1 — Basic info | `_buildBasicInfoStep` | Fraunces italic prompt *"A little about your body."* · underline-only `TextField`s · unit toggles as trailing chips · "Next" CTA only enables when all fields valid |
| 2 — Goal | `_buildGoalStep` | Fraunces italic prompt · 4 large option cards using the **existing `_OptionCard` pattern from `initial_assessment_flow.dart`** (4px terracotta left strip on selected, warm-surface) |
| 3 — Activity level | `_buildActivityLevelStep` | Same option-card pattern, 4 levels |
| 4 — Sports | `_buildSportsStep` | Multi-select chip grid using **the existing sage `_TagPill` from `exercise_card.dart`** (selected = sage tinted fill + terracotta text) · existing `_sportOptions` list reused |
| 5 — Equipment | `_buildEquipmentStep` | Same chip grid pattern · existing `_equipmentOptions` reused · "Let's go" terracotta CTA on this final step |

Plus: replace the existing `_progressController.animateTo` indicator with the **stretching-dot pattern from `_buildHeader` in `initial_assessment_flow.dart`** (current dot grows 8→24px wide). 6 dots total to match `_totalSteps`.

**DoD.**
- All 9 existing widget tests stay green without modification (the form data shape, controllers, and onTap handlers are unchanged).
- One new widget test per re-skinned step asserting: the Fraunces italic prompt text is present, the progress dots show the correct active index, and the primary CTA is a `FilledButton` (terracotta is the theme default).
- `flutter analyze lib/features/profile/presentation/pages/onboarding_flow.dart` zero warnings.

**Risk.** Easy to over-engineer this into a "split each step into its own file" refactor. **Don't.** This is a visual pass — keep the single-file structure. Folder-splitting can come later if test count for the file gets unwieldy.

**C1 and C2 are independent — dispatch in parallel.**

---

### Phase D — Journal Test Fix (parallel with Phase C, 1 unit)

**Status:** ✅ shipped 2026-04-26 — see `handoff-2026-04-26.md`

**File.** `frontend/mobile/lib/features/journal/presentation/pages/journal_entry_page_test.dart` (10 tests, all failing with `Firebase [DEFAULT] app has not been initialized`)

**Diagnosis hint** (already half-done by reading the test):
- The test already overrides `journalRepositoryProvider` and `currentUserIdProvider` via `ProviderScope`.
- Therefore the Firebase init error must come from a **transitively-imported widget** in `JournalEntryPage` that touches Firebase outside those two providers — most likely `voice_input_widget.dart` or a recovery/profile dependency it pulls in for the contextual prompts.
- **Step 1:** read `journal_entry_page.dart` and list every other provider/widget it imports.
- **Step 2:** for each, check whether it touches `FirebaseAuth.instance` / `FirebaseFirestore.instance` directly (vs going through a provider that could be overridden).
- **Step 3:** add the missing override(s) to `buildPage`.

**DoD.** All 10 tests in `journal_entry_page_test.dart` pass. **No production-code changes.** If a production file *forces* the test to need a fix (e.g., a widget calls `FirebaseAuth.instance` directly instead of `ref.watch(firebaseAuthProvider)`), call that out in the PR description as a follow-up — do not fix it in this pass.

**Risk.** Tempting to chase the production-code architecture problem mid-test-fix. Resist; flag separately.

---

### Phase E — Final QA Sweep (after C1 + C2 + D pass, 1 unit)

```bash
cd frontend/mobile

flutter analyze                     # must be ZERO warnings
flutter test                        # baseline 721 → expect ≥731 + new C1/C2 tests
```

Plus a manual smoke pass on the Android emulator covering:
1. Auth: sign up new user → land on onboarding welcome
2. Onboarding: walk all 6 steps end-to-end → land on home
3. Home: tap today focal card → start session → complete one exercise block → tap complete → land on session summary
4. Library: open exercise detail → back
5. Body awareness: tap a region on the body map → bottom sheet opens
6. Profile: tap each of the 4 grouped nav cards → page opens, back works

**DoD.** Zero analyze warnings · zero test failures · all 6 smoke flows complete without error · screenshot of home + onboarding step 3 attached to the PR.

---

### Phase F — Calendar Revamp v2 (independent, can run any time, ~3–4 units)

Calendar was explicitly out of scope in v1. Same process as v1:

1. `docs/screens/revamp-v2/calendar/discovery/plan.md`
2. `docs/screens/revamp-v2/calendar/design/mockups.html` + screenshots
3. Flutter implementation: `calendar_page.dart` using all existing v1 brand tokens
4. `spec.md` + `test-cases.md`

**Design direction (from `plan.md §Out of scope`):** heat-map day cells (intensity = session count), inline day detail (no bottom sheet), month stats bar at top, filter chips instead of toggle bar.

**Risk.** Touching calendar can affect the home `_MonthlyHeatMap` if they share a widget. Audit shared dependencies first.

---

### Phase G — Deploy (after Phase E, 1 unit)

1. Bump build number in `pubspec.yaml` (`+N`)
2. Codemagic TestFlight build via `.claude/skills/ios-staging-codemagic/SKILL.md`
3. Android staging build via existing GitHub Actions workflow
4. Internal tester verification

**Rollback strategy.** The revamp is shipped under default theme — there is no feature flag. If a tester reports a critical regression, revert the offending widget commit (each screen group should be a separate commit so revert is surgical). Keep `MaterialApp.themeMode` forced to `dark` until light-mode is verified across all 20 screens (per `plan.md §Flutter migration status`).

---

## Parallelism map

```
[A: housekeeping]  ── 1 agent, ~10 min, do first
       │
       ├─ [B1] [B2] [B3] [B4] [B5] [B6] [B7]   ◄ all 7 spec groups parallel
       │
       ├─ [C1: home restructure]   ──┐
       ├─ [C2: onboarding revamp]  ──┼── all parallel ──► [E: QA sweep] ──► [G: deploy]
       └─ [D: journal test fix]    ──┘

[F: calendar v2]  ────────── independent, any time
```

**Critical path:** A → C → E → G  
**Total wall-clock if fully parallelized:** ~3 units (A + max(C,D) + E + G)  
**Total agent-units consumed:** ~14 (A=1 + B=7 + C1=2 + C2=2 + D=1 + E=1 + G=1, F adds 3–4 if scheduled now)

---

## Priority for "what to dispatch first"

C1 + C2 + D shipped 2026-04-26; A docs sync follow-up shipped 2026-04-27. What's left:

1. **E** (final QA sweep — gating for G)
2. **G** (deploy)
3. **B1–B7** (specs add confidence, never block deploy — fill in opportunistically)
4. **F** (calendar v2 — its own deliverable, schedule when capacity allows)

---

## Sonnet handoff

Ready-to-paste prompt for C1 + C2 + D: see `sonnet-handoff-phases-C-D.md` in this folder.
