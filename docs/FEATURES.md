# Way2Move — Feature Status

> **Last updated:** 2026-04-21
> **Test coverage snapshot:** 674+ tests passing (582 Phase 1 + 92 Phase 2). Phase 3 Blocks 0/2/3/4 and Phase 4 Blocks 0-1 added ~80 more tests on 2026-03-31 — refresh count on next full `flutter test` + `cd backend/functions && npm test` run.
>
> Companion docs:
> - `RELEASE_PLAN.md` — v1.0 scope, flag decisions, unflag order
> - `FEATURE_FLAGS_INVENTORY.md` — flag catalog (⚠ flags not yet wired in code)
> - `phases/phase0X-tasks.md` — authoritative task-level completion per block
> - Canonical project status: `/projects/my-projects/marco-cns/projects/way2move/STATUS.md`

---

## Completed Features

### Phase 1 — Training + Body Awareness MVP

#### 1. Authentication (Block 1)
**What it is:** Email/password and social sign-in (Google, Apple) via Firebase Auth. New users automatically get a Firestore profile document created by a Cloud Function trigger.

**How to test in UI:**
- **LoginPage** (`/auth/login`): Enter email + password, tap "Sign In". Try Google/Apple buttons. Tap "Create account" link to navigate to sign-up.
- **SignUpPage** (`/auth/signup`): Fill name, email, password, confirm password. Submit creates account and navigates to home.
- **Auth guard**: Try accessing any protected route while logged out — you should be redirected to `/auth/login`.

---

#### 2. Exercise Library (Blocks 2–3)
**What it is:** A searchable, filterable library of 60+ curated exercises covering DNS, PRI, mobility, stability, strength, breathing, and hypermobility. Users can browse, search, filter by tags, view details, and add custom exercises.

**How to test in UI:**
- **ExerciseListPage** (`/exercises`, bottom nav "Exercises" tab): Scroll through exercise cards. Use the search field at top. Toggle filter chips (sport/type/region/equipment) — list narrows in real time.
- **ExerciseDetailPage** (tap any exercise card): View title, description, video URL link, difficulty badge, tags, coaching cues, progressions/regressions.
- **AddExerciseDialog** (tap "+" FAB on list page): Fill name, description, video URL, select tags. Save adds the exercise to the list.

---

#### 3. Assessment System (Block 4)
**What it is:** A questionnaire-based movement assessment that detects compensation patterns (forward head posture, rounded shoulders, anterior pelvic tilt, etc.) based on user answers about occupation, sitting habits, pain areas, and activity. Includes a weekly pulse check (energy, soreness, motivation, sleep sliders).

**How to test in UI:**
- **InitialAssessmentFlow** (`/assessment`, full-screen):
  - Step 0 — Intro: "Movement Assessment" title, "Start" button
  - Step 1 — Occupation: choose "Desk Job", "Physically Active", or "Mixed"
  - Step 2 — Sitting Hours: choose a range
  - Step 3 — Pain Areas: multi-select (neck, lower back, knees, ankles, shoulders, hips)
  - Step 4 — Running: "Yes" / "No"
  - Step 5 — Processing animation (~1.8s)
  - Step 6 — Results: score ring, detected patterns, "Build My Program" / "View Later" buttons
- **AssessmentHistoryPage** (`/assessment/history`): Pull-to-refresh, cards with date + "Latest" badge + score + pattern chips.
- **WeeklyPulseDialog** (call `showWeeklyPulseDialog(context)`): 4 sliders (1–5) with emoji labels, Save button.

---

#### 4. Programs (Block 5)
**What it is:** Users create or auto-generate corrective training programs. Programs define a weekly template (which days to train, which exercises per day). Auto-generation maps detected compensations to specific exercises from the seed library.

**How to test in UI:**
- **ProgramDetailPage** (`/programs`, inside shell): Shows active program with gradient header (name, goal, duration, days/week), weekly schedule with day circles and exercise cards. "Deactivate Program" button with confirmation dialog. Empty state if no active program.
- **ProgramBuilderPage** (`/programs/new`, full-screen): Form with name, goal, duration chips (4w–16w). WeekTemplateEditor: tap day circles to toggle training/rest. Save button. When opened via `/programs/new?fromAssessment=<id>`, fields auto-fill from assessment results.

