# Assessment & AI — Spec (Phase B4)

**Scope:** Initial Assessment Flow (questions + processing + results = a single page with 7 PageView steps), and the AI Recommendation Review page that consumes the resulting report.
The assessment is the user's first deep onboarding into PRI/DNS-rooted compensation profiling. Its results drive the recommended program in the AI review page.
**Not in scope:** Re-assessment comparison page, Assessment timeline, Movement recording (records video; lives at `movement_recording_page.dart`).

**Source files:**

- Initial Assessment Flow — `frontend/mobile/lib/features/assessments/presentation/pages/initial_assessment_flow.dart` (1115 lines)
- AI Recommendation Review — `frontend/mobile/lib/features/programs/presentation/pages/ai_recommendation_review_page.dart` (720 lines)
- Detection service — `frontend/mobile/lib/features/assessments/domain/services/compensation_detection_service.dart`
- Recommendation engine — `frontend/mobile/lib/features/programs/domain/services/program_recommendation_engine.dart`

---

## 1. User flows

### Assessment — happy path
1. User taps "Take movement assessment" from profile/home → router pushes `Routes.assessment` → `InitialAssessmentFlow` (`:78`).
2. `_StepIntro` (step 0) — calm intro screen, "Begin" CTA → `_nextStep` advances.
3. `_StepOccupation` (step 1) — required, single-select via `_OptionCard`s. Continue disabled until `_canAdvanceOccupation == true` (`:229`).
4. `_StepSittingHours` (step 2) — required, 4 options (`'lt2' | '2to4' | '4to6' | 'gt6'`). Continue disabled until selection.
5. `_StepPainAreas` (step 3) — multi-select `_ToggleChip`s, no min selection required.
6. `_StepRunning` (step 4) — single-select between yes/no (default `_form.isRunner == false`).
7. Tapping Continue on step 4 → `_currentStep == 5` triggers `_runDetection` (`:108`) which:
   - Calls `CompensationDetectionService.detectCompensations(answers)` synchronously.
   - Calls `CompensationDetectionService.calculateOverallScore(patterns)`.
   - Sets `_detectedPatterns` and `_overallScore` via setState.
   - **`Future.delayed(1800ms)` then auto-advances to step 6 (`_StepResults`).**
8. `_StepProcessing` (step 5) — full-screen rotating circle + "Analysing your movement profile…" — purely cosmetic during the 1800ms delay.
9. `_StepResults` (step 6) — score ring (Fraunces 52px score over a custom-painted gradient ring), detected patterns list, three CTAs:
   - "Build my program" → `_saveAndBuildProgram` → push `programBuilder?fromAssessment={id}`
   - "Record movement video" → `_saveAndRecordVideo` → push `movementRecording`
   - "Save for later" → `_saveAndFinish` → `context.go(Routes.home)`
10. All three save paths await `createAssessmentProvider.notifier.submit(assessment)` and short-circuit to `Routes.home` if `userId == null` OR if `saved == null` (no error UI on save failure!).

### AI Recommendation Review
1. Page receives `CompensationReport` + `UserProfile` via `extra` (`:19-25`).
2. `initState` calls `ProgramRecommendationEngine.generate(...)` synchronously to seed `_program`. **No async / no error handling here.**
3. `_fadeController` (500ms ease-out) fades the body in.
4. User reviews movement-analysis cards (one per detection, sorted by priority) + 7 day cards.
5. Tap edit icon on an exercise row → `_editExercise(dayIndex, entryIndex)` opens an `AlertDialog` with sets/reps controllers.
6. Tap × on an exercise row → `_removeEntry` strips the entry. **If a day's last entry is removed, the day flips to `DayTemplate.rest`** (`:148-150`).
7. Tap "Accept" in `_AcceptBar` → `_accept` (`:160-180`) submits via `createProgramProvider`. On success: `context.go('/')` + green snackbar. On failure: error snackbar. **No retry; the page stays mounted with the same `_program`.**

---

## 2. States

