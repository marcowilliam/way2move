# Way2Move — Feature Status

> **Last updated:** 2026-03-30
> **Total tests passing:** 582 (Phase 1) + 92 (Phase 2) = 674

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

**How to test in UI:**
- **JournalEntryPage** (`/journal/entry`): Tap mic button → turns red with pulse animation, "Listening..." label, live transcription preview. Tap again to stop → "Audio recorded" indicator. Text fallback available. Mood/energy selectors. Save uploads audio to Firebase Storage.
- **JournalHistoryPage**: Chronological list with type filters.
- **ReviewAutoCreatedPage**: Shows parsed training activities and meals from journal text. Edit/confirm/delete each entity before saving.

---

#### 10. Nutrition MVP (Block 12)
**What it is:** Basic meal tracking with meal type selection, text descriptions, stomach feeling rating (1–5 emoji scale), and optional notes. 14-day stomach pattern trends show correlations between meal types and gut feeling.

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
**What it is:** Home dashboard with today's session card, weekly overview strip, monthly heat map, active goals, quick actions, and "Track Today" shortcuts. Bottom navigation with 5 tabs. Profile page with stats and feature navigation.

**How to test in UI:**
- **HomePage** (`/`, Home tab):
  - Greeting header with name + date + streak badge (fire icon)
  - Today's session card (planned/completed/in-progress/no-session states)
  - Missed-day motivation banner: "Back on track — every session counts."
  - Weekly strip: 7 circles (M–S), green with checkmark for completed days
  - Monthly heat map: current month grid with green ✓ for completed days, session count
  - Active Goals: up to 3 mini-cards with progress bars
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

## Pending Features

### Phase 2 — AI Movement Assessment (remaining)

#### Before/After Comparison UI (Block 4)
Side-by-side video playback with synchronized scrubbing. Pose landmark overlay using `CustomPainter` with color-coded joints (green=good, amber=borderline, red=compensation). Radar/bar chart comparing initial vs re-assessment scores. Compensation reduction summary cards.

#### Re-Assessment Scheduling & Notifications (Block 5)
Automatic scheduling of re-assessments (default 4 weeks, configurable). Push notifications via FCM 3 days before and on due date. Re-assessment flow showing previous scores for comparison. Assessment timeline page with trend arrows per compensation.

---

### Phase 3 — Advanced Nutrition

#### Cloud Speech-to-Text Upgrade (Block 0)
Replace on-device STT with cloud API (Google Cloud Speech-to-Text, Whisper, or Deepgram) for better accuracy across all voice features. Device STT kept as offline fallback.

#### Photo Food Recognition (Block 1) — *deferred*
Camera-based meal logging via AI food recognition API. Recognize food items, estimate portions and macros. Confirm/edit/reject recognized items.

#### Full Meal Tracking with Macros (Block 2)
Upgrade meals with calories, protein, carbs, fat, and food items array. Food database search. Enhanced meal entry and daily views with running macro totals.

#### Macro Targets (Block 3)
Daily calorie and macro targets calculated from user profile (age, weight, height, activity, goal). Training vs rest day adjustments. Settings page for viewing/editing targets.

#### Daily/Weekly Nutrition Dashboard (Block 4)
Macro ring charts, calorie bars, stomach feeling trends. Weekly averages, consistency scores, trend lines. Stomach-food correlation view. Meal history with quick-add. Streak tracking.

#### Meal Planning (Block 5)
Create meal plans for upcoming days/weeks. Copy meals, generate grocery lists, save/reuse weekly templates.

---

### Phase 4 — Smart Recovery

#### Recovery Score Calculation (Block 0)
Daily recovery score from sleep quality (30%), training load (40%), weekly pulse (20%), and gut feeling (10%). Calculated nightly via Cloud Function. Stored in Firestore. Phase 4b adds nutrition adherence and rebalances weights.

#### Training Adjustment Recommendations (Block 1)
Map recovery scores to green/yellow/red training zones. Auto-suggest session modifications when recovery is low. Recovery banner on home dashboard with score and recommendation.

#### Wearable Integration (Block 2)
Apple Watch (HealthKit) and Garmin (Connect API) integration for sleep, HRV, resting HR, activity, and stress data. Feed into recovery score calculation.

#### Recovery Trends Dashboard (Block 3)
Recovery score trend charts (7/30/90 days). Correlation overlay with training volume and sleep. Weekly recovery summary with best/worst days and key factors.

---

### Phase 5 — Social & Coaching — *deferred*

#### Coach Role & Permissions (Block 0)
Coach-athlete relationships with invite flow. Coach dashboard with connected athletes and quick stats.

#### Coach Creates Programs (Block 1)
Coach views athlete assessments, creates/edits programs on their behalf. Athlete notifications and accept/modify flow.

#### Sharing Workouts & Programs (Block 2)
Share sessions as cards, share program templates via link, deep link handling, privacy controls.

#### Community Exercise Library (Block 3)
User-submitted exercises with moderation queue. Community badge, upvote/save to personal library.

#### Progress Sharing (Block 4)
Generate and share progress reports (assessment improvements, consistency, program completion). Coach progress timeline. Opt-in leaderboards.

---

### Phase 6 — Deployment & Distribution

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

#### Test Builds (Block 5)
Codemagic (iOS/TestFlight), GitHub Actions (Android), internal testing tracks, Sentry monitoring.

#### Freemium Model (Block 6)
Define free/premium tiers, RevenueCat integration, paywall UI, subscription management.

#### Public Launch (Block 7)
App Store and Google Play submissions, review handling, phased rollout, analytics.
