# Phase 1 — Training + Body Awareness MVP: Implementation Checklist

> **Depends on:** nothing (first phase)
> **Can run parallel with:** Phase 6 (Deployment) from mid-phase onward
> **Blocks:** Phase 2, Phase 3, Phase 4, Phase 5

**Current test count: 131 passing** (auth: 21, exercises: 17, assessments: 21, programs: 16, sessions: 24, profile: 32)

---

## Block 0 — Project Setup ✅

- [x] Initialize Flutter project with proper package name (com.way2move.app)
- [x] Configure Firebase project (dev environment)
- [x] Set up Riverpod, GoRouter, fpdart dependencies
- [x] Set up Lefthook (pre-commit: analyze+format, pre-push: test)
- [x] Set up Nx workspace configuration
- [x] Configure Firebase emulator suite (Auth, Firestore, Functions, Storage)
- [x] Create core/ folder structure (theme, router, errors, constants, utils)

---

## Block 1 — Auth ✅

- [x] Domain: User entity (id, email, name, avatarUrl, createdAt)
- [x] Domain: AuthRepository interface (signIn, signUp, signOut, currentUser, authStateChanges)
- [x] Domain: SignIn, SignUp, SignOut use cases
- [x] Data: FirebaseAuthDatasource (email+password, Google, Apple sign-in)
- [x] Data: UserModel (fromFirestore/toFirestore/toEntity)
- [x] Data: AuthRepositoryImpl with Either error handling
- [x] Presentation: AuthNotifier provider (AsyncNotifierProvider)
- [x] Presentation: LoginPage (email + password, social sign-in buttons)
- [x] Presentation: SignUpPage (email, password, confirm password, name)
- [x] Tests: unit tests for SignIn, SignUp, SignOut use cases
- [x] Tests: widget tests for LoginPage and SignUpPage
- [x] Cloud Function: onUserCreate trigger (creates user doc in Firestore with default fields)

### UI — What to test
- **LoginPage** (`/auth/login`): email + password fields, "Sign In" button, Google/Apple sign-in buttons, "Create account" link → navigates to SignUpPage
- **SignUpPage** (`/auth/signup`): name, email, password, confirm password fields; submit creates account and navigates to home
- Auth guard: unauthenticated users are redirected to `/auth/login` on any protected route

---

## Block 2 — Exercise Library (Domain + Data) ✅

- [x] Domain: Exercise entity with full taxonomy (id, name, description, videoUrl, sportTags, patternTags, planeTags, typeTags, regionTags, equipmentTags, difficulty, progressionIds, regressionIds, cues)
- [x] Domain: ExerciseRepository interface (getExercises, getExerciseById, searchExercises, addCustomExercise)
- [x] Domain: GetExercises, SearchExercises, AddExercise use cases
- [x] Data: ExerciseModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreExerciseDatasource
- [x] Data: ExerciseRepositoryImpl with caching (seed data cached permanently after first load)
- [x] Tests: unit tests for all use cases and model serialization
- [x] Seed data: 60+ curated exercises in `exercise_seed_data.dart` (DNS, PRI, mobility, stability, strength, breathing, hypermobility)

---

## Block 3 — Exercise Library (Presentation) ✅

- [x] ExerciseListPage with filtering (by sport, type, region, equipment) and inline search field
- [x] ExerciseSearchDelegate (search by name, pattern, tags)
- [x] ExerciseDetailPage (video player, description, cues, progressions/regressions links)
- [x] AddExerciseDialog (name, description, video URL from YouTube/Instagram, tag selection)
- [x] Exercise card widget with tags display and difficulty indicator
- [x] Providers: exerciseListProvider, exerciseSearchProvider, exerciseFilterProvider
- [x] Tests: widget tests for exercise list, detail, and add dialog

### UI — What to test
- **ExerciseListPage** (`/exercises`): list of exercise cards, search field at top, filter chips below (sport/type/region/equipment); tap a card → opens detail
- **ExerciseDetailPage** (`/exercises/:id`): title, description, video URL link, difficulty badge, tags, cue list, progressions/regressions
- **AddExerciseDialog**: tap "+" button on list page; form with name, description, video URL, tags; save adds to list
- Filter chips are multi-select; list narrows in real time as filters change

