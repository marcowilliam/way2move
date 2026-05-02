# Assessment & AI — Test Cases (Phase B4)

Mapped to `.claude/rules/testing.md`. Legend: `U` = unit · `W` = widget · `I` = integration · `E` = E2E.

---

## Initial Assessment Flow — `InitialAssessmentFlow`

File: `initial_assessment_flow_test.dart`.

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 1 | W | `initial_assessment_flow_test.dart` | Pump | Step 0 (`_StepIntro`) rendered with "Begin" CTA |
| 2 | W | `initial_assessment_flow_test.dart` | Tap "Begin" | PageView advances to step 1 (occupation) |
| 3 | W | `initial_assessment_flow_test.dart` | On step 1 with no selection | Continue is disabled (onNext null) |
| 4 | W | `initial_assessment_flow_test.dart` | Tap an occupation card | `_form.occupation` set; Continue enabled |
| 5 | W | `initial_assessment_flow_test.dart` | On step 2 with no selection | Continue disabled |
| 6 | W | `initial_assessment_flow_test.dart` | Tap '4 – 6 hours' card | `_form.sittingHours == '4to6'`; Continue enabled |
| 7 | W | `initial_assessment_flow_test.dart` | On step 3 with no selection | Continue ENABLED (no min selection) |
| 8 | W | `initial_assessment_flow_test.dart` | Toggle Neck/Upper Back chip | `_form.neckPain` flips |
| 9 | W | `initial_assessment_flow_test.dart` | On step 4 with default state (`isRunner == false`) | Continue enabled (default flag is a real selection) — **currently-missing**, surfaces edge case #4 |
| 10 | W | `initial_assessment_flow_test.dart` | Tap Continue from step 4, then pump 2000ms | Step 5 (processing) renders, then step 6 (results) auto-advances after the 1800ms `Future.delayed` |
| 11 | W | `initial_assessment_flow_test.dart` | On step 5 | No back button visible, no progress dots — **currently-missing**, documents edge case #2 |
| 12 | W | `initial_assessment_flow_test.dart` | Step 6 with empty `_detectedPatterns` | `_ResultBanner` "No significant patterns found" rendered |
| 13 | W | `initial_assessment_flow_test.dart` | Step 6 with one significant pattern | `_PatternTile` rendered with terracotta severity bar |
| 14 | W | `initial_assessment_flow_test.dart` | Step 6 default `_overallScore` (10.0) | Score ring shows "10.0", green-end gradient — **currently-missing**, surfaces edge case #3 (false-positive default score) |
| 15 | W | `initial_assessment_flow_test.dart` | Step 6, mock `userId == null` + tap "Save for later" | `submit` NOT called; `context.go(Routes.home)` invoked silently — **currently-missing**, surfaces edge case #5 |
| 16 | W | `initial_assessment_flow_test.dart` | Step 6, mock `submit` returns null + tap "Build my program" | Falls back to `context.go(Routes.home)`; no error UI — **currently-missing**, surfaces edge case #6 |
| 17 | W | `initial_assessment_flow_test.dart` | Step 6, valid save, tap "Save for later" | `_saveAndFinish` invoked; `createAssessmentProvider.submit` called once |
| 18 | W | `initial_assessment_flow_test.dart` | Step 6, tap "Record movement video" | `context.go(Routes.movementRecording, extra: {...})` invoked |
| 19 | U | `compensation_detection_service_test.dart` | Various answer maps | Returns expected pattern lists |
| 20 | U | `compensation_detection_service_test.dart` | All answers null | Returns empty list, score 10.0 — guards default-score edge case #3 |
| 21 | I | `assessment_int_test.dart` | Submit assessment via `createAssessmentProvider` | Firestore `assessments/{id}` doc created with answers + score — **currently-missing** |
| 22 | E | `integration_test/assessment_e2e_test.dart` | Walk all 7 steps, save & finish | App lands on home; assessment exists in emulator Firestore — **currently-missing** |

---

## AI Recommendation Review — `AIRecommendationReviewPage`

There is currently **no `ai_recommendation_review_page_test.dart`** — `plan.md:202-203` notes the test was deferred ("Widget test deferred — page requires full CompensationReport + UserProfile + recommendation engine; smoke-tested via analyze."). Every test below is currently-missing.