---

#### 5. Session Tracking (Block 6)
**What it is:** Log training sessions with exercise blocks, track sets/reps/weight per exercise, rate RPE (1–10), add notes. Sessions can be generated from the active program's weekly template or created standalone.

**How to test in UI:**
- **SessionView** (`/session/active`, full-screen): SliverAppBar with focus + date + progress chip. Exercise block cards expand to show set rows (reps/weight inputs, checkmark per set, RPE selector). "Complete Workout" button → notes sheet → saves → navigates to summary.
- **SessionSummaryPage** (`/session/summary/:id`): Celebration animation, "Workout Complete!" headline, stats row (exercises/sets/duration), per-exercise planned→actual comparison.
- **CreateStandaloneSessionPage** (`/session/standalone`): Search and add exercises, set planned sets/reps, "Start Workout" button.

---

#### 6. User Profile & Onboarding (Block 7)
**What it is:** Multi-step onboarding flow collecting user info (age, height, weight, training goal, activity level, sports, equipment). Profile editing page for updating all fields.

**How to test in UI:**
- **OnboardingFlow** (`/onboarding`, full-screen): 6 steps — Welcome → Basic Info → Goal → Activity Level → Sports → Equipment. Back button on all steps except Welcome. Skip button top-right. Progress bar animates between steps.
- **ProfileEditPage** (`/profile/edit`): Sections for basic info, training goal, activity level, training days/week, sports, equipment. Save button shows snackbar on success.

---

#### 7. Compensation Profile (Block 8)
**What it is:** Body map visualization of active movement compensations. Each compensation has severity, status tracking (active → improving → resolved), history, and links to related goals and exercises. Journal entries are parsed for compensation-related mentions.

**How to test in UI:**
- **CompensationProfilePage** (`/compensations`): Interactive body map with tap regions showing active compensations color-coded by severity.
- **CompensationDetailPage** (tap a compensation): History timeline, related goals (red chips), related exercises (green chips), severity progression.

---

#### 8. Goal System (Block 9)
**What it is:** Set and track movement/fitness goals. Goals can be auto-suggested from assessment compensations or created manually. Goals link to compensations and exercises, with progress tracked via a metric/target system.

**How to test in UI:**
- **GoalListPage** (`/goals`, bottom nav "Goals" tab): Goal cards with name, category chip, progress bar, current/target values. FAB "+" opens AddGoalDialog. Empty state prompts assessment.
- **GoalDetailPage** (`/goals/:goalId`): Animated progress bar, current/target, description, linked compensation and exercise chips. "Mark as Achieved" button (green). Achieved goals show achievement date.
- **AddGoalDialog** (modal from FAB): Name, description, category chips, metric/target/unit fields.
- **GoalSetupPage** (`/goals/setup`, after assessment): Suggested goals with animated entrance, tap to select/deselect, "Add X goals" button.

---

#### 9. Journaling System — Voice-First (Blocks 10–11)
**What it is:** Voice-first journaling with on-device speech-to-text transcription and audio recording. Supports pre/post-session journals. Auto-creates Session and Meal documents from parsed text. Users review auto-created entities before saving.

> **Phase 3 upgrade (shipped):** Cloud STT (Whisper) replaces on-device STT when `feature_cloud_stt` is on — see feature #22.

**How to test in UI:**
- **JournalEntryPage** (`/journal/entry`): Tap mic button → turns red with pulse animation, "Listening..." label, live transcription preview. Tap again to stop → "Audio recorded" indicator. Text fallback available. Mood/energy selectors. Save uploads audio to Firebase Storage.
- **JournalHistoryPage**: Chronological list with type filters.
- **ReviewAutoCreatedPage**: Shows parsed training activities and meals from journal text. Edit/confirm/delete each entity before saving.

---

#### 10. Nutrition MVP (Block 12)
**What it is:** Basic meal tracking with meal type selection, text descriptions, stomach feeling rating (1–5 emoji scale), and optional notes. 14-day stomach pattern trends show correlations between meal types and gut feeling.

