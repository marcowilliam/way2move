# Session — Spec (Phase B2)

**Scope:** Home Dashboard, Active Session (in-workout), Session Summary.
The session loop is the app's core verb: see today's focal action → start a workout → log sets/RPE → finish with a celebration. This spec covers all three screens and the transitions between them.
**Not in scope:** Standalone session creation (`create_standalone_session_page.dart`), session detail review (read-only), Calendar.

**Source files:**

- Home Dashboard — `frontend/mobile/lib/features/dashboard/presentation/pages/home_page.dart` (1210 lines, 6 sections)
- Active Session — `frontend/mobile/lib/features/sessions/presentation/pages/session_view.dart` (914 lines)
- Session Summary — `frontend/mobile/lib/features/sessions/presentation/pages/session_summary_page.dart` (804 lines)
- Today focal card test — `frontend/mobile/lib/features/dashboard/presentation/pages/today_focal_card_test.dart`
- Home providers — `frontend/mobile/lib/features/dashboard/presentation/providers/home_providers.dart`

---

## 1. User flows

### Home → Session → Summary (happy path)

1. User opens home (`home_page.dart:34`); router has already passed splash + onboarding gates.
2. `_TodayFocalCard` (`home_page.dart:165-211`) reads `todaySessionsProvider` and renders one of four `_FocalState`s based on the first session's status.
3. Tap the focal CTA → `context.push(Routes.sessionActive)` (planned/active) or `Routes.sessionStandalone` (no-session path).
4. `SessionView` (`session_view.dart:15`) reads `activeSessionProvider`; renders the workout body inside `_buildWorkout` (`:68`).
5. User taps a set's circle → `_SetRow.onToggle` calls `recordSet` on `activeSessionProvider`. Reps text comes from `_repsController` (defaults to `block.plannedReps`), kg comes from `_weightController` (empty by default).
6. RPE slider — tap any of 10 invisible hit zones to set RPE 1–10; the terracotta dot animates left along the gradient track.
7. Tap "Complete workout" → `_BottomBar._completeWorkout` (`session_view.dart:301`) opens a modal bottom sheet (`_CompleteWorkoutSheet`) for an optional notes string.
8. On "Save & finish" → `completeSession(notes: notes)` runs and `context.pushReplacement(Routes.sessionSummary(session.id))`.
9. `SessionSummaryPage` (`session_summary_page.dart:24`) starts `_celebController` immediately on `initState`. The sage check mark animates in via custom `_CheckPainter` (`:317-365`), then headline + stats fade in.
10. If progression rules suggest advancing/deloading any completed exercise, `ProgressionSuggestionCard`s render below the stats. Each card has independent Accept/Dismiss handlers that just add the exerciseId to `_dismissedExerciseIds`.
11. Tap "Back to home" → `context.go(Routes.home)`.

### Daily routine flow (Protocol pin)

When `activeProtocolsProvider` resolves to a protocol active on today, `_DailyRoutineProtocolCard` renders **above** the focal card (`home_page.dart:55-56`). Tap the pinned card → `_ProtocolWorkoutTile._start` (`:1089-1120`) runs `StartSessionFromWorkout`, sets the new session as `inProgress`, and `context.go(Routes.sessionActive)`.

### Exit-mid-session flow

Tap close-X in the SliverAppBar → `_confirmExit` (`session_view.dart:178-200`) shows an `AlertDialog`. "Exit" calls `activeSessionProvider.notifier.discard()` then `context.pop()`. There is no "save draft" option — the session is discarded.

---

## 2. States