---

## Block 4 — Assessment System ✅

- [x] Domain: Assessment entity (id, userId, date, answers, compensationResults, movementScores)
- [x] Domain: AssessmentRepository interface (create, getLatest, getHistory)
- [x] Domain: CreateAssessment, GetLatestAssessment, GetAssessmentHistory use cases
- [x] Tests: unit tests for CreateAssessment, GetLatestAssessment, GetAssessmentHistory
- [x] Data: AssessmentModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreAssessmentDatasource
- [x] Data: AssessmentRepositoryImpl (with provider)
- [x] Presentation: assessment_providers.dart
- [x] Presentation: InitialAssessmentFlow (multi-step: answer questions, view results)
- [x] Presentation: AssessmentHistoryPage (list past assessments with scores)
- [x] Presentation: WeeklyPulseDialog (4 sliders: energy, soreness, motivation, sleep)
- [x] Compensation detection logic (rule-based from questionnaire answers — see rules below)
- [x] Tests: widget tests for assessment flow and weekly pulse

### UI — What to test
- **InitialAssessmentFlow** (`/assessment`, full-screen outside shell):
  - Step 0 — Intro: title "Movement Assessment", "Start" button
  - Step 1 — Occupation: animated progress bar (14%), three chips: "Desk Job", "Physically Active", "Mixed"
  - Step 2 — Sitting Hours: chips "< 2 hours", "2–4 hours", "4–6 hours", "> 6 hours"
  - Step 3 — Pain Areas: multi-select toggle chips (neck, lower back, knees, ankles, shoulders, hips)
  - Step 4 — Running: "Yes" / "No" chips
  - Step 5 — Processing: rotating animation, auto-advances after ~1.8s
  - Step 6 — Results: score ring (percentage), detected pattern tiles, two CTAs:
    - "Build My Program" → navigates to `/programs/new?fromAssessment=<id>`
    - "View My Program Later" → pops back
  - Back button on all steps except Intro; progress bar animates forward/backward
- **AssessmentHistoryPage** (`/assessment/history`): pull-to-refresh, empty state, cards with date + "Latest" badge + colored score + pattern chips
- **WeeklyPulseDialog** (call `showWeeklyPulseDialog(context)`): 4 sliders (1–5), emoji labels, "Save" button shows checkmark on success then auto-dismisses

> **Compensation detection rules** (map questionnaire answers → CompensationPattern enum):
> - Desk job + neck pain → `forwardHeadPosture`, `roundedShoulders`
> - Sitting >6h/day → `anteriorPelvicTilt`, `poorCoreStability`
> - Lower back pain + sedentary → `anteriorPelvicTilt`, `excessiveLumbarLordosis`
> - Knee pain + runner → `kneeValgus`, `weakGluteMed`
> - Ankle pain → `limitedDorsiflexion`, `overPronation`
> - Shoulder pain overhead → `roundedShoulders`, `limitedThoracicRotation`
>
> Note: video recording for movement screening is deferred — questionnaire-based compensation detection only for now.

---

## Block 5 — Programs ✅

- [x] Domain: Program entity (id, userId, name, goal, durationWeeks, weekTemplate, isActive, createdAt)
- [x] Domain: WeekTemplate entity (days: Map<int, DayTemplate> 0=Mon…6=Sun)
- [x] Domain: DayTemplate entity (focus, exerciseEntries: list of ExerciseEntry with sets/reps)
- [x] Domain: ProgramRepository interface (create, getActive, update, deactivate, getHistory)
- [x] Domain: CreateProgram, GetActiveProgram, UpdateProgram, DeactivateProgram use cases
- [x] Data: ProgramModel (fromFirestore/toFirestore/toEntity) with string day-key serialization
- [x] Data: FirestoreProgramDatasource
- [x] Data: ProgramRepositoryImpl
- [x] Presentation: ProgramBuilderPage (name/goal/duration form + WeekTemplateEditor, auto-generates from assessment)
- [x] Presentation: WeekTemplateEditor widget (animated day chips + training day detail cards)
- [x] Presentation: ProgramDetailPage (gradient header, week schedule, deactivate flow)
- [x] Auto-generate starter program from assessment results (GenerateProgramFromAssessment)
- [x] Tests: unit tests for use cases and program generation logic
- [x] Tests: widget tests for program builder and detail pages