> **Phase 3 upgrade (shipped):** Full macro tracking, Open Food Facts food DB search, macro targets, and nutrition dashboard — see features #23–25. The MVP remains the fallback when `feature_nutrition` is off.

**How to test in UI:**
- **DailyNutritionPage** (`/nutrition`): Date navigator (← today →), summary card (meal count + avg stomach feeling), FAB → MealLogPage, patterns icon → StomachPatternPage.
- **MealLogPage** (`/nutrition/log`): Meal type chips (Breakfast/Lunch/Dinner/Snack/Drink), description field, 5-emoji stomach feeling selector (😣😕😐🙂😊), optional notes. Save disabled until required fields filled.
- **DailyMealsView**: Sections per meal type, meal cards show description + emoji + time, swipe left to delete.
- **StomachPatternPage** (`/nutrition/patterns`): Colored progress bars per meal type with average scores over 14 days.

---

#### 11. Sleep Logging (Block 13)
**What it is:** Log bed time, wake time, sleep quality (1–5 scale), and optional notes. View history as a bar chart (7-day and 30-day views) with color-coded quality indicators.

**How to test in UI:**
- **SleepLogEntryPage** (`/sleep`): Bed time + wake time pickers, calculated duration, quality chips (Poor/Fair/Okay/Good/Excellent), optional notes. Save disabled until quality selected.
- **SleepHistoryPage** (`/sleep/history`): Chart at top (7-day/30-day toggle, color-coded bars), list of past logs below. Pull to refresh.

---

#### 12. Progress Photos & Weight (Block 14)
**What it is:** Guided progress photo capture (front, side left, side right, back angles) with overlay guides. Photos upload to Firebase Storage. Side-by-side before/after comparison view. Weight logging with trend line chart.

**How to test in UI:**
- **PhotoCapturePage** (`/progress/capture`): Guided capture with overlay guides for each angle. Photos upload automatically.
- **PhotoTimelinePage**: Chronological gallery of progress photos. Tap to compare.
- **PhotoComparisonView**: Side-by-side before/after with date labels.
- **WeightLogEntry**: Quick weight input.
- **WeightTrendChart**: Line chart with trend line over time.

---

#### 13. Auto-Progression (Block 15)
**What it is:** Automatic training progression suggestions based on exercise completion history, sleep quality, weekly pulse scores, and gut trends. Suggests increasing reps, load (+2.5kg), advancing to a harder variation, or deloading. Appears after completing a session.

**How to test in UI:**
- **ProgressionSuggestionCard** (shown on SessionSummaryPage): Blue/orange gradient card for exercises with suggestions. Accept/Dismiss buttons with animated entrance. Progression types: increase reps, increase load, advance variation. Deload when sleep/pulse/gut scores are low.
- **ProgressionSettingsPage** (`/progression/settings`): Configure global thresholds via sliders (completion count, sleep quality, pulse score, stomach feeling). About section explaining the system.

---

#### 14. Calendar (Block 16)
**What it is:** Month and week view calendar showing scheduled/completed/skipped sessions with color-coded dots. Tap a day to view sessions or create a new one.

**How to test in UI:**
- **CalendarPage** (`/calendar`, bottom nav): Month/Week toggle. Month view: 7-column grid with day numbers and colored dots (green=completed, blue=planned, gray=skipped, purple=recovery). Week view: horizontal strip with icons. Navigate months with chevron arrows.
- **DaySessionsSheet** (tap any day): Bottom sheet with date header, session cards (focus + status + duration). "Start New Session" button. Empty state message.

---

#### 15. Dashboard & Navigation (Block 17)
**What it is:** Home dashboard with today's session card, weekly overview strip, monthly heat map, active goals, quick actions, and "Track Today" shortcuts. Bottom navigation with 5 tabs (Home, Exercises, Nutrition, Goals, Profile). Profile page with stats and feature navigation.