### Initial Assessment Flow
| State | Trigger |
|---|---|
| Step 0 (intro) | Always advance-able; "Begin" CTA enabled. |
| Step 1 (occupation) — empty | `onNext: null` → CTA shows but is disabled (40% opacity convention from `_QuestionScaffold`). |
| Step 1 — selected | `onNext: _nextStep`. |
| Step 2 (sitting) — same as step 1 with 4 hour-buckets. |
| Step 3 (pain) — always advance-able (no minimum). |
| Step 4 (running) — selecting `false` is the default, so technically advance-able from mount. |
| Step 5 (processing) — read-only, 1800ms timer auto-advances. **No exit button; system back is also disabled** (header has `showBack = _currentStep > 0 && _currentStep < 5`). |
| Step 6 (results) — empty patterns | `_ResultBanner` "No significant patterns found". Score ring still drawn against `_overallScore` (default `10.0`). |
| Step 6 — patterns present | List of `_PatternTile`s, each tappable to expand. |
| Saving | `_saving == true` → buttons disabled across the page. **No spinner on the result CTAs themselves** — visual feedback is only via the disabled state. |
| Save failure | `submit()` returns null → falls through to `context.go(Routes.home)` (`_saveAndRecordVideo:191-193`, `_saveAndBuildProgram:223-225`). User loses results silently. |

### AI Recommendation Review
| State | Trigger |
|---|---|
| Mount | Sync `ProgramRecommendationEngine.generate` runs in `initState`. **If the engine throws, the page crashes.** |
| Empty detections | `_EmptyAnalysisCard` shown with "No compensations detected — great baseline movement quality!". 7 day cards still render. |
| Detections present | One `_CompensationCard` per `report.sortedByPriority`. Severity bar widthFactor: 1.0 / 0.66 / 0.33. |
| Day card — rest | Sage-tinted day badge, neutral surface, "Rest" label. |
| Day card — training | Terracotta surface, white-on-primary text, "$count ex" badge. |
| Edit dialog open | sets + reps `TextField`s; Cancel / Save. |
| Edit dialog Save with empty reps | Falls back to existing `entry.reps` (`:117-119`) — preserves prior. Empty sets value falls back to `entry.sets` (`:115`). |
| Last entry removed from a day | Day reverts to `DayTemplate.rest` (`:148-150`). **No undo.** |
| Accepting | `createProgramProvider.isLoading == true` → `_AcceptBar` disables. |
| Accept success | Snackbar floats; `context.go('/')`. |
| Accept failure | Snackbar floats; user remains on page; can retry. |

---

## 3. Edge cases the spec author dug out of the actual code

1. **Hardcoded 1800ms processing delay.** `initial_assessment_flow.dart:131-134` runs `Future.delayed(1800ms)` to "feel like analysis". The detection service is synchronous — actual computation takes microseconds. Users on slow devices see the same 1800ms. Users on fast devices also see 1800ms. The delay is a fake.
2. **Processing step has no escape hatch.** `:292-293` sets `showBack = _currentStep > 0 && _currentStep < 5` AND `showDots = _currentStep > 0 && _currentStep < 5`. On step 5 (processing) both back and dots are hidden — the user cannot retreat to fix an answer. If `_runDetection` throws (it can — service is unguarded), the user is stuck on the spinner forever.
3. **Score ring defaults to 10.0 before detection.** `_overallScore = 10.0` (`:91`) is the initial value. If a user navigates to step 6 without `_runDetection` having run (e.g. via dev hot reload), the ring shows a perfect 10/10 score with empty patterns — falsely positive.
4. **`_StepRunning` defaults to `isRunner = false`.** That makes "no, running isn't my thing" the silently-pre-selected option (`:601-606`). A user who taps Continue without reading just submits "not a runner" by default. There is no "no answer" state.
5. **All three "Save & X" CTAs short-circuit to home on userId == null.** `_saveAndFinish` `:142-145`, `_saveAndRecordVideo` `:166-169`, `_saveAndBuildProgram` `:201-205` all silently navigate home without saving anything when there's no user. The fix would be to throw or show a sign-in dialog — instead, the assessment is silently lost.
6. **Save failure on the "build program" path silently falls back to home.** `:222-226` — if `submit()` returns null, the user thinks they pressed "Build my program" but lands on home with no program created and no error shown.
7. **AI review page is constructed sync in `initState`.** `:51-54` — `ProgramRecommendationEngine.generate` runs synchronously and there's no try/catch. If the engine ever evolves to throw, the page just crashes. No loading state.
8. **Edit-exercise dialog leaks `TextEditingController`s.** `:76-77` creates two new controllers per dialog open. They are never disposed — `Navigator.pop` just closes the dialog. Each edit leaks two controllers.
9. **Edit dialog accepts negative or zero sets.** `:115` parses `int.tryParse(setsController.text.trim()) ?? entry.sets`. There's no `min(1)` clamp. A user typing `0` or `-3` saves that. The downstream session view will then render zero set rows.
10. **Last-exercise-removed → silent rest day.** `:148-150` collapses the day to `DayTemplate.rest` if the user removes the last exercise. **No undo, no toast.** Users may not realize Tuesday is now a rest day.
11. **`weekTemplate.days[dayIndex]!` force-unwrap.** `:75` and `:133` and `:260` all use `!` on the day map. If the recommendation engine ever returns a sparse map, the page crashes.
12. **Pattern list is sorted only at construct.** `:233` reads `widget.report.sortedByPriority[i]`. If the report's sort is computed lazily, every iteration re-sorts. Consider caching to a local `late final`.
13. **Score ring's `value: overallScore / 10` is unclamped.** `:718` — if the score service ever returns >10 or <0, the painter receives an invalid value and the ring renders strangely.
14. **`overallScore.toStringAsFixed(1)` always shows one decimal.** A perfect 10.0 reads "10.0", which looks awkward at 52px Fraunces. A clean "10" would be better visually.