### UI — What to test
- **ProgramDetailPage** (`/programs`, inside shell):
  - No active program: centered icon + "No active program" text + suggestion copy
  - With active program: gradient header card (name, goal, "X weeks" badge, "X days/week" badge); "Weekly Schedule" with animated day circles (filled = training, muted = rest) + day detail cards (focus name, exercise count); "Deactivate Program" outlined red button → confirmation dialog
- **ProgramBuilderPage** (`/programs/new`, full-screen outside shell):
  - Form: "Program Name" field, "Goal" multi-line field, "Duration" choice chips (4w/6w/8w/12w/16w)
  - WeekTemplateEditor in edit mode: tap day circles to toggle rest ↔ training
  - "Save Program" filled button at bottom
  - When opened via `/programs/new?fromAssessment=<id>`: name, goal, and week template auto-filled from the latest assessment's compensation results (Mon/Wed/Fri training days, exercises split across 3 days)

> **Auto-generation mapping** (CompensationPattern → exercise IDs from seed data):
> - `forwardHeadPosture` → `ex_chin_tuck`, `ex_dns_prone_forearm`
> - `roundedShoulders` → `ex_wall_slide`, `ex_ys_ts`, `ex_face_pull`
> - `anteriorPelvicTilt` → `ex_90_90_breathing`, `ex_deadbug`, `ex_couch_stretch`
> - `poorCoreStability` → `ex_deadbug`, `ex_bird_dog`, `ex_plank`, `ex_rkg_plank`
> - `weakGluteMed` → `ex_clamshell`, `ex_single_leg_glute_bridge`
> - `limitedHipInternalRotation` → `ex_hip_90_90`, `ex_hip_90_90_lift`, `ex_hip_car`
> - `limitedDorsiflexion` → `ex_ankle_car`, `ex_calf_stretch`
> - `thoracicKyphosis` → `ex_thoracic_rotation`, `ex_thoracic_extension_bench`, `ex_cat_cow`

---

## Block 6 — Sessions ✅

- [x] Domain: Session entity (id, userId, programId, focus, date, status, exerciseBlocks, notes, durationMinutes)
- [x] Domain: ExerciseBlock entity (exerciseId, plannedSets, plannedReps, actualSets, rpe, notes)
- [x] Domain: SetEntry entity (setNumber, reps, weight, completed)
- [x] Domain: SessionRepository interface (createSession, updateSession, watchSessionsByDate, getSessionHistory)
- [x] Domain: CreateSession, UpdateSession, GetSessionsByDate, GetSessionHistory use cases
- [x] Domain: GenerateSessionFromProgram use case (pure, no repo — maps program DayTemplate → Session for today)
- [x] Data: SessionModel / ExerciseBlockModel / SetEntryModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreSessionDatasource
- [x] Data: SessionRepositoryImpl (with provider)
- [x] Presentation: ActiveSessionNotifier (in-progress state: record sets, RPE, block notes, complete)
- [x] Presentation: SessionView (SliverAppBar with progress chip, exercise block cards with inline set rows, RPE selector 1–10, Complete Workout bottom sheet)
- [x] Presentation: SessionSummaryPage (celebration animation, stats row, planned vs actual, notes)
- [x] Presentation: CreateStandaloneSessionPage (exercise picker with search, sets/reps per exercise, Start Workout)
- [x] Session generation from program weekly template (auto-create session for today based on active program)
- [x] Routes: /session/active, /session/standalone, /session/summary/:sessionId added to GoRouter
- [x] Tests: unit tests for CreateSession, UpdateSession, GetSessionsByDate, GetSessionHistory, GenerateSessionFromProgram (all paths)
- [x] Tests: widget tests for SessionView and SessionSummaryPage

