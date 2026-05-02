# Exercise & Program — Spec (Phase B3)

**Scope:** Exercise Library, Exercise Detail, Program Detail.
The exercise/program surface is the user's reference + planning area: browse the catalog (built-in + custom), open detail to read cues, see the active program's weekly schedule.
**Not in scope:** Add-exercise dialog (modal subtree below `_AddExerciseDialog`), filter sheet (modal), week-template editor internals (`week_template_editor.dart` is its own widget).

**Source files:**

- Exercise Library — `frontend/mobile/lib/features/exercises/presentation/pages/exercise_list_page.dart` (725 lines)
- Exercise Detail — `frontend/mobile/lib/features/exercises/presentation/pages/exercise_detail_page.dart` (496 lines)
- Program Detail — `frontend/mobile/lib/features/programs/presentation/pages/program_detail_page.dart` (212 lines)
- Card widget — `frontend/mobile/lib/features/exercises/presentation/widgets/exercise_card.dart`

---

## 1. User flows

### Browse → detail
1. User taps "Exercises" tab → `ExerciseListPage` (`:14`) renders.
2. `_listController` (`WayMotion.reward`) starts immediately on init — every card slides up + fades in via per-index `Interval` (`:276-291`) staggered by 0.05.
3. User types in the search field → `_searchController.onChanged` writes to `exerciseSearchQueryProvider` and calls `setState(() {})` to refresh the suffix-icon clear button (`:105-108`).
4. User taps a type chip in `_InlineTypeChips` → `exerciseFilterProvider.notifier.state = filter.copyWith(typeTags: [...])` — list refilters.
5. Tap a card → `context.push(Routes.exerciseDetail(id))`. The card's `Hero` tag is `'exercise-${id}'`, which the detail page's `SliverAppBar.flexibleSpace` matches (`:96`).
6. On the detail page, `_controller` (settled) fades the body in. Tap the back button or "Add to session" → `Navigator.maybePop()` (`:240`).

### Filter via sheet
1. Tap the tune icon in the AppBar → `_showFilterSheet` opens `_FilterSheet` modal bottom sheet.
2. The icon's `Badge.isLabelVisible` flips on when `!filter.isEmpty`.
3. Active filters render a horizontal pill row (`_ActiveFiltersRow`) below the type chips, each pill tappable to remove its filter.

### Add custom exercise
- Tap the "+" icon → `_showAddExerciseDialog` opens `_AddExerciseDialog`.

### Open active program
1. User navigates to "My program" → `ProgramDetailPage` (`:11`).
2. `activeProgramProvider` resolves: loading → spinner; error → "Something went wrong" centered text; data null → `_EmptyState` ("No active program"); data → `_ProgramBody`.
3. `_ProgramBody` (`:98`) renders: program name (Fraunces displaySmall), metadata row (`durationWeeks` + `trainingDays`), goal box (terracotta-tinted, hidden if empty), then the `WeekTemplateEditor`.
4. AppBar overflow menu (only present on data state) → "Deactivate program" → confirm dialog → `deactivateProgramProvider.deactivate(program.id)` → pops the page.

---

## 2. States

### Exercise Library
| State | Trigger |
|---|---|
| Loading | `exerciseListProvider.loading` → centered spinner inside `Expanded`. |
| Error | Provider error → red "Could not load exercises" text. **No retry button.** |
| Empty unfiltered | `exercises.isEmpty && filter.isEmpty && search empty` → `_EmptyState(isFiltered: false)` "No exercises yet". |
| Empty filtered | `exercises.isEmpty && (!filter.isEmpty || _searchController.text.isNotEmpty)` → `_EmptyState(isFiltered: true)` "No exercises match your filters". |
| Data | List of cards, staggered entrance once. |
| Search active | Suffix close-X visible; tap clears controller + provider. |
| Filter active | Badge dot on the tune icon + `_ActiveFiltersRow` visible. |
| Filter sheet open | Modal bottom sheet, drag-dismissable. |
| Add dialog open | Modal alert dialog. |

