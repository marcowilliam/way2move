# Sonnet Handoff — Revamp v1 Phases C + D

**Date prepared:** 2026-04-24
**Paste this as-is to a fresh Sonnet agent. Do not include the header above.**

---

## Context (you're a fresh agent — read this carefully)

You are continuing the Way2Move brand revamp (`revamp-v1`). The visual pass over all 20 screens is complete and shipped. Three explicitly-deferred items remain:

- **C1** — Home dashboard restructure (collapse 8 sections to 6, single hero focal card, week-strip circles, quick-log pill row)
- **C2** — Onboarding steps 1–5 visual revamp (the 6-step `PageView` already exists; you re-skin the 5 question steps)
- **D** — Fix 10 pre-existing failures in `journal_entry_page_test.dart` (Firebase init issue from a transitively-imported widget)

**These three tasks are independent.** If a parent agent dispatches multiple Sonnets in parallel, each one takes one task. If you're working solo, do them in this order: **D first** (smallest, unblocks the test baseline), then **C1**, then **C2**.

---

## Repository

- Working tree: `/projects/my-projects/personal/way2move/main`
- Branch: `main`
- Flutter app root: `frontend/mobile/`

---

## Mandatory reads (in this order, before touching any code)

1. **`docs/screens/revamp-v1/discovery/plan.md`** — shipped-vs-pending list and per-screen design direction (especially `§Screen 5` for C1, the deferred-onboarding note for C2)
2. **`docs/screens/revamp-v1/discovery/phases-plan.md`** — the broader plan this handoff slots into (parallelism map, success criteria, risk register)
3. **`docs/screens/revamp-v1/discovery/handoff-2026-04-21.md`** — `§Quality bar to keep up` and `§Per-screen patterns this pass established`. **The patterns listed there are how every screen in this revamp looks.** Copy them.
4. **`docs/branding/brand-identity-plan.md`** — full token system; the principle is "breath, not bounce"
5. **`lib/core/theme/app_colors.dart` · `app_typography.dart` · `app_spacing.dart` · `app_motion.dart`** — never hardcode colors, sizes, or durations

---

## Project rules you must follow (non-negotiable)

These are enforced by `.claude/rules/` (auto-imported by `CLAUDE.md`):

- **Clean Architecture.** Presentation watches Riverpod providers; never call Firebase SDKs from a widget directly.
- **Riverpod, never `setState` for non-local state.** All shared/derived state goes through providers.
- **TDD.** Write/extend the failing test before the implementation. Patterns in `.claude/rules/testing.md`.
- **Theme tokens always.** No hex colors, no `Duration(milliseconds: 300)`, no raw font sizes — use `AppColors.*`, `WayMotion.*`, `AppSpacing.*`, `theme.textTheme.*`.
- **Underline-only inputs.** The theme already configures this — do not pass `OutlineInputBorder` or `filled: true`.
- **48px min tap target · 56px primary CTAs.**
- **Sage is never a primary CTA color.** Terracotta for actions; sage for "good/confirmed/improving" states only. The one exception is the achieve button on Goal Detail.
- **Run `flutter analyze <file>` after each file you touch.** Fix `prefer_const_constructors` and `deprecated_member_use` at write time.

---

## D — Journal test fix (do this first, smallest task)

### Files

- **Test:** `frontend/mobile/lib/features/journal/presentation/pages/journal_entry_page_test.dart` (10 tests, all failing)
- **Production (read only — do not edit):** `frontend/mobile/lib/features/journal/presentation/pages/journal_entry_page.dart`

### Diagnosis (already half-done by reading the test)

The test **already** wires `ProviderScope` overrides for `journalRepositoryProvider` and `currentUserIdProvider`. Failure must come from a different provider — most likely something `JournalEntryPage` transitively pulls in (the voice input widget, a contextual prompt provider, or a recovery dependency) that calls `FirebaseAuth.instance` or `FirebaseFirestore.instance` directly instead of going through an overrideable provider.

### Steps

1. Open `journal_entry_page.dart` and list every `import` from `way2move/features/...` and every `ref.watch(...)` it makes.
2. For each provider/widget it uses, follow the chain — does any of them touch a Firebase singleton directly (vs going through a provider you can override)?
3. Add the missing override to `buildPage(...)` in the test. Look at how `home_page_test.dart` overrides `MockSessionRepository` / `MockGoalRepository` / `MockProfileRepository` for an example of the multi-mock pattern.
4. If a production widget calls `FirebaseAuth.instance` directly (architecture violation), **do not fix it in this pass** — flag it in your handoff/PR description as a follow-up. Test-only changes for D.