### UI — What to test
- **SessionView** (`/session/active`, full-screen outside shell): SliverAppBar with focus title + date + "X / Y" progress chip; exercise block cards (tap to expand → set rows with reps/weight inputs, checkmark per set, RPE 1–10 selector); "Complete Workout" button enabled only after at least one set completed; sheet on complete asks for notes → saves and navigates to summary
- **SessionSummaryPage** (`/session/summary/:id`, full-screen): celebration icon animation, "Workout Complete!" headline, focus name, stats row (exercises / sets done / duration), notes card if present, per-exercise summary tiles with planned→actual set count, "Back to Home" button
- **CreateStandaloneSessionPage** (`/session/standalone`, full-screen): search field filters exercise list in real time, tap "+" to add exercise to workout, sets/reps spinners in selected list, "Start Workout (N exercises)" button opens SessionView

---

## Block 7 — User Profile & Onboarding ✅

- [x] Domain: UserProfile entity (id, name, email, avatarUrl, age, height, weight, activityLevel, trainingGoal, sportsTags, trainingDaysPerWeek, availableEquipment, injuries, onboardingComplete)
- [x] Domain: Injury entity (bodyRegion, description, severity, isActive) + enums (InjurySeverity, ActivityLevel, TrainingGoal)
- [x] Domain: ProfileRepository interface (getProfile, updateProfile, watchProfile)
- [x] Domain: GetProfile, UpdateProfile use cases
- [x] Data: UserProfileModel + InjuryModel (fromFirestore/toFirestore/toEntity, handles both camelCase and snake_case from Firestore)
- [x] Data: FirestoreProfileDatasource
- [x] Data: ProfileRepositoryImpl (with provider)
- [x] Presentation: profile_provider.dart (profileStreamProvider, profileNotifierProvider, hasCompletedOnboardingProvider)
- [x] Presentation: OnboardingFlow (6-step: welcome, basic info, goal, activity level, sports, equipment) with animated PageView + progress bar
- [x] Presentation: ProfileEditPage (edit all profile fields — name, age, height, weight, goal, activity, sports, equipment, training days)
- [x] Routes: /onboarding and /profile/edit added to GoRouter with slide transitions
- [x] Tests: unit tests for GetProfile, UpdateProfile use cases (7 tests)
- [x] Tests: model tests for UserProfileModel and InjuryModel (9 tests)
- [x] Tests: widget tests for OnboardingFlow (8 tests) and ProfileEditPage (7 tests)

### UI — What to test
- **OnboardingFlow** (`/onboarding`, full-screen outside shell):
  - Step 0 — Welcome: "Welcome to Way2Move" title, running icon, "Continue" button, "Skip" button top-right
  - Step 1 — Basic Info: "About You" title, Display Name / Age / Height / Weight text fields (all optional)
  - Step 2 — Goal: "What's your main goal?" title, 6 selection tiles (General Fitness, Strength, Mobility, Longevity, Sport-Specific, Rehab) with icons; Continue disabled until one selected
  - Step 3 — Activity Level: "How active are you currently?" title, 5 selection tiles (Sedentary to Extremely Active); training days per week selector (1-7 circles)
  - Step 4 — Sports: "What sports or activities do you do?" title, multi-select FilterChips (Running, Climbing, Swimming, etc.)
  - Step 5 — Equipment: "What equipment do you have access to?" title, multi-select FilterChips (Bodyweight, Dumbbells, Barbell, etc.); "Get Started" button
  - Back button appears on all steps except Welcome; animated progress bar updates with each step
  - Skip button (top-right) on any step → saves profile with `onboardingComplete: true` → navigates to Home
- **ProfileEditPage** (`/profile/edit`, full-screen):
  - AppBar with "Edit Profile" title and "Save" text button
  - Sections: Basic Info (name, age, height, weight), Training Goal (ChoiceChips), Activity Level (ChoiceChips), Training Days per Week (1-7 number circles), Sports & Activities (FilterChips), Available Equipment (FilterChips)
  - Save button calls updateProfile → shows "Profile updated" SnackBar → pops back

---