**How to test in UI:**
- **HomePage** (`/`, Home tab):
  - Greeting header with name + date + streak badge (fire icon)
  - Today's session card (planned/completed/in-progress/no-session states)
  - Missed-day motivation banner: "Back on track — every session counts."
  - Weekly strip: 7 circles (M–S), green with checkmark for completed days
  - Monthly heat map: current month grid with green ✓ for completed days, session count
  - Active Goals: up to 3 mini-cards with progress bars
  - **Recovery Banner** (when `feature_recovery` on) — see feature #27
  - Quick Actions (2x2): New Session, Assessment, My Program, Exercises
  - Track Today (2x2): Journal, Log Meal, Log Sleep, Progress Photo
- **ProfilePage** (`/profile`, Profile tab): Avatar initial + name, email, training goal badge. Stats row (streak/sessions/goals). Navigation tiles to all features. Sign Out button.

---

### Phase 2 — AI Movement Assessment

#### 16. ML Pose Estimation (Block 0)
**What it is:** On-device pose estimation using `flutter_pose_detection` (MediaPipe BlazePose). Extracts 33 body landmarks per frame with 3D coordinates. Runs entirely on-device (GPU ~3ms, NPU ~13ms per frame) — no server calls, works offline.

**How to test in UI:** No direct UI. This is an infrastructure service used by the video analysis pipeline. Verify by running unit tests (32 tests).

---

#### 17. Video Analysis Pipeline (Block 1)
**What it is:** Record 5 screening movements (overhead squat, single-leg stance, forward bend, shoulder raise, walking gait) via camera. Videos are compressed, uploaded to Firebase Storage, analyzed on-device via pose estimation, and results stored in Firestore.

**How to test in UI:**
- **MovementRecordingPage**: Camera preview, progress dots (5 movements), movement name + instructions. Tap record → 3-second countdown → recording (red pulsing button + "REC" badge). Tap stop → review state (green checkmark, Retake/Next buttons). After last movement → analysis overlay with progress bar. Screen pops on completion.
- Navigate via `context.push(Routes.movementRecording, extra: {'assessmentId': '<id>', 'userId': '<uid>'})`.

---

#### 18. Compensation Detection from Video (Block 2)
**What it is:** Analyzes pose landmark data to detect movement compensations (knee valgus, limited dorsiflexion, weak glute med, rounded shoulders, forward head posture). Scores severity by frame ratio (mild <30%, moderate 30–60%, significant >60%). Merges AI detection with questionnaire results.

**How to test in UI:** No direct UI — domain-layer only. Results surface in Block 3's recommendation page. Verify via unit tests (43 tests).

---

#### 19. AI Program Recommendations (Block 3)
**What it is:** Rule-based engine that generates a personalized corrective program from compensation detection results. Prioritizes by severity, selects exercises from the library, filters by available equipment, distributes across training days. Users review and edit the program before accepting.

**How to test in UI:**
- **AIRecommendationReviewPage** (`/assessment/recommendation`):
  - Movement Analysis section: compensation cards sorted by severity (red/orange/green), each showing pattern name, severity badge, % of frames
  - Weekly Schedule: 7 day cards, training days show exercises, rest days show "Rest"
  - Tap `3×12` badge on any exercise → dialog to edit sets/reps
  - Tap × to remove an exercise
  - "Accept & Create Program" button → saves program to Firestore, navigates home
- Navigate via `context.push(Routes.aiRecommendation, extra: {'report': compensationReport, 'profile': userProfile})`.

---

#### 20. Before/After Comparison UI (Block 4) — *shipped 2026-03-31*
**What it is:** Side-by-side video playback with synchronized scrubbing for initial vs re-assessment movements. Pose landmark overlay via `CustomPainter` draws joints color-coded by quality (green=good, amber=borderline, red=compensation) with lines between connected joints. `MovementScoreChart` (radar/grouped-bar) compares scores across movements. Summary cards highlight improvements like "Knee valgus improved from significant → mild."

**How to test in UI:**
- **ReAssessmentComparisonPage** (triggered after completing a re-assessment): Two video panes scrub in lockstep. Joint overlays update frame-by-frame with color coding. Radar chart shows initial-vs-current scores. Summary cards list compensation changes with arrows.

---