### Definition of done

- `flutter test lib/features/journal/presentation/pages/journal_entry_page_test.dart` → all 10 pass.
- `git diff frontend/mobile/lib/features/journal/presentation/pages/journal_entry_page.dart` → empty (production file untouched).

---

## C1 — Home Dashboard restructure

### Current structure (do NOT need to find — pinned here)

- **Page:** `frontend/mobile/lib/features/dashboard/presentation/pages/home_page.dart` (1059 lines)
- **Test:** same folder, `home_page_test.dart` (9 tests, must end this work green)
- **Providers (already complete — DO NOT add new ones):** `frontend/mobile/lib/features/dashboard/presentation/providers/home_providers.dart`
  - `streakProvider` → int (days)
  - `missedYesterdayProvider` → bool
  - `weeklyCompletedDaysProvider` → `Set<int>` (1=Mon … 7=Sun)
  - `totalCompletedSessionsProvider` → int
  - `currentMonthSessionsProvider` → `List<Session>`
  - Plus `todaySessionsProvider` from `sessions/presentation/providers/session_providers.dart`

### What's there now (8 sections, lines roughly)

```
HomePage
├─ _GreetingHeader        (lines 59–105) ← already revamped, keep as-is
├─ _StreakBadge           (lines 107–137)
├─ _TodaySessionCard      (lines 142–176) → branches into 4 sub-widgets:
│    ├─ _SessionCardSkeleton    (loading)
│    ├─ _ActiveSessionBanner    (status == inProgress)
│    ├─ _PlannedSessionCard     (status == planned)
│    ├─ _CompletedTodayCard     (status == completed)
│    └─ _NoSessionCard          (no session today, optionally with missed-yesterday banner)
├─ RecoveryBanner          (separate widget, imported)
├─ _WeekStrip              (after line ~445, exact at flutter analyze)
├─ _MonthlyHeatMap
├─ _GoalProgressSection
├─ _QuickActionsGrid       ← collapse with TrackTodayGrid into pill row
└─ _TrackTodayGrid         ← collapse with QuickActionsGrid into pill row
```

### Target (6 sections — per `plan.md §Screen 5`)

1. `_GreetingHeader` — keep verbatim
2. **`_TodayFocalCard` (NEW)** — replaces `_TodaySessionCard` + `RecoveryBanner` + the missed-yesterday banner. Hero card. Terracotta 4px left strip (use the `Stack` + `Positioned.fill(width: 4)` technique from `_ExerciseBlockCard` in `session_view.dart`). Min 120px tall. Single terracotta `FilledButton` CTA at 56px. Folds the 4 today-state sub-widgets into one `TodayFocalState` enum-driven component (drive the enum from a small private provider in this file or pass `todaySessionsProvider.when(...)` results).
3. `_WeekStrip` (refactor existing) — 7 × 32px circles, M–S, evenly spaced. Sage fill + white check on completed, terracotta 2px ring on today (hollow), sage 4px inner dot on missed past, plain hollow on future. Use `AnimatedContainer(duration: WayMotion.standard, curve: WayMotion.easeStandard)` for state changes. Drive from `weeklyCompletedDaysProvider`.
4. `_MonthlyHeatMap` — keep, audit for hardcoded colors and replace with theme tokens
5. `_GoalProgressSection` — cap visible goals at 2; if more, render a "See all goals →" `TextButton.icon` (chevron right) below
6. **`_QuickLogPillRow` (NEW)** — replaces `_QuickActionsGrid` AND `_TrackTodayGrid`. Horizontal `SingleChildScrollView` with 4 `OutlinedButton.icon`s (40px tall): Journal · Meal · Sleep · Photo. Sage outline, Manrope `labelMedium` text, Material icon (24px) before label. Each navigates via `context.push(Routes.X)`.

### Riverpod data flow for C1

```
weeklyCompletedDaysProvider  ──► _WeekStrip
todaySessionsProvider        ──► _TodayFocalCard (with missedYesterdayProvider for the rest-day banner)
goalsProvider                ──► _GoalProgressSection (cap at 2)
streakProvider               ──► _GreetingHeader (already wired)
```

No new providers. If you find yourself wanting one, you're probably duplicating something `home_providers.dart` already exports.

### Testing strategy for C1