## Block 8 — Compensation Profile

- [ ] Domain: Compensation entity (id, userId, name, type, region, severity, status, source, relatedGoalIds, relatedExerciseIds, history, detectedAt, resolvedAt)
- [ ] Domain: CompensationRepository interface (create, update, getActive, getByRegion, getHistory, markImproving, markResolved)
- [ ] Domain: CreateCompensation, UpdateCompensation, GetActiveCompensations, MarkCompensationImproving, MarkCompensationResolved use cases
- [ ] Data: CompensationModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreCompensationDatasource
- [ ] Data: CompensationRepositoryImpl
- [ ] Presentation: CompensationProfilePage — body map showing active compensations with severity indicators
- [ ] Presentation: CompensationDetailPage — history, related goals, related exercises, severity timeline
- [ ] Presentation: CompensationBodyMap widget — interactive body outline with tap regions
- [ ] Logic: parse journal entries for compensation-related mentions (keyword-based Phase 1)
- [ ] Tests: unit tests for compensation use cases and journal parsing logic
- [ ] Tests: widget tests for compensation profile and body map

---

## Block 9 — Goal System

- [ ] Domain: Goal entity (id, userId, name, description, category, targetMetric, targetValue, currentValue, unit, sport, compensationIds, exerciseIds, source, status, achievedAt)
- [ ] Domain: GoalRepository interface (create, update, getAll, getByStatus, getByCompensation, markAchieved)
- [ ] Domain: CreateGoal, UpdateGoal, GetGoals, GetGoalsByCompensation, MarkGoalAchieved use cases
- [ ] Data: GoalModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreGoalDatasource
- [ ] Data: GoalRepositoryImpl
- [ ] Logic: generate suggested goals from compensation profile + user sport (rule-based mapping)
- [ ] Seed data: create suggested_goals.json with goal templates linked to common compensations
- [ ] Presentation: GoalSetupPage — shown after initial assessment, suggested + custom goals
- [ ] Presentation: GoalListPage — goal cards with progress bars, linked exercises and compensations
- [ ] Presentation: GoalDetailPage — target vs current, exercise path, compensation links, achievement history
- [ ] Presentation: AddGoalDialog — custom goal creation with compensation and exercise linking
- [ ] Tests: unit tests for goal use cases and suggestion logic
- [ ] Tests: widget tests for goal pages

---

## Block 10 — Journaling System (Voice-First)

- [ ] Domain: Journal entity (id, userId, date, type, content, audioUrl, mood, energyLevel, painPoints, linkedSessionId, autoCreatedEntities)
- [ ] Domain: JournalRepository interface (create, getByDate, getByType, getForSession, getHistory)
- [ ] Domain: CreateJournal, GetJournalsByDate, GetJournalsForSession use cases
- [ ] Data: JournalModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreJournalDatasource
- [ ] Data: JournalRepositoryImpl
- [ ] Voice input: integrate speech_to_text package for on-device transcription
- [ ] Voice recording: record audio to local file, upload to Firebase Storage (optional, for reference)
- [ ] Presentation: JournalEntryPage — voice-first with text fallback, mood/energy selectors, pain point body map
- [ ] Presentation: JournalHistoryPage — chronological list with type filters
- [ ] Presentation: JournalPrompts — contextual prompts for each journal type (wake-up: "How do you feel?", pre-session: "What will you focus on?", post-session: "How did it go?", bedtime: "Summarize your day")
- [ ] Link pre/post-session journals to specific sessions
- [ ] Tests: unit tests for journal use cases
- [ ] Tests: widget tests for journal entry and history pages

---

## Block 11 — Voice Daily Summary & Auto-Creation

- [ ] Entity extraction service: parse transcribed text for training activities (exercises, duration, body areas, type)
- [ ] Entity extraction service: parse transcribed text for meal descriptions (food, meal type, stomach feeling)
- [ ] Auto-create Session documents from parsed training activities (source: 'voice')
- [ ] Auto-create Meal documents from parsed food descriptions (source: 'voice')
- [ ] Store references in journal's autoCreatedEntities field
- [ ] Presentation: ReviewAutoCreatedPage — show parsed entities, allow user to edit/confirm/delete before saving
- [ ] Presentation: inline notification when entities are auto-created ("Created 2 sessions and 3 meals from your journal")
- [ ] Compensation profile update: parse journal for body awareness mentions (pain, tightness, improvements)
- [ ] Tests: unit tests for entity extraction parsing logic (various input patterns)
- [ ] Tests: widget tests for review page