| # | Type | File (would-be) | Trigger | Expected |
|---|---|---|---|---|
| 23 | W | `ai_recommendation_review_page_test.dart` | Mount with empty detections list | `_EmptyAnalysisCard` rendered with success copy — **currently-missing** |
| 24 | W | `ai_recommendation_review_page_test.dart` | Mount with 3 detections sorted | 3 `_CompensationCard`s rendered in `report.sortedByPriority` order — **currently-missing** |
| 25 | W | `ai_recommendation_review_page_test.dart` | Mount with significant-severity detection | Severity bar `widthFactor: 1.0`, color `severitySignificant` — **currently-missing** |
| 26 | W | `ai_recommendation_review_page_test.dart` | Mount with all 7 days | 7 `_DayCard`s rendered (Mon–Sun), rest days sage-tinted, training days terracotta — **currently-missing** |
| 27 | W | `ai_recommendation_review_page_test.dart` | Tap edit on first exercise | `AlertDialog` with sets + reps fields shown — **currently-missing** |
| 28 | W | `ai_recommendation_review_page_test.dart` | Edit dialog: enter sets=5 reps="12-15", Save | `_program.weekTemplate.days[i].exerciseEntries[j].sets == 5`, `reps == "12-15"` — **currently-missing** |
| 29 | W | `ai_recommendation_review_page_test.dart` | Edit dialog: enter empty reps, Save | Reps preserves prior value (edge case #1 of edit-fallback behavior) — **currently-missing** |
| 30 | W | `ai_recommendation_review_page_test.dart` | Edit dialog: enter `0` for sets, Save | Saves 0 — no clamp (surfaces edge case #9) — **currently-missing** |
| 31 | W | `ai_recommendation_review_page_test.dart` | Tap × on the only exercise of a day | Day collapses to `DayTemplate.rest`, no toast/undo — **currently-missing**, surfaces edge case #10 |
| 32 | W | `ai_recommendation_review_page_test.dart` | Tap Accept; mock `submit` returns saved program | Snackbar floats with success copy; `context.go('/')` invoked — **currently-missing** |
| 33 | W | `ai_recommendation_review_page_test.dart` | Tap Accept; mock `submit` returns null | Error snackbar; user remains on page; can retry — **currently-missing** |
| 34 | W | `ai_recommendation_review_page_test.dart` | Construct page with engine that throws | Page crashes (no try/catch) — documents missing-error-boundary edge case #7 — **currently-missing** |
| 35 | W | `ai_recommendation_review_page_test.dart` | Open + Save edit dialog 5 times | Dialog leaks 10 `TextEditingController`s (5 sets + 5 reps) — **currently-missing**, surfaces edge case #8 |
| 36 | U | `program_recommendation_engine_test.dart` | Generate from a CompensationReport with no detections | Returns a baseline-mobility week template |
| 37 | U | `program_recommendation_engine_test.dart` | Generate with 3 days/week profile | Exactly 3 training days; rest distributed sensibly |
| 38 | I | `ai_review_int_test.dart` | Accept program with emulator | Firestore `programs/{id}` has `isActive: true` and matches `_program` — **currently-missing** |
| 39 | E | `integration_test/ai_review_e2e_test.dart` | Full flow: assessment → AI review → accept | New active program exists; user lands on home with terracotta focal-card visible — **currently-missing** |

---

## Currently-missing scenarios summary

The four most valuable gaps:

1. **Entire AI review page has no widget tests (#23–#35).** Per `plan.md:202-203` it was deferred. This is the most expensive single gap in B4 — accept-with-error, edit-dialog leaks, last-entry-removed silent-rest, and unguarded engine.throw all live here.
2. **Save failure on assessment silently navigates home (#15, #16 / edge cases #5–#6).** Three save paths short-circuit to home on null userId or null submit result. No tests, no error UI. A failed save looks identical to a successful one.
3. **Processing step has no exit (#11 / edge case #2).** The 1800ms timer is the only escape. If `_runDetection` throws, the user is stuck. Add a watchdog timer + retry, or a "Cancel" affordance.
4. **Default score 10.0 looks like a perfect baseline (#14 / edge case #3).** A user reaching step 6 by any unusual path (hot reload, deep link) sees a fake-perfect score. Either initialize to `null` and skip the ring until populated, or initialize to a sentinel (`0` or `-1`) so the bug is visible.
