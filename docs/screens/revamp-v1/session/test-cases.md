# Session — Test Cases (Phase B2)

Mapped to `.claude/rules/testing.md`. Legend: `U` = unit · `W` = widget · `I` = integration (Firebase emulator) · `E` = E2E.

---

## Home Dashboard — `HomePage`

Files: `home_page_test.dart` (9 widget tests) + `today_focal_card_test.dart` (4 focal-state tests).

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 1 | W | `today_focal_card_test.dart` | `todaySessionsProvider` → 1 planned session | `_FocalCardShell` renders "Start Session" CTA, terracotta strip visible (✅) |
| 2 | W | `today_focal_card_test.dart` | `todaySessionsProvider` → 1 inProgress | "Continue Session" CTA (✅) |
| 3 | W | `today_focal_card_test.dart` | `todaySessionsProvider` → 1 completed | "Great work today!" + sage tint (✅) |
| 4 | W | `today_focal_card_test.dart` | Empty + `missedYesterdayProvider == true` | Missed banner shown above no-session content (✅) |
| 5 | W | `home_page_test.dart` | Pump | Greeting reads "Good <morning/afternoon/evening>" (✅) |
| 6 | W | `home_page_test.dart` | `streakProvider == 0` | Streak chip not in tree (✅) |
| 7 | W | `home_page_test.dart` | `streakProvider == 5` | Streak chip reads "5 days" (✅ implied) |
| 8 | W | `home_page_test.dart` | `activeGoalsProvider` returns 3 goals | Only 2 cards rendered + "See all goals" link (✅) |
| 9 | W | `home_page_test.dart` | Pump | Quick-log row renders all 4 pills with `AppKeys.quickActionLog*` (✅) |
| 10 | W | `today_focal_card_test.dart` | `todaySessionsProvider` returns BOTH inProgress + completed | Renders inProgress card; completed work invisible — **currently-missing**, surfaces spec edge case #2 (priority bug) |
| 11 | W | `home_page_test.dart` | `profileStreamProvider` loading | Greeting renders "Good morning." (no name, trailing dot only) — **currently-missing**, surfaces spec edge case #1 |
| 12 | W | `home_page_test.dart` | `streakProvider == 1` | Chip reads "1 day" (singular) — **currently-missing** |
| 13 | W | `home_page_test.dart` | `activeProtocolsProvider` returns 1 active protocol with 1 workout | Daily routine card renders above focal card — **currently-missing** |
| 14 | W | `home_page_test.dart` | Tap daily-routine card while `_starting == true` | onTap is null (no double-start) — **currently-missing** |
| 15 | W | `home_page_test.dart` | Tap "See all goals" link | `context.go(Routes.goals)` invoked — **currently-missing** |
| 16 | I | `home_page_int_test.dart` | Seed 3 completed sessions in Firestore for current week | `_WeekStrip` renders 3 sage-filled circles — **currently-missing** |
| 17 | E | `integration_test/home_e2e_test.dart` | Tap focal CTA on planned session | App navigates to `Routes.sessionActive`, `_buildWorkout` renders — **currently-missing E2E** |

---

## Active Session — `SessionView`

File: `session_view_test.dart`.

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 18 | W | `session_view_test.dart` | `activeSessionProvider` loading | Only `CircularProgressIndicator` rendered |
| 19 | W | `session_view_test.dart` | `activeSessionProvider` error | Error text rendered |
| 20 | W | `session_view_test.dart` | `activeSessionProvider` data with session | Focus title + date rendered, exercise blocks render |
| 21 | W | `session_view_test.dart` | Pump with 3 blocks where block[1] has `isStarted: true, completedSetsCount < plannedSets` | block[1] is `isCurrent: true`, expanded by default |
| 22 | W | `session_view_test.dart` | Tap a set circle | `onToggle(true)` called → `recordSet` invoked with reps from `plannedReps` default |
| 23 | W | `session_view_test.dart` | Type "12" into reps field, tap circle | `recordSet` receives `reps: 12` |
| 24 | W | `session_view_test.dart` | Tap "Complete workout" | Bottom sheet appears with hint "How did it feel…" |
| 25 | W | `session_view_test.dart` | Open sheet, tap "Save & finish" | `completeSession(notes: '')` called, navigates via `pushReplacement` to summary |
| 26 | W | `session_view_test.dart` | Open sheet, tap "Cancel" | Sheet dismissed; `completeSession` NOT called |
| 27 | W | `session_view_test.dart` | Open sheet, drag to dismiss | Returns null → treated as cancel; `completeSession` NOT called — **currently-missing**, surfaces spec edge case #7 |
| 28 | W | `session_view_test.dart` | Tap close-X, tap "Stay" in dialog | Session NOT discarded; remains on view — **currently-missing** |
| 29 | W | `session_view_test.dart` | Tap close-X, tap "Exit" | `discard()` called, navigation pops |
| 30 | W | `session_view_test.dart` | Type reps but never tap circle, then tap close-X → Exit | Discarded — typed reps lost; this asserts the data-loss path — **currently-missing**, surfaces edge case #9 |
| 31 | W | `session_view_test.dart` | Tap RPE 7 hit zone (10 zones evenly distributed) | Notifier `setRpe(exerciseId, 7)` called; dot animates to `((7-1)/9) * (trackWidth - 18)` |
| 32 | W | `session_view_test.dart` | RPE already 5, tap RPE 5 again | Notifier called with same value (idempotent) |
| 33 | W | `session_view_test.dart` | `state == null` mid-session | Renders `'No active session'` Center text with no AppBar — **currently-missing**, surfaces dead-end edge case #8 |
| 34 | U | `active_session_state_test.dart` | `hasAnyWork` getter on session | True when at least one set is completed |
| 35 | I | `session_view_int_test.dart` | Seed planned session, complete 3 sets, finish | Firestore session doc has `status == 'completed'` and 3 actualSets — **currently-missing** |
| 36 | E | `integration_test/session_e2e_test.dart` | Start → complete 1 block → finish → land on summary | Navigation chain matches spec §1 — **currently-missing E2E** |