---

## Block 12 — Nutrition MVP

- [ ] Domain: Meal entity (id, userId, date, mealType, description, stomachFeeling, stomachNotes, source, linkedJournalId)
- [ ] Domain: MealRepository interface (create, update, delete, getByDate, getHistory)
- [ ] Domain: CreateMeal, UpdateMeal, DeleteMeal, GetMealsByDate use cases
- [ ] Data: MealModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreMealDatasource
- [ ] Data: MealRepositoryImpl
- [ ] Presentation: MealLogPage — add meal (voice/text/manual), select meal type, stomach feeling (1-5), stomach notes
- [ ] Presentation: DailyMealsView — list all meals for a day with stomach feeling indicators
- [ ] Presentation: StomachPatternView — simple view showing stomach feeling trends over time (which meals correlate with bad feelings)
- [ ] Voice meal input: use speech_to_text, parse for meal description and stomach state
- [ ] Tests: unit tests for meal use cases
- [ ] Tests: widget tests for meal log and daily view

---

## Block 13 — Sleep Logging

- [ ] Domain: SleepLog entity (id, userId, bedTime, wakeTime, quality, notes, date)
- [ ] Domain: SleepRepository interface (log, getLogs, getAverageQuality)
- [ ] Domain: LogSleep, GetSleepLogs, GetAverageSleepQuality use cases
- [ ] Data: SleepLogModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreSleepDatasource
- [ ] Data: SleepRepositoryImpl
- [ ] Presentation: SleepLogEntryWidget (quick entry: bed time, wake time, quality 1-5, optional notes)
- [ ] Presentation: SleepHistoryChart (7-day and 30-day views with quality trend line)
- [ ] Tests: unit tests for use cases
- [ ] Tests: widget tests for sleep entry and chart

---

## Block 14 — Progress Photos & Weight

- [ ] Domain: ProgressPhoto entity (id, userId, date, photoUrl, angle, notes)
- [ ] Domain: WeightLog entity (id, userId, date, weight, notes)
- [ ] Domain: ProgressPhotoRepository interface (capture, getByDate, getTimeline, getByAngle)
- [ ] Domain: WeightLogRepository interface (log, getLogs, getTrend)
- [ ] Domain: CaptureProgressPhoto, GetPhotoTimeline, LogWeight, GetWeightTrend use cases
- [ ] Data: ProgressPhotoModel, WeightLogModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreProgressPhotoDatasource, FirestoreWeightLogDatasource
- [ ] Data: ProgressPhotoRepositoryImpl, WeightLogRepositoryImpl
- [ ] Presentation: PhotoCapturePage — guided capture (front, side left, side right, back) with overlay guides
- [ ] Presentation: PhotoTimelinePage — chronological gallery, tap to compare side-by-side
- [ ] Presentation: PhotoComparisonView — side-by-side before/after with date labels
- [ ] Presentation: WeightLogEntry — quick weight input
- [ ] Presentation: WeightTrendChart — line chart over time with trend line
- [ ] Firebase Storage: upload photos, generate thumbnail URLs
- [ ] Tests: unit tests for use cases
- [ ] Tests: widget tests for photo capture, timeline, and weight pages

---

## Block 15 — Auto-Progression