### Exercise Detail
| State | Trigger |
|---|---|
| Loading | Spinner inside Scaffold. |
| Not found | `data == null` OR `error` → `_NotFoundScaffold` ("Exercise not found", AppBar with back). |
| Data | Hero header tinted sage (alpha 0.10), title, tag row, region wrap (if any), description (if any), cues (collapsible, expanded), progressions/regressions (collapsible, collapsed), equipment wrap. |
| Cue list | Numbered terracotta circles. |
| Hero from list | Hero tag `'exercise-${id}'` matches the card. |
| Bottom CTA | Always reads "Add to session" — `Navigator.maybePop()` (no actual session API call here). |

### Program Detail
| State | Trigger |
|---|---|
| Loading | Spinner. |
| Error | "Something went wrong" text — **no retry**. |
| No active program | `_EmptyState` with self-improvement icon + copy. **No CTA button** to navigate to an assessment or to a builder. |
| Data | Name + metadata + goal box (if non-empty) + WeekTemplateEditor. |
| Overflow menu | Visible only on data state with non-null program. Single item: "Deactivate program". |
| Confirm deactivate | AlertDialog with Cancel/Deactivate; on Deactivate → repository + Navigator pop. |

---

## 3. Edge cases the spec author dug out of the actual code

1. **Search-clear path mutates state and provider out of sync.** `exercise_list_page.dart:96-101` clears `_searchController` AND writes empty string to `exerciseSearchQueryProvider`, then `setState(() {})`. The `setState` is purely so the `suffixIcon` re-renders without the close button — the provider write would already trigger filtering. This double mechanism is fragile: any future change that replaces `setState` with a Riverpod listener will leave the close button stuck.
2. **Type chips are rendered as a single horizontal row, no overflow indicator.** `_InlineTypeChips` (`:159-212`) renders every `ExerciseType.values` entry inside a `ListView` with horizontal scroll. There is no scroll-affordance arrow or fade gradient at the right edge — users may not realize there are more types off-screen.
3. **Active-filters row sits below the type chips conditionally.** `:112` adds `_ActiveFiltersRow` only when `!filter.isEmpty`. This causes a layout jump (the page contents shift down by ~48px) the first time a filter is applied. No animation guards this.
4. **`_humanize` lives on TWO classes.** `_InlineTypeChips._humanize` (`:202-211`) and `_ExerciseDetailViewState._humanize` (`exercise_detail_page.dart:252-261`) are byte-for-byte identical. Easy to drift.
5. **Hero crash on missing exercise.** `exercise_detail_page.dart:23` returns `_NotFoundScaffold` when `exercise == null`. But the route arrived via `Hero` from the list — the detail page's Hero tag never matches because the `SliverAppBar.flexibleSpace` Hero is gated on the `_ExerciseDetailView` branch. Result: the Hero animation aborts mid-flight and the user sees a quiet flash before the not-found message. **No graceful recovery.**
6. **Detail page errors are silently identical to "not found".** `:29` collapses `error` and `data == null` into the same `_NotFoundScaffold`. A network/permission error reads as "Exercise not found" — misleading.
7. **"Add to session" CTA is a lie on standalone detail visits.** `:239-245` renders a 56px terracotta `FilledButton.icon` reading "Add to session" but its `onPressed` is `Navigator.maybePop()`. If the user opened the detail directly (not from an active session flow), tapping the button just navigates back — no session created, no exercise added. **Misleading copy.**
8. **Coaching cues numbered with hardcoded `TextStyle`.** `:166-170` sets `fontSize: 11, fontWeight: w700, color: textOnPrimary` directly instead of using `AppTypography.manrope` or theme tokens. Diverges from brand-tokens-everywhere rule.
9. **Program empty state has no action.** `program_detail_page.dart:179-211` shows "No active program" copy but no button to start an assessment or open the builder. Per `plan.md` the assessment generates a program — the empty state should link to it.
10. **Deactivate dialog uses `FilledButton` for the destructive action.** `program_detail_page.dart:84-87` makes "Deactivate" the terracotta primary action. Standard Material guidance is to use a destructive (red) accent for destructive verbs, especially when the alternative is "Cancel". Easy to mis-tap.
11. **`activeProgramProvider` returning `null` is treated identically to "user has no program ever".** Empty state copy "Complete your movement assessment to generate a program, or build one manually." (`:202-205`) assumes the user is greenfield. If a previous program was just deactivated, the user lands here with the same message — no acknowledgement.
12. **Goal banner is hidden when `program.goal.isEmpty`.** `:149` — there's no fallback ("No goal set") nor an edit affordance from this screen.