### Home Dashboard
| Section | States |
|---|---|
| `_GreetingHeader` (`:76`) | `firstName` derived from `profileStreamProvider.valueOrNull?.name.split(' ').first` — falls back to `''` when profile is loading. Streak chip hidden when `streak == 0`. |
| `_DailyRoutineProtocolCard` (`:1041`) | Hidden (`SizedBox.shrink`) when no active protocols match today; spinner inline on the tile while `_starting` is true. |
| `_TodayFocalCard` (`:165`) | `loading` → `_FocalSkeleton`. `error` → `SizedBox.shrink`. `data` → first matching of inProgress/completed/planned/noSession. |
| `_WeekStrip` (`:539`) | 7 fixed circles. Per day: completed (sage filled + check), today (terracotta ring), missed past (hollow + sage 6×6 dot), future (hollow). |
| `_MonthlyHeatMap` (`:629`) | Sage-filled cells for completed; terracotta-tinted for today; sessionPlanned-tinted for planned-not-future; transparent for future. |
| `_GoalProgressSection` (`:778`) | Loading/error → `SizedBox.shrink`. Empty → `_NoGoalsCard`. Otherwise displays max 2 + "See all goals" link if more exist. |
| `_QuickLogPillRow` (`:944`) | Static — 4 outlined pills, horizontal scroll. No empty/error state. |

### Active Session
| State | Trigger |
|---|---|
| `loading` | `activeSessionProvider` not yet resolved → spinner Scaffold (`session_view.dart:51-53`). |
| `error` | Provider error → `Center(Text('Error: $e'))` (`:54-56`). **No retry button.** |
| `state == null` | Provider resolved but no session → `Center(Text('No active session'))` (`:58-62`). **No way to navigate back from this view.** |
| `data` | Workout rendered. `currentIndex` = first incomplete block (`:72-74`). Current block expanded by default. |
| Set circle: incomplete | Outlined circle with set number text. |
| Set circle: completed | Sage-filled circle with check icon. |
| RPE: unset | Track shows gradient, no dot, label "Tap to set". |
| RPE: set | Terracotta dot animates to position `((currentRpe - 1) / 9) * (trackWidth - 18)`. |
| `isSubmitting` | Bottom bar's `Complete workout` swaps to spinner; entire button disabled. |
| Complete-sheet open | Bottom sheet with notes field. Cancel pops false; Save & finish pops true. |

### Session Summary
| State | Trigger |
|---|---|
| `historyAsync.loading` | Spinner Scaffold (`:107-109`). |
| `historyAsync.error` | `Center(Text('Error: $e'))` — **no retry**. |
| `session == null` (latency) | Renders `_buildSummaryScaffold(context, null, exercises)` (`:118-121`) — minimal summary with zero counts, no exercise tiles, no progression cards. |
| `session != null`, no completed blocks | Stats row reads "0 exercises · 0 sets · —". No exercise tiles. |
| Progression suggestions present | Suggestion cards render below exercise list. Each has accept/dismiss → adds to `_dismissedExerciseIds`. |
| Suggestion dismissed | Card returns `SizedBox.shrink` next build. **No undo.** |
| Notes empty | `_NotesCard` not rendered (`:198`). |

---

## 3. Edge cases the spec author dug out of the actual code

These required reading the `.dart` files; they're not in `plan.md`.