- [ ] Domain: ProgressionRule entity (exerciseId, completionThreshold, sleepThreshold, pulseThreshold)
- [ ] Domain: ProgressionService (evaluate readiness, suggest next step)
- [ ] Logic: check completion count (default 3x successful completions before advancing)
- [ ] Logic: check sleep quality (average over last 3 days must meet threshold)
- [ ] Logic: check weekly pulse score (energy + soreness + motivation composite)
- [ ] Logic: check stomach/gut trends (consistent gut issues may suggest deload)
- [ ] Progression actions: increase reps, increase load, advance to harder variation (via progressionIds)
- [ ] Deload triggers: poor sleep trend, low pulse score, pain reported in weekly pulse, persistent gut issues
- [ ] Goal progress update: when exercise progression happens, update related goal currentValue
- [ ] Presentation: ProgressionSettingsPage (configure thresholds per exercise or globally)
- [ ] Presentation: ProgressionSuggestionCard (shown after session completion — accept/dismiss/modify)
- [ ] Tests: unit tests for progression logic (all paths: advance, hold, deload)

---

## Block 16 — Calendar

- [ ] Calendar view (month + week toggle modes) showing scheduled sessions (training + recovery)
- [ ] Tap day to view existing sessions or create new session
- [ ] Color-coded by status (planned=blue, completed=green, skipped=gray, recovery=purple, rest=transparent)
- [ ] Session type icons (training, recovery, mobility, breathing)
- [ ] Journal indicators on calendar days (show which days have journal entries)
- [ ] Google Calendar sync (one-way push via Google Calendar API)
- [ ] Apple Calendar sync (one-way push via device_calendar package)
- [ ] Tests: widget tests for calendar rendering and day tap interaction

---

## Block 17 — Dashboard & Navigation

- [ ] Home dashboard: today's sessions (training + recovery), journal prompts, goal progress cards, weekly overview, monthly glance
- [ ] Missed-day motivation: if user missed yesterday, show encouraging message with goal reminder (not guilt)
- [ ] Quick actions: start journal (voice), log meal, log sleep, take progress photo
- [ ] Streak counter (counts training + recovery + journal days, not just training)
- [ ] Weekly overview: days active vs planned, training/recovery balance
- [ ] Monthly glance: heat map or simple grid showing activity density
- [ ] Goal progress visualization: progress bars toward movement goals
- [ ] Bottom navigation: Home, Calendar, Exercises, Goals, Profile
- [ ] GoRouter setup with all routes and auth guard
- [ ] Profile page: edit name, avatar, training preferences, notification settings
- [ ] App theme and styling (light-mode-first, high contrast, generous tap targets, earth tones)
- [ ] Animated screen transitions (no raw MaterialPageRoute — use PageRouteBuilder)
- [ ] Tests: widget tests for dashboard, navigation, and profile page

---

## Implementation notes

### Architecture (mandatory order per block)
1. Domain entities → 2. Repository interfaces → 3. Use cases → **4. Tests (TDD — write test FIRST)** → 5. Data models → 6. Datasources → 7. Repository impl → 8. Integration tests → 9. Riverpod providers → 10. Widgets → 11. Widget tests

### Key file references
| File | Purpose |
|---|---|
| `lib/main.dart` | App entry, Firebase init, emulator connect |
| `lib/core/errors/app_failure.dart` | Sealed failure hierarchy |
| `lib/core/constants/app_keys.dart` | Widget Keys for testing — **do not redefine keys locally in page files** |
| `lib/core/router/app_router.dart` | GoRouter instance — add new routes here |
| `lib/core/router/routes.dart` | Route path constants — `Routes.exerciseDetail(id)` is a static method pattern, follow for parameterized routes |
| `lib/core/providers/firebase_providers.dart` | Firebase singleton providers |
| `lib/features/exercises/data/datasources/exercise_seed_data.dart` | 60+ seed exercises — reference IDs here for program auto-generation |

### Gotchas
- **`AppUser`** is the domain entity name (not `User` — avoids conflict with `firebase_auth.User`)
- **Tests co-located with source** in `lib/` (not `test/`). Run with `flutter test lib/`
- **Bottom nav** tabs: Home(0), Calendar(1), Exercises(2), Progress(3), Profile(4) — wired in `_AppScaffold` inside `app_router.dart`
- **Firebase options** are placeholder values pointing to `way2move-dev`. Emulator works without real credentials in debug mode
- **Zero lint warnings** before any commit — run `flutter analyze` from `frontend/mobile/` and fix all issues before finishing a task