The 9 existing tests in `home_page_test.dart` likely:
- Pump the page with mock repos (see lines 1–60 of the test file)
- Assert on widget types like `_QuickActionsGrid`, `_TrackTodayGrid`, `_TodaySessionCard`

Some tests will need to update their `find.byType` to point at the new widgets. **That's expected**, not a regression. Walk every test before deleting an old widget; for each test:
- If it asserts a behavior (e.g. "tapping the planned-session card navigates to active session") — keep the behavior, update the selector to find the new `_TodayFocalCard`.
- If it asserts an old widget exists (`find.byType(_QuickActionsGrid), findsOneWidget`) — replace with `find.byType(_QuickLogPillRow)`.

**Add new tests:**
- `today_focal_card_test.dart` co-located, covering all 4 states (loading is OK to skip): active · planned · completed · no-session+missed · no-session+rest.

### Definition of done for C1

- `flutter analyze frontend/mobile/lib/features/dashboard/...` → zero warnings
- `flutter test frontend/mobile/lib/features/dashboard/...` → ≥9 passing (existing) + new focal card tests
- The build tree under `HomePage.build()` contains exactly 6 top-level children
- No hex colors, no raw `Duration(...)`, no `OutlineInputBorder` introduced

### Out of scope for C1 (do not touch)

- `_GreetingHeader` (already revamped)
- `home_providers.dart` (already complete)
- The `RecoveryBanner` widget definition (it's used elsewhere — just remove its slot from home, don't delete the widget)

---

## C2 — Onboarding visual revamp

### Critical correction up-front

This is **not** a "build 5 new step screens" task. The flow already exists in **one file** as a 6-step `PageView`. Your job is to re-skin steps 1–5; step 0 (welcome) was already revamped in v1.0 and should be left alone.

### Files

- **Page:** `frontend/mobile/lib/features/profile/presentation/pages/onboarding_flow.dart` (804 lines)
- **Test:** same folder, `onboarding_flow_test.dart` (9 tests, must end this work green)

### Existing step methods (line numbers approximate, confirm with grep)

```
_buildWelcomeStep        line 289   ◄ DO NOT TOUCH (already revamped)
_buildBasicInfoStep      line 320   ◄ revamp to "Basic info" pattern below
_buildGoalStep           line 397   ◄ revamp to option-card pattern
_buildActivityLevelStep  line 459   ◄ revamp to option-card pattern
_buildSportsStep         line 558   ◄ revamp to chip-grid pattern
_buildEquipmentStep      line 607   �O revamp to chip-grid pattern + "Let's go" CTA
```

State already in place (all in `_OnboardingFlowState`):
- `_pageController · _progressController · _currentStep · _totalSteps = 6`
- `_nameController · _ageController · _heightController · _weightController` (TextEditingControllers)
- `_selectedGoal: TrainingGoal? · _selectedActivityLevel: ActivityLevel?`
- `_selectedSports: Set<String> · _selectedEquipment: Set<String>`
- `_trainingDaysPerWeek: int · _injuries: List<Injury> · _saving: bool`
- `_sportOptions: List<String>` (15 sports)
- `_equipmentOptions: List<(String, String)>` (11 items)

**Reuse all of this.** Do not rename, do not refactor the controller logic, do not split into separate files.

### Revamp prescription per step

For all 5 steps:
- Replace the section title with a **Fraunces italic prompt** (`AppTypography.fraunces(size: 24, italic: true)` or whichever helper the codebase exposes; check `app_typography.dart`)
- Use `AppSpacing.lg` (24) vertical rhythm between elements

**Step 1 — Basic info (`_buildBasicInfoStep`)**
- Prompt: *"A little about your body."*
- Underline-only `TextField`s for age, height, weight (the theme handles the underline — pass no decoration overrides). Keep the existing controllers.
- "Next" CTA — terracotta `FilledButton` at 56px. Should disable when any required field is empty (the existing `_next()` already advances; you may need to add an `enabled` state).

**Step 2 — Goal (`_buildGoalStep`)**
- Prompt: *"What's your main goal?"*
- 4 large option cards using the **`_OptionCard` pattern from `lib/features/assessment/presentation/pages/initial_assessment_flow.dart`** — go read that widget. The pattern: warm-surface card, 4px terracotta left strip on selected, icon + label + supporting text.
- One `TrainingGoal` enum value selected at a time → `_selectedGoal`.

