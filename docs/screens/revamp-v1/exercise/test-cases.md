# Exercise & Program — Test Cases (Phase B3)

Mapped to `.claude/rules/testing.md`. Legend: `U` = unit · `W` = widget · `I` = integration · `E` = E2E.

---

## Exercise Library — `ExerciseListPage`

File: `exercise_list_page_test.dart`.

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 1 | W | `exercise_list_page_test.dart` | Provider loading | Spinner rendered inside `Expanded` |
| 2 | W | `exercise_list_page_test.dart` | Provider data with 5 exercises | 5 `ExerciseCard`s rendered |
| 3 | W | `exercise_list_page_test.dart` | Empty data, no filter | `_EmptyState(isFiltered: false)` shown — copy "No exercises yet" |
| 4 | W | `exercise_list_page_test.dart` | Empty data, filter or search active | Copy "No exercises match your filters" |
| 5 | W | `exercise_list_page_test.dart` | Provider error | "Could not load exercises" rendered, error color |
| 6 | W | `exercise_list_page_test.dart` | Type "squat" in search | `exerciseSearchQueryProvider` updated to "squat", suffix close-X visible |
| 7 | W | `exercise_list_page_test.dart` | Tap close-X after typing | Search field clears, provider reset to '', suffix returns to null |
| 8 | W | `exercise_list_page_test.dart` | Tap a `_ScrollChip` | `exerciseFilterProvider.typeTags` toggled |
| 9 | W | `exercise_list_page_test.dart` | Pump with active filter | Tune-icon `Badge.isLabelVisible == true` |
| 10 | W | `exercise_list_page_test.dart` | Tap tune icon | `_FilterSheet` modal opens |
| 11 | W | `exercise_list_page_test.dart` | Tap card | `context.push(Routes.exerciseDetail(id))` invoked |
| 12 | W | `exercise_list_page_test.dart` | Pump 800ms after mount | All cards' opacity ≈ 1.0 (stagger settled) — **currently-missing** |
| 13 | W | `exercise_list_page_test.dart` | Apply a filter then assert layout shift | Layout jumps once filter row mounts (no animation) — **currently-missing**, surfaces edge case #3 |
| 14 | W | `exercise_list_page_test.dart` | Pump with all `ExerciseType.values` enum entries | Type-chip row scrolls horizontally beyond viewport — **currently-missing**, documents lack of overflow indicator (edge case #2) |
| 15 | W | `exercise_list_page_test.dart` | Tap "+" icon | `_AddExerciseDialog` shown |
| 16 | I | `exercise_list_int_test.dart` | Seed 50 exercises in Firestore, query with type filter | Filtered list returned matches expected — **currently-missing** |
| 17 | E | `integration_test/exercise_e2e_test.dart` | Search then tap a card | Detail page opens with matching name — **currently-missing E2E** |

---

## Exercise Detail — `ExerciseDetailPage`

File: `exercise_detail_page_test.dart`.

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 18 | W | `exercise_detail_page_test.dart` | Provider loading | Spinner Scaffold |
| 19 | W | `exercise_detail_page_test.dart` | Provider data null | `_NotFoundScaffold` shown ("Exercise not found") |
| 20 | W | `exercise_detail_page_test.dart` | Provider error | `_NotFoundScaffold` shown — same as null — **currently-missing**, surfaces edge case #6 (different errors collapse to same UI) |
| 21 | W | `exercise_detail_page_test.dart` | Provider data with full exercise | Title, tag row, region chips, description, cues, progressions, regressions, equipment all rendered |
| 22 | W | `exercise_detail_page_test.dart` | Exercise with empty cues list | "Coaching cues" section not rendered |
| 23 | W | `exercise_detail_page_test.dart` | Exercise with empty progressionIds | "Progressions" section not rendered |
| 24 | W | `exercise_detail_page_test.dart` | Exercise with `videoUrl: ''` | Hero shows `Icons.self_improvement`, not `play_circle_outline` |
| 25 | W | `exercise_detail_page_test.dart` | Pump 600ms after mount | Body fade-in complete (`_fadeAnim.value > 0.95`) |
| 26 | W | `exercise_detail_page_test.dart` | Tap "Coaching cues" header | Section toggles between expanded/collapsed |
| 27 | W | `exercise_detail_page_test.dart` | Cues = `['cue1', 'cue2', 'cue3']` | Cues are numbered 1, 2, 3 in terracotta circles |
| 28 | W | `exercise_detail_page_test.dart` | Tap "Add to session" CTA from a non-active-session entry point | `Navigator.maybePop()` invoked; no session API call — **currently-missing**, documents misleading-CTA edge case #7 |
| 29 | W | `exercise_detail_page_test.dart` | Hero from list to detail | Hero tag `'exercise-${id}'` matches; transition completes — **currently-missing E2E-style integration** |

---

## Program Detail — `ProgramDetailPage`

File: `program_detail_page_test.dart`.

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 30 | W | `program_detail_page_test.dart` | Provider loading | Spinner |
| 31 | W | `program_detail_page_test.dart` | Provider error | "Something went wrong" text |
| 32 | W | `program_detail_page_test.dart` | Provider data null | `_EmptyState` shown with copy "No active program" |
| 33 | W | `program_detail_page_test.dart` | Empty state | No CTA button to assessment/builder rendered — **currently-missing**, surfaces edge case #9 (dead-end empty state) |
| 34 | W | `program_detail_page_test.dart` | Provider data with program | Name (Fraunces displaySmall), `${durationWeeks} weeks`, `${trainingDays} days/week` rendered |
| 35 | W | `program_detail_page_test.dart` | Program with `goal: ''` | Goal banner not rendered |
| 36 | W | `program_detail_page_test.dart` | Program with goal text | Goal banner with terracotta-tint background rendered |
| 37 | W | `program_detail_page_test.dart` | Provider data null | AppBar overflow menu has 0 items (no actions) |
| 38 | W | `program_detail_page_test.dart` | Provider data with program, tap overflow | Single "Deactivate program" item shown |
| 39 | W | `program_detail_page_test.dart` | Tap "Deactivate program" → "Cancel" | Dialog dismissed; `deactivate` NOT called |
| 40 | W | `program_detail_page_test.dart` | Tap "Deactivate program" → "Deactivate" | `deactivateProgramProvider.deactivate(program.id)` called; page popped |
| 41 | W | `program_detail_page_test.dart` | Deactivate dialog | "Deactivate" button is a `FilledButton` (terracotta primary, NOT destructive-red styled) — **currently-missing**, documents the styling concern from edge case #10 |
| 42 | I | `program_detail_int_test.dart` | Seed program in Firestore, deactivate via UI | Firestore program doc has `isActive: false` — **currently-missing** |

---

## Currently-missing scenarios summary

The four most valuable gaps:

1. **"Add to session" CTA is a misleading lie (#28 / edge case #7).** The button reads "Add to session" but only pops navigation. Either rename it ("Back") or wire it up — and either way add a test guarding the actual behavior.
2. **Provider error collapses to "Exercise not found" (#20 / edge case #6).** Network errors masquerade as 404s. Add a separate `_ErrorScaffold` with retry, or at minimum a separate test that asserts current behavior so the lossy mapping is documented.
3. **Program empty state is a dead-end (#33 / edge case #9).** No CTA to assessment, no CTA to builder. The user has to manually navigate elsewhere. Test asserts the missing CTA so it shows up in the gap list.
4. **Deactivate styled as primary FilledButton (#41 / edge case #10).** Destructive action should not be terracotta-primary. Test documents current styling so a future a11y/UX pass can flip it.