#### 21. Re-Assessment Scheduling & Notifications (Block 5) — *shipped 2026-03-31*
**What it is:** `ReAssessmentSchedule` entity tracks next assessment date (default 4 weeks, configurable 4/6/8/12). Cloud Function trigger `onAssessmentComplete` writes the next date to the user doc. FCM push notifications fire 3 days before and on the due date ("Time to re-assess — see how far you've come"). Re-assessment flow shows previous score per movement for context.

> **Release note:** FCM depends on the `feature_notifications` flag and production FCM setup (Phase 6). Keep scheduling on, notifications off until Phase 6.

**How to test in UI:**
- **Interval setting**: after completing an assessment, go to settings to change re-assessment interval (4/6/8/12 weeks).
- **AssessmentTimelinePage**: chronological list of past assessments with trend arrows per compensation pattern (improving/worsening/stable).
- **Notification fire**: scheduled in FCM for `nextAssessmentDate − 3 days` and `nextAssessmentDate`.

---

### Phase 3 — Advanced Nutrition

#### 22. Cloud Speech-to-Text Upgrade (Block 0) — *shipped 2026-03-31*
**What it is:** OpenAI Whisper API called via a Firebase Callable Function (`transcribeAudio`) — keeps API keys server-side. Replaces on-device `speech_to_text` across journal, session logging, and meal logging. Device STT kept as offline fallback when the cloud call fails or the user is offline. Gated by `feature_cloud_stt` Remote Config flag.

**How to test in UI:** No new screens — behavior change only.
- Record any voice note (Journal entry, meal log, session notes) with network available → transcription accuracy noticeably improves on food names, proper nouns, and longer phrases.
- Turn off network before recording → device STT fallback kicks in; transcription still works but reverts to previous quality.
- **A/B comparison task remains open** (`[ ]` in phase03 Block 0) — accuracy metrics not yet captured.

---

#### 23. Full Meal Tracking with Macros (Block 2) — *shipped 2026-03-31*
**What it is:** `Meal` entity upgraded with `calories`, `protein`, `carbs`, `fat`, and `foodItems: List<FoodItem>`. New `FoodItem` entity (name, portion, macros). `FoodDatabaseService` queries **Open Food Facts** (free, no API key) for food search. `MealEntryPage` redesigned: search bar at top, tap to add items, each shows macros + editable portion. `DailyMealsView` shows running macro totals per day. Stomach feeling carried forward from MVP. Backwards-compatible with pre-upgrade meals ("No items tracked" shown gracefully).

**Companion feature (commit `9ed91d4`):** Nutrition tab added to bottom navigation; users can create custom foods when the Open Food Facts result is missing or inaccurate.

**How to test in UI:**
- **Bottom nav → Nutrition**: reaches nutrition hub directly (no longer buried under Profile).
- **MealLogPage** (`/nutrition/log`): search field at top → type a food → list of hits from Open Food Facts → tap to add. Each added item shows macros and editable portion (grams). Running totals at bottom. Stomach-feeling selector + notes still present.
- **Custom food flow**: when no match is found, "Create custom food" button opens an entry form (name, serving size, calories, protein, carbs, fat).
- **DailyMealsView**: meals grouped by type; per-day totals row shows kcal + protein + carbs + fat.
- **Backwards compat**: open a meal logged before 2026-03-31 → displays description + stomach feeling; food items section shows "No items tracked."

---

#### 24. Macro Targets (Block 3) — *shipped 2026-03-31*
**What it is:** Daily calorie target computed from `UserProfile` via Mifflin-St Jeor BMR × activity multiplier. Macro split presets: Fat loss (40/30/30 P/C/F), Maintenance (30/40/30), Muscle gain (30/50/20). Training days bump calories +10–15%; rest days drop −10%. `NutritionTargetSettingsPage` lets users view/edit targets and pick a preset. Firestore collection: `nutritionTargets/{userId}` (single doc per user).

**How to test in UI:**
- **NutritionTargetSettingsPage**: view calculated TDEE for today (training vs rest), select a preset goal chip (Fat Loss / Maintenance / Muscle Gain) → macro split updates → save. Override any value manually.
- **Verify training vs rest day**: log a session for today → reload page → daily target shows the training-day adjusted calories.
- **Verify unit tests**: calculation formulas have unit tests for BMR, activity multipliers, and training/rest adjustments.