1. **Home greeting silently drops the name.** `home_page.dart:85` does `profile?.name.split(' ').first ?? ''`. While the profile stream is loading, the greeting reads "Good morning." with a trailing dot but no name — for a moment on every cold start. After load, the name appears. There's no skeleton or placeholder.
2. **Today focal-card "completed" branch never wins over "in-progress".** `home_page.dart:185-203` checks `inProgress` first, then `completed`, then `planned`. If the user has both an inProgress AND a completed session today (rare but possible — completed one workout, started another), the inProgress card shows and the completed work is invisible. `extraSessionCount` is also misleading: it only counts completed sessions, not the in-progress one.
3. **The "Rest day — log your journal or start something fresh." copy contradicts the CTA.** `home_page.dart:450-456` says "Rest day" but the CTA reads "Start Session" and routes to `Routes.sessionStandalone`. If the user actually wanted to rest, the screen has no "log a journal" affordance — just a session-creation button.
4. **Set rows persist `TextEditingController`s by `setNum`, but block keys aren't.** `session_view.dart:640-666` keeps `Map<int, TextEditingController>` keyed only on the set number. If the same `_ExerciseBlockBodyState` ever re-rendered for a different exercise (it doesn't today — each block has its own State), the controllers would carry over. **No widget key on `_ExerciseBlockBody`** to guard against this.
5. **Progression suggestions are computed once and cached on the State.** `session_summary_page.dart:66-99` early-returns if `_suggestions.isNotEmpty`. If `exercisesAsync` is still loading on first build but resolves on the second, `_computeSuggestions` runs then. **But if the user navigates away mid-load, the suggestions are never written anywhere persistent.** The dismissed set is also local State only.
6. **Wellness inputs to progression are hardcoded `4.0`.** `session_summary_page.dart:83-85` passes literal `avgSleepQuality: 4.0, pulseScore: 4.0, avgStomachFeeling: 4.0` with a TODO-style comment "Phase 1: use default wellness values" (`:77-78`). **Today's progression suggestions are effectively decided by RPE + completed sets only.** A user who logs awful sleep won't see deload suggestions.
7. **The complete-workout bottom sheet returns `null` when dismissed by drag.** `session_view.dart:303` awaits `showModalBottomSheet<bool>`. Dismissing by tapping outside or dragging down returns `null`, which the `if (confirmed != true) return;` check (`:313`) treats as cancel. Tap outside the sheet = silently abort. No confirm-on-dismiss prompt.
8. **No-session path is dead-end on error.** `session_view.dart:58-62` shows `'No active session'` with no Scaffold AppBar, no back button, no exit. If `activeSessionProvider` somehow resolves to `null` mid-session (e.g., the user discards in a different tab), they're stuck on a centered text with the system back gesture as the only escape. iOS users without a back gesture are stuck.
9. **Exit dialog discards even if reps were typed but no set was tapped.** `_confirmExit` calls `discard()` (`:197`). The local `TextEditingController` text in `_repsControllers`/`_weightControllers` is gone — only `actualSets` (set on tap) is persisted. Easy to lose 5 minutes of typing.
10. **Session-not-yet-in-history fallback renders an empty summary with no spinner.** `session_summary_page.dart:118-121` falls through to `_buildSummaryScaffold(context, null, exercises)` when the session ID isn't yet in `sessionHistoryProvider`. The user sees the celebration animation, "Workout Complete!", and stats reading "0 · 0 · —". **No visual cue this is loading vs final.**
11. **Streak chip is invisible at exactly streak=1?** It's not — `home_page.dart:108` shows it when `streak > 0`. But the copy "1 day" is grammatically right per the ternary `${streak == 1 ? '' : 's'}` (`:146`). Worth noting because off-by-one bugs around streak display are easy.

---

## 4. Animation triggers

| Screen | Trigger | Animation |
|---|---|---|
| Home | Mount of `_TodayFocalCard` (state change) | Surface + border `AnimatedContainer` (`WayMotion.standard`) — colors crossfade between idle, in-progress (terracotta tint), completed (sage tint). |
| Home | Today's weekday match | Week strip circle stays terracotta-ringed; on completion → fades to sage filled (`AnimatedContainer`, standard). |
| Home | Heat-map cell state change | Per-cell `AnimatedContainer` standard transition. |
| Active Session | Mount | `_headerController` (`WayMotion.settled`) fades the focus title + date in. |
| Active Session | Block enters viewport | `_ExerciseBlockCard._slideController` runs after `60ms × index` delay (`session_view.dart:452-457`) — staggered slide-in `Offset(0.05, 0) → Offset.zero`. |
| Active Session | Block becomes current | `didUpdateWidget` flips `_expanded = true` (`:461-466`). |
| Active Session | Set tap | Circle's `AnimatedContainer` standard color/border crossfade. |
| Active Session | RPE change | `AnimatedPositioned.left` on the terracotta dot (`WayMotion.standard`). |
| Active Session | Progress chip update | `AnimatedContainer` (standard) on the chip's bg color (transitions to sage on `complete == true`). |
| Summary | Mount | `_celebController` (settled + standard) drives `_celebScale` (0–60% interval) and `_fadeIn` (30–100%). The check-mark `_CheckPainter` paints the tick line in two phases on the same controller — first half draws p1→p2, second half draws p2→p3. |
| Summary | Suggestion dismissed | No animation — card swaps to `SizedBox.shrink` instantly (`:246`). |