---

## 4. Animation triggers

| Screen | Trigger | Animation |
|---|---|---|
| Library | Mount | `_listController` runs `WayMotion.reward`. Per-card stagger: `Interval((i*0.05).clamp(0,0.8), (i*0.05+0.3).clamp(0,1), curve: Curves.easeOut)`. Each card fades + translates from `Offset(0, 20)` to zero. |
| Library | Filter chip tap | `AnimatedContainer` (`WayMotion.micro`) on selected color/border. |
| Library | Filter applied | `_ActiveFiltersRow` mounts/unmounts with no animation — instant insertion. |
| Detail | Mount | `_controller` runs `WayMotion.settled`; `FadeTransition` over the `CustomScrollView`. |
| Detail | Library → Detail | `Hero` with tag `'exercise-${id}'` (sage tinted icon container). |
| Detail | Tap collapsible section | `_CollapsibleSection` toggles with its own animation (likely `AnimatedSize` — see `:367`). |
| Program | Overflow menu | Material `PopupMenuButton` default expand. |
| Program | Deactivate confirm | Material `showDialog` default. |

---

## 5. A11y notes

### Semantic labels

- **Library AppBar tune icon** has `tooltip: 'Filter'` (`:65`). Good — screen reader announces this. Badge state (`isLabelVisible: !filter.isEmpty`) is **not announced** — the tooltip stays "Filter" whether 0 or 5 filters are active. **Gap:** dynamic tooltip e.g. "Filter (3 active)".
- **Add-exercise icon** has `tooltip: 'Add custom exercise'` — good.
- **Search field** has `hintText: 'Search exercises…'` — Material exposes this. Clear button is an `IconButton(icon: Icons.close)` with no tooltip. **Gap.**
- **Type chips** are `InkWell` with no `Semantics` selected/button hint. The selected color is the only signal. **Gap:** wrap in `Semantics(button: true, selected: selected)`.
- **Cue numbers** ("1", "2", "3" inside the terracotta circles) read aloud separately from the cue text. Screen reader hears: "1, Drive your heel through the floor, 2, Squeeze your glutes". **Gap:** wrap each cue in `MergeSemantics` so the number + text are read as one node.
- **Region chips** on detail use `_humanize(r.name)` text — fine, but no role hint.
- **Program "Deactivate program" PopupMenuItem** has accessible default Material semantics.

### Contrast

- Primary cue numbers (white on terracotta) — passes AA.
- Sage-tinted hero header (alpha 0.10) — the play-circle icon is `AppColors.accent` on warm-linen — borderline at small icon sizes (here 64px, fine).
- Active-filter pill text — needs a check; rendered in `_FilterChip` (line 402+).
- "No exercises match your filters" body text — Stone color on warm linen, AA-OK.

### Tap targets

- **Library type chips** use `vertical: AppSpacing.sm` = 8px padding on a label of ~16px height = ~32px total. **Below 48px.** Acceptable on a desktop-style horizontal scroller, but the project rule is 48×48.
- **Search clear button** is a default `IconButton` ≥ 48px — passes.
- **Card tap target** is the entire card (large) — fine.
- **Program deactivate menu item** uses `PopupMenuItem` defaults — 48px. Passes.
- **Detail "Add to session" CTA** is `Size.fromHeight(56)` — passes.

### Focus & keyboard

- The horizontal type-chip row swallows keyboard focus into its scrolling list. Keyboard users can tab through individual chips, but there's no visible focus indicator — the only signal is the color change on selection.
- Filter sheet bottom-sheet is dismissable via Esc / system back.