---

#### 25. Daily/Weekly Nutrition Dashboard (Block 4) — *shipped 2026-03-31*
**What it is:** **Upgraded DailyNutritionPage** with a richer summary card (calorie progress bar, 3 animated macro ring charts via `fl_chart` PieChart, streak fire badge, stomach-feeling emoji). **New NutritionDashboardPage** at `/nutrition/dashboard` with four sections: weekly calorie bar chart with target line, consistency stats (days logged + streak), stomach-food correlation list (which foods correlate with poor stomach ratings), and meal history quick-add. Reusable widgets: `MacroRingChart`, `CalorieProgressBar`, `WeeklyNutritionChart`, `StomachCorrelationList`, `MealHistoryQuickAdd`. Riverpod providers: `weeklyNutritionProvider`, `stomachCorrelationsProvider`, `loggingStreakProvider`. Gated by `feature_nutrition_dashboard`.

**How to test in UI:**
- **DailyNutritionPage** (`/nutrition`): summary card at top shows calorie bar + 3 macro rings (protein/carbs/fat vs target) + streak flame with day count + today's avg stomach emoji.
- **NutritionDashboardPage** (`/nutrition/dashboard`): weekly bar chart with dashed target line; consistency card shows "X/7 days logged" + current streak; stomach correlation list ranks foods by average stomach score; meal history shows recent meals with a "+" to re-add quickly.
- **13 unit tests** for the three use cases + **8 widget tests** for dashboard components.

---

### Phase 4 — Smart Recovery (Phase 4a shipped)

#### 26. Recovery Score Calculation (Block 0) — *shipped 2026-03-31*
**What it is:** `RecoveryScore` entity with `RecoveryScoreComponents` (sleep, training load, weekly pulse, gut feeling) and `RecoveryZone` enum (green/yellow/red). `RecoveryService` (pure Dart, static) computes daily score via v1 formula: **sleep 30% + training load 40% + weekly pulse 20% + gut feeling 10%**.
- **Sleep**: avg quality of last 3 sleep sessions (1–5 → 0–100%)
- **Training load**: last 3 days vs 7-day avg — score improves when load is decreasing
- **Weekly pulse**: avg of energy + (100 − soreness) + motivation + sleep from `WeeklyPulseEntry`
- **Gut feeling**: avg stomach feeling from nutrition entries

`calculateNightlyRecoveryScores` Cloud Function runs at 2 AM daily, writes to `recoveryScores/{userId}/daily/{YYYY-MM-DD}` and updates `users/{userId}.todayRecoveryScore`. Gated by `feature_recovery`.

> **Phase 4b upgrade pending:** add nutrition-adherence component and rebalance weights now that Phase 3 Block 3 is shipped.

**How to test in UI:** No new screen at this block — score surfaces via Block 1's `RecoveryBanner`.
- **Verify via Firestore**: after nightly Cloud Function run, check `users/{uid}.todayRecoveryScore` populated and `recoveryScores/{uid}/daily/` has today's document.
- **25 Flutter unit tests + 20 TypeScript unit tests** cover formula edge cases (missing inputs, boundary values).

---

#### 27. Training Adjustment Recommendations (Block 1) — *shipped 2026-03-31*
**What it is:** Score zones — green (75–100), yellow (50–74), red (0–49) — mapped to training modifications. `GenerateRecoveryRecommendation` use case returns a headline + detail + `SuggestedSessionType` (full session, reduced volume, mobility only, rest). `RecoveryBanner` widget sits on the home dashboard with an animated score counter + zone color chip; tap → `RecoveryDetailPage` with animated ring, 4-component breakdown (animated bars), recommendation card, and 7-day sparkline. Integration with auto-progression (recovery overrides progression) is **deferred** — to be revisited after wearables.

**How to test in UI:**
- **HomePage** → **RecoveryBanner** near the top: animated score counter, zone-colored chip, recommendation headline. Tap → slide-in transition to detail page.
- **RecoveryDetailPage** (`/recovery`):
  - Animated ring fills to today's score
  - 4 component bars (sleep / training load / weekly pulse / gut) animate to their contribution values
  - Recommendation card explains the zone + suggested session type
  - 7-day sparkline shows trend