---

## 5. A11y notes

### Semantic labels

- **Home greeting** is a single `Text` with no semantics override. Screen readers read "Good morning, Marco." then the date. The streak chip reads as "5 days" alone — no "streak" context. **Gap:** wrap streak chip in `Semantics(label: '5-day streak')`.
- **Week strip** circles have no labels — a screen reader hears nothing for them. **Gap:** wrap each in `Semantics(label: 'Monday — completed' | 'Wednesday — today' | 'Tuesday — missed' | 'Friday — upcoming')`.
- **Heat-map cells** are bare `AnimatedContainer`s with day-number text. The day number reads, but completion status doesn't. **Gap:** add `Semantics(label: '$day, completed' | '$day, planned' | '$day')`.
- **Set circles** are `GestureDetector`s with no `Semantics`. The number inside is read, but tap behavior is opaque. **Gap:** `Semantics(button: true, selected: isCompleted, label: 'Set $setNumber')`.
- **RPE slider** uses 10 invisible `Expanded` GestureDetectors over a gradient; nothing to read. The label below ("RPE 7 / 10") is the only signal. **Gap:** wrap each hit zone in `Semantics(button: true, label: 'Effort $rpe')` and the whole row in `Semantics(slider: true, value: '$currentRpe of 10')`.
- **Sage check painter** on summary has no label — the celebration is silent for screen readers. **Gap:** wrap in `Semantics(label: 'Workout complete')`.

### Contrast

- Summary stats `Fraunces` value text uses default theme `displayMedium` size — fine.
- `AppColors.warning` (#…) on `AppColors.warning.withValues(alpha: 0.12)` background for the missed-yesterday banner (`home_page.dart:417-432`) — text-on-tint contrast is borderline at the 11px label size. **Worth measuring.**
- Set-circle "completed" state icon (white check on sage) passes AA easily.
- "Rest now — tomorrow keeps the streak." (Stone on warm linen) is fine.

### Tap targets

- **Set circles are 30×30 px** (`session_view.dart:757-758`). **Below 48 px minimum.** This is the primary interaction in a workout — easy to miss-tap with sweaty hands. The padding-only Row gives the row about 50px tall total, but the actual hit area is just the circle.
- **RPE slider hit zones** are `AppSpacing.minTapTarget / 2` = 24px tall (`:867`) divided into 10 horizontal strips (each ~36px wide on a 360px screen). Both axes are under 48px. **Major a11y gap** — RPE setting is hard to hit precisely.
- **Quick-log pills** are `OutlinedButton.icon` with `minimumSize: Size(0, 40)` (`home_page.dart:1015`) — 40 px tall, **under 48 px**.
- Home `_GoalMiniCard` and `_LogPill` are sized for density; a 1-handed phone use audit would flag both.
- Summary "Back to home" CTA is `Size.fromHeight(56)` — passes.

### Focus & keyboard

- The complete-workout sheet's TextField has a tap-outside-to-dismiss path that returns `null` to `showModalBottomSheet` (see Edge case #7). For a keyboard user there's no way to invoke "Cancel" via Esc — only via the explicit Cancel button.
- Active-session's CustomScrollView doesn't trap focus; tabbing out of a reps field jumps to the next set's reps. Acceptable but worth confirming.