**Step 3 — Activity level (`_buildActivityLevelStep`)**
- Prompt: *"How active are you right now?"*
- Same `_OptionCard` pattern, 4 levels mapped to `ActivityLevel` enum values.

**Step 4 — Sports (`_buildSportsStep`)**
- Prompt: *"What movement do you do?"*
- Multi-select chip grid using the **`_TagPill` pattern from `lib/features/exercises/presentation/widgets/exercise_card.dart`** — outlined sage, selected state fills sage lightly with terracotta text.
- 3 chips per row using `Wrap`. Iterate over existing `_sportOptions`. Selection state lives in `_selectedSports`.

**Step 5 — Equipment (`_buildEquipmentStep`)**
- Prompt: *"What do you have access to?"*
- Same chip grid pattern, iterate over existing `_equipmentOptions` (note: it's a list of `(String, String)` records — first is the key for `_selectedEquipment`, second is the display label).
- Final CTA: terracotta `FilledButton` "Let's go" at 56px → calls the existing `_saveOnboarding()` (or whatever the existing complete-handler is named — find it near line 130).

### Progress indicator

The current implementation uses an `AnimationController` driving a `LinearProgressIndicator`-style bar (`_progressController.animateTo(...)` in `_updateProgress()`). Replace this with the **stretching-dot pattern from `_buildHeader` in `initial_assessment_flow.dart`** — 6 dots, current grows from 8→24px wide, completed dots stay 24px wide, future dots stay 8×8.

You can keep `_progressController` and just change what it drives (or remove it if the new dots work off `_currentStep` directly — preferred, simpler).

### Definition of done for C2

- All 9 existing tests in `onboarding_flow_test.dart` pass without modification (controllers, enum values, and onTap handlers preserved → behavioral surface unchanged → assertions still hold)
- If a test fails because it asserted on the old visual (e.g. `find.byType(LinearProgressIndicator)`), update the selector but do not change what the test verifies
- One new widget test per re-skinned step asserting: Fraunces italic prompt text is present, progress dots show the correct active index for that step, and the primary CTA exists
- `flutter analyze frontend/mobile/lib/features/profile/presentation/pages/onboarding_flow.dart` → zero warnings

### Out of scope for C2 (do not touch)

- `_buildWelcomeStep` — already revamped
- The `_pageController` / `_next()` / `_back()` / save logic
- The `TrainingGoal` / `ActivityLevel` enums or their values
- `_sportOptions` / `_equipmentOptions` data
- The `UserProfile` entity / repository

---

## Final sweep (after all three tasks pass)

```bash
cd frontend/mobile

flutter analyze                # MUST be zero warnings
flutter test                   # baseline 721 → expect ≥731 + your new C1/C2 tests
```

If the test count drops below baseline, bisect to the commit that introduced the regression before handing back. **Never use `--no-verify` to bypass hooks.**

---

## Reference files (quick index)

| What | Where |
|---|---|
| Brand tokens | `lib/core/theme/app_colors.dart · app_typography.dart · app_spacing.dart · app_motion.dart` |
| Stretching progress-dot pattern | `lib/features/assessment/presentation/pages/initial_assessment_flow.dart` → `_buildHeader` |
| 4px terracotta left strip technique | `lib/features/sessions/presentation/pages/session_view.dart` → `_ExerciseBlockCard` (`Stack` + `Positioned.fill(width: 4)`) |
| `_OptionCard` (selected state, warm-surface card) | `lib/features/assessment/presentation/pages/initial_assessment_flow.dart` |
| `_TagPill` (sage outlined chip) | `lib/features/exercises/presentation/widgets/exercise_card.dart` |
| Custom-painted ring (for the focal card optional ring decoration) | `lib/features/goals/presentation/pages/goal_list_page.dart` → `_RingPainter` |
| Multi-mock test pattern | `lib/features/dashboard/presentation/pages/home_page_test.dart` (lines 1–60) |
| App-wide widget keys | `lib/core/constants/app_keys.dart` (don't remove existing keys; add new ones for new widgets) |

---

## When you finish

Write a short handoff in `docs/screens/revamp-v1/discovery/handoff-2026-04-DD.md` (use today's date) covering:
- Which of C1/C2/D you completed
- New test counts (before/after for each task)
- Any production-code architecture issues you flagged but didn't fix (per the D rules)
- Any test selectors you had to update (call them out so the next reviewer doesn't think they're regressions)
- Anything in `plan.md` or `phases-plan.md` that needs updating to reflect what landed