- **Providers**: `todayRecoveryScoreProvider`, `recoveryTrendProvider`, `recoveryRecommendationProvider`.

---

## In Progress

### Brand v1 Dark-Mode Revamp (commit `264889c`, started 2026-04-21)
Token system (colors, typography, spacing, motion) shipped. Logo redesigned. **5 of 20 planned screens** migrated to the new design system. Remaining 15 screens must migrate before v1.0 for visual consistency.

**How to verify:** open migrated screens side-by-side with un-migrated ones and confirm: consistent corner radius, new typography scale, dark-mode surface colors, new primary/accent palette.

---

## Pending Features

### Phase 3 — Advanced Nutrition (remaining)

#### Photo Food Recognition (Block 1) — *⛔ deferred (scope cut)*
Camera-based meal logging via AI food recognition API. Recognize food items, estimate portions and macros. Confirm/edit/reject recognized items. **Explicitly not shipping in this cycle.**

#### Meal Planning (Block 5)
Create meal plans for upcoming days/weeks. Copy meals, generate grocery lists, save/reuse weekly templates.

---

### Phase 4 — Smart Recovery (Phase 4b — requires Phase 3 data)

#### Recovery Score v2 Upgrade
Add nutrition-adherence component to `RecoveryService` (actual macros vs targets from feature #24) and rebalance weights. Unblocked now that Phase 3 Block 3 ships.

#### Wearable Integration (Block 2)
Apple Watch (HealthKit) and Garmin (Connect API) integration for sleep, HRV, resting HR, activity, and stress data. Feed into recovery score calculation. `WearableConnectionPage` at `/settings/wearables`.

#### Recovery Trends Dashboard (Block 3)
Recovery score trend charts (7/30/90 days). Correlation overlay with training volume and sleep. Weekly recovery summary with best/worst days and key factors. Export as CSV or image.

---

### Phase 5 — Social & Coaching — *mostly deferred*

#### Coach Role & Permissions (Block 0) — *⛔ deferred*
Coach-athlete relationships with invite flow. Coach dashboard with connected athletes and quick stats. Requires `frontend/web/` scaffold (not yet created).

#### Coach Creates Programs (Block 1) — *⛔ deferred*
Coach views athlete assessments, creates/edits programs on their behalf. Athlete notifications and accept/modify flow.

#### Sharing Workouts & Programs (Block 2) — *⛔ deferred*
Share sessions as cards, share program templates via link, deep link handling, privacy controls.

#### Community Exercise Library (Block 3) — *⛔ deferred*
User-submitted exercises with moderation queue. Community badge, upvote/save to personal library.

#### Progress Sharing (Block 4) — *only active Phase 5 item*
Generate and share progress reports (assessment improvements, consistency, program completion). Coach progress timeline. Opt-in leaderboards.

---

### Phase 6 — Deployment & Distribution

> **Blocks v1.0 launch.** All of the following must land before first public release.

#### App Store & Play Accounts (Block 0)
Apple Developer and Google Play accounts, app entries, signing keys.

#### App Identity (Block 1)
App icon, adaptive icon, splash screen, bundle ID, display name.

#### Production Firebase (Block 2)
Separate production Firebase project, deploy rules/functions/seeds, Crashlytics, environment switching.

#### Privacy Policy & ToS (Block 3)
Draft and host privacy policy and terms of service. GDPR compliance (data export, account deletion).

#### Store Listings (Block 4)
App Store and Google Play descriptions, screenshots, feature graphic, ASO keywords.

#### Test Builds (Block 5) — *partially in progress*
Codemagic (iOS/TestFlight) pipeline scaffolded — see `.claude/skills/ios-staging-codemagic/SKILL.md`. GitHub Actions (Android) pending. Internal testing tracks + Sentry monitoring pending.

#### Freemium Model (Block 6)
Define free/premium tiers, RevenueCat integration, paywall UI, subscription management. **Post-v1.0.**

#### Public Launch (Block 7)
App Store and Google Play submissions, review handling, phased rollout, analytics.