---

## Session Summary — `SessionSummaryPage`

File: `session_summary_page_test.dart`.

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 37 | W | `session_summary_page_test.dart` | Mount with valid sessionId | Sage check mark `CustomPaint` renders, headline reads "Workout Complete!" |
| 38 | W | `session_summary_page_test.dart` | Pump 800ms after mount | `_celebController` complete; check tick has drawn fully (verify via finder on `_CheckPainter` progress ≈ 1.0) |
| 39 | W | `session_summary_page_test.dart` | Session has 3 completed blocks, 9 sets, 25 min | Stats row reads "3 · 9 · 25m" |
| 40 | W | `session_summary_page_test.dart` | Session duration is null | Stats row reads "— " for duration |
| 41 | W | `session_summary_page_test.dart` | Session.notes empty | `_NotesCard` not rendered |
| 42 | W | `session_summary_page_test.dart` | sessionId not in history yet | Renders empty stats (0 · 0 · —), no exercise tiles, no spinner — **currently-missing**, surfaces edge case #10 |
| 43 | W | `session_summary_page_test.dart` | Progression service returns advance suggestion for exercise A | `ProgressionSuggestionCard` for A renders below exercises |
| 44 | W | `session_summary_page_test.dart` | Tap dismiss on suggestion card | Card swaps to `SizedBox.shrink` next build — no undo affordance — **currently-missing** |
| 45 | W | `session_summary_page_test.dart` | Mock progression service called by `_computeSuggestions` | Verify wellness inputs are literal `4.0, 4.0, 4.0` — **currently-missing**, documents the hardcoded-defaults debt (edge case #6) |
| 46 | W | `session_summary_page_test.dart` | Tap "Back to home" | `context.go(Routes.home)` invoked |
| 47 | W | `session_summary_page_test.dart` | Provider error | `'Error: $e'` text rendered, no retry button — **currently-missing** (documents missing retry) |
| 48 | I | `session_summary_int_test.dart` | Seed completed session with 2 progression rules; mount with id | Suggestions match expected service output — **currently-missing** |
| 49 | E | `integration_test/session_e2e_test.dart` | Full loop: start → complete → land on summary → tap home | App returns to home, focal card now shows "completed" state — **currently-missing E2E** |

---

## Currently-missing scenarios summary

The four most valuable gaps:

1. **InProgress + completed today (#10).** Today's focal-card priority can hide a completed session if any inProgress one exists. No test guards this; the user-facing copy ("$extraSessionCount sessions done") is also wrong in that case. Worth a regression test plus a product decision (show both? only completed?).
2. **Set circles + RPE hit zones are under 48 px (a11y §5).** Testing today only checks behavior, not size. Add a widget test using `tester.getSize` to assert these are ≥48 px or, if intentionally smaller, document the exception.
3. **Mid-session `state == null` is a dead-end (#33 / edge case #8).** No test, no Scaffold AppBar, no exit button. iOS 16+ users without back-gesture have to kill the app.
4. **Bottom-sheet drag-dismiss silently aborts complete-workout (#27 / edge case #7).** `null` is treated as cancel. A user who drags down expecting "back to workout" gets it; a user who drags down expecting "save anyway" silently loses. Worth either confirming or documenting the behavior.