---

## 4. Animation triggers

| Screen | Trigger | Animation |
|---|---|---|
| Assessment | Step change | `_pageController.animateToPage(350ms, easeInOutCubic)`. |
| Assessment | Step change | Header progress dots: dot at index `<= _currentStep` is 24px wide, others 8px (`:322`) — `AnimatedContainer` standard. |
| Assessment | Step 5 mount | `_StepProcessingState._controller` rotates the spinner circle indefinitely (2s repeat). |
| Assessment | Step 6 mount | `_ScoreRingPainter` paints once with the final `overallScore / 10` value — **no draw-in animation**. |
| AI Review | Mount | `_fadeController` 500ms ease-out fades the body in. |
| AI Review | Day card state change | `AnimatedContainer` (`WayMotion.standard`) on the day's surface color. |
| AI Review | Edit dialog | Material default. |
| AI Review | Accept success | Snackbar floating animation. |

---

## 5. A11y notes

### Semantic labels

- **Score ring** is a `CustomPaint` — it has no semantics. The Fraunces "8.4" + "out of 10" texts read aloud, but the ring's gradient color (terracotta → sage) communicates severity to sighted users only. **Gap:** wrap in `Semantics(label: 'Movement quality score 8.4 out of 10')`.
- **Compensation card severity bar** is a `FractionallySizedBox` with no semantics. The label ("Mild" / "Moderate" / "Significant") is a sibling. **Gap:** `MergeSemantics` so the pattern + severity + frame ratio read as one logical unit.
- **Day card "Mon/Tue" badge** is in a non-semantic `Container`. Screen reader hears just "Mon". **Gap:** wrap in `Semantics(header: true, label: 'Monday — 5 exercises')`.
- **Exercise row × button** has no `tooltip`. **Gap:** `tooltip: 'Remove exercise'`.
- **Pain-area `_ToggleChip`s** lack `Semantics(toggled:)`. The selected state communicates via color only.

### Contrast

- White-on-terracotta day cards pass AA easily.
- Severity-mild bar uses `AppColors.severityMild` — likely a low-saturation honey. **Worth measuring** against the warm-linen background.
- "out of 10" label is `theme.textTheme.labelSmall` (Stone) on warm linen — borderline at 11px.

### Tap targets

- **Pain `_ToggleChip`s** sit in a `Wrap` with `spacing: 10, runSpacing: 10`. Their internal padding determines tap size — if it's <48px the rule is violated. **Worth measuring** in widget test (`tester.getSize(find.byType(_ToggleChip))`).
- **Score ring** is a 160×160 visual, not interactive — fine.
- **Edit/× icons on exercise rows** are likely `IconButton`s — default 48×48. Probably OK.
- Step CTA "Continue" / "Build my program" are theme-default `FilledButton`s — should be 56px tall via the `_QuestionScaffold` shell.

### Focus & keyboard

- `PageView` uses `NeverScrollableScrollPhysics` — no swipe back. Step navigation is via the disabled-when-empty Continue button + back arrow.
- Step 5 (processing) cannot be exited; system back is disabled. **Major a11y gap** if the page hangs or the user wants to fix an answer.
