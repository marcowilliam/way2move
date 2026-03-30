# Phase 1 — Training + Body Awareness MVP: Implementation Checklist

> **Depends on:** nothing (first phase)
> **Can run parallel with:** Phase 6 (Deployment) from mid-phase onward
> **Blocks:** Phase 2, Phase 3, Phase 4, Phase 5

**Current test count: 517 passing** (auth: 21, exercises: 17, assessments: 21, programs: 16, sessions: 24, profile: 32, compensations: 38, goals: 39, calendar: 10, dashboard: 15, sleep: 25, nutrition: 26)

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

## Block 8 — Compensation Profile ✅

- [x] Domain: Compensation entity (id, userId, name, type, region, severity, status, source, relatedGoalIds, relatedExerciseIds, history, detectedAt, resolvedAt)
- [x] Domain: CompensationRepository interface (create, update, getActive, getByRegion, getHistory, markImproving, markResolved)
- [x] Domain: CreateCompensation, UpdateCompensation, GetActiveCompensations, MarkCompensationImproving, MarkCompensationResolved use cases
- [x] Data: CompensationModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreCompensationDatasource
- [x] Data: CompensationRepositoryImpl
- [x] Presentation: CompensationProfilePage — body map showing active compensations with severity indicators
- [x] Presentation: CompensationDetailPage — history, related goals, related exercises, severity timeline
- [x] Presentation: CompensationBodyMap widget — interactive body outline with tap regions
- [x] Logic: parse journal entries for compensation-related mentions (keyword-based Phase 1)
- [x] Tests: unit tests for compensation use cases and journal parsing logic
- [x] Tests: widget tests for compensation profile and body map

---

## Block 9 — Goal System ✅

- [x] Domain: Goal entity (id, userId, name, description, category, targetMetric, targetValue, currentValue, unit, sport, compensationIds, exerciseIds, source, status, achievedAt)
- [x] Domain: GoalRepository interface (create, update, getAll, getByStatus, getByCompensation, markAchieved)
- [x] Domain: CreateGoal, UpdateGoal, GetGoals, GetGoalsByCompensation, MarkGoalAchieved use cases
- [x] Domain: GetSuggestedGoals use case (maps CompensationPattern → Goal templates)
- [x] Data: GoalModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreGoalDatasource
- [x] Data: GoalRepositoryImpl
- [x] Logic: generate suggested goals from compensation patterns (rule-based mapping — 10 patterns)
- [x] Presentation: GoalSetupPage — shown after initial assessment, suggested + custom goals
- [x] Presentation: GoalListPage — goal cards with progress bars, staggered animation, empty state
- [x] Presentation: GoalDetailPage — animated progress bar, target vs current, compensation/exercise chips, mark achieved
- [x] Presentation: AddGoalDialog — custom goal creation with category chips, metric/value/unit fields
- [x] Providers: goalRepositoryProvider, getGoalsProvider, activeGoalsProvider, goalNotifierProvider
- [x] Routes: /goals (GoalListPage), /goals/setup (GoalSetupPage), /goals/:goalId (GoalDetailPage)
- [x] Firestore security rules: goals collection — owner read/write only
- [x] Tests: unit tests for CreateGoal, UpdateGoal, GetGoals, GetGoalsByCompensation, MarkGoalAchieved, GetSuggestedGoals (20 tests)
- [x] Tests: widget tests for GoalListPage, GoalDetailPage, AddGoalDialog, GoalSetupPage

### UI — What to test
- **GoalListPage** (`/goals`, inside shell): goal cards with name, category chip, source badge (Suggested), linear progress bar with current/target values; FAB "+" opens AddGoalDialog; empty state shows "No goals yet. Complete an assessment to get suggestions."; pull to refresh
- **GoalDetailPage** (`/goals/:goalId`, inside shell): goal name in AppBar, progress card with animated progress bar, current/target value, percentage complete, description section, linked compensation chips (red), linked exercise chips (green), "Mark as Achieved" filled green button; on achievement: snack bar with checkmark; achieved goals show achievement date card instead of button
- **AddGoalDialog** (modal): name field, optional description, category choice chips (Mobility, Stability, Strength, Endurance, Posture, Sport, Recovery, General), metric/target value/unit fields in a row, Cancel/Save buttons; validation shows inline errors
- **GoalSetupPage** (`/goals/setup`, full-screen outside shell): title "Set Up Your Goals", suggested goal cards (animated stagger entrance) each showing name + target; tap to select (animated checkmark), tap again to deselect; "Add X goals" filled button appears when goals are selected; "Add Custom Goal" outlined button always visible; "Done" button top-right navigates to home

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

## Block 12 — Nutrition MVP ✅

- [x] Domain: Meal entity (id, userId, date, mealType, description, stomachFeeling, stomachNotes, source, linkedJournalId)
- [x] Domain: MealRepository interface (create, update, delete, getByDate, getHistory)
- [x] Domain: CreateMeal, UpdateMeal, DeleteMeal, GetMealsByDate use cases
- [x] Data: MealModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreMealDatasource
- [x] Data: MealRepositoryImpl
- [x] Presentation: MealLogPage — add meal (text/manual), select meal type, stomach feeling (1-5), stomach notes
- [x] Presentation: DailyMealsView — list all meals for a day with stomach feeling indicators, grouped by type, swipe-to-delete
- [x] Presentation: DailyNutritionPage — date navigator, summary card, FAB to log meal
- [x] Presentation: StomachPatternPage — 14-day trend view showing avg stomach feeling per meal type
- [x] Riverpod: dailyMealsNotifierProvider, stomachTrendProvider
- [x] Routes: /nutrition, /nutrition/log, /nutrition/patterns added to GoRouter
- [x] Firestore security rules: meals collection
- [x] Tests: unit tests for CreateMeal, UpdateMeal, DeleteMeal, GetMealsByDate (14 tests)
- [x] Tests: widget tests for MealLogPage (7 tests) and DailyMealsView (5 tests)

### UI — What to test
- **DailyNutritionPage** (`/nutrition`): date navigator ← today →, summary card (meals count + avg stomach feeling with color coding), FAB + navigates to MealLogPage, patterns icon navigates to StomachPatternPage
- **MealLogPage** (`/nutrition/log`): meal type chip selector (Breakfast/Lunch/Dinner/Snack/Drink), description multi-line field, stomach feeling 5-emoji selector (😣😕😐🙂😊), optional notes field, save disabled until type + description + feeling filled, save creates meal and pops
- **DailyMealsView**: sections per meal type (BREAKFAST/LUNCH/DINNER/SNACK/DRINK), "No X logged yet" empty state per section, meal card shows description + emoji + time, notes indicator icon when notes present, swipe left to delete
- **StomachPatternPage** (`/nutrition/patterns`): "Stomach Pattern" headline, "Based on your last 14 days" subtitle, colored progress bars per meal type with avg score, empty state when no data

---

## Block 13 — Sleep Logging ✅

- [x] Domain: SleepLog entity (id, userId, bedTime, wakeTime, quality, notes, date)
- [x] Domain: SleepRepository interface (log, getLogs, getAverageQuality)
- [x] Domain: LogSleep, GetSleepLogs, GetAverageSleepQuality use cases
- [x] Data: SleepLogModel (fromFirestore/toFirestore/toEntity)
- [x] Data: FirestoreSleepDatasource
- [x] Data: SleepRepositoryImpl
- [x] Presentation: SleepLogEntryPage (full page: bed time, wake time, quality 1-5 selector, optional notes, save button)
- [x] Presentation: SleepHistoryChart (7-day and 30-day views with quality bar chart, empty state)
- [x] Presentation: SleepHistoryPage (list view with chart header, pull to refresh)
- [x] Routes: /sleep (log entry) and /sleep/history added to GoRouter
- [x] Firestore security rules: sleepLogs collection (already present)
- [x] Tests: unit tests for LogSleep, GetSleepLogs, GetAverageSleepQuality use cases (11 tests)
- [x] Tests: widget tests for SleepLogEntryPage (8 tests) and SleepHistoryChart (6 tests)

### UI — What to test
- **SleepLogEntryPage** (`/sleep`): bed time + wake time pickers (showTimePicker), calculated duration shown, quality 1–5 chip selector (labels: Poor/Fair/Okay/Good/Excellent), optional notes field, Save button disabled until quality selected, success SnackBar on save, error SnackBar on failure
- **SleepHistoryPage** (`/sleep/history`): chart at top, list of past logs (date, time range, duration, stars), empty state, pull to refresh
- **SleepHistoryChart**: 7-day/30-day toggle, bar chart with color-coded quality bars (red=1, orange=2, yellow=3, green=4, teal=5), average quality label, empty state

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

## Block 16 — Calendar ✅ (core implemented)

- [x] Calendar view (month + week toggle modes) showing scheduled sessions (training + recovery)
- [x] Tap day to view existing sessions or create new session (DaySessionsSheet bottom sheet)
- [x] Color-coded dots by status (planned=blue, completed=green, skipped=gray, recovery=purple)
- [x] Session type icons in week strip (training, recovery, completed, skipped)
- [x] Month navigation with slide left/right animation
- [x] Week/Month toggle with AnimatedContainer transition
- [x] Day tap: ink ripple + bottom sheet slides up with curve
- [x] Session dots: staggered fade-in entrance on month load
- [x] CalendarPage with selectedDateProvider + calendarModeProvider (StateProviders)
- [x] sessionsForMonthProvider (StreamProvider.family), sessionsForDayProvider (derived)
- [x] CalendarMonthGrid widget, CalendarWeekStrip widget, DaySessionsSheet widget
- [x] Routes: /calendar wired to CalendarPage (was placeholder)
- [x] Tests: widget tests for CalendarPage (5 tests) and DaySessionsSheet (5 tests)
- [ ] Journal indicators on calendar days (deferred — requires Block 10)
- [ ] Google Calendar sync (deferred — Phase 2+)
- [ ] Apple Calendar sync (deferred — Phase 2+)

### UI — What to test
- **CalendarPage** (`/calendar`, inside shell via bottom nav): month name + year centered in top bar, left/right chevrons to navigate months (smooth slide animation), Month/Week toggle buttons top-right
  - **Month view** (default): 7-column grid, day numbers, colored dot indicators (green=completed, blue=planned, gray=skipped, purple=recovery); selected day highlighted in primary color; today highlighted with subtle primary tint; tap any day → bottom sheet slides up
  - **Week view**: 7-day horizontal strip showing day label (Mo/Tu...) + day number + session type icon; tapping "Week" toggle animates height change
- **DaySessionsSheet** (bottom sheet): drag handle at top, date header (e.g. "Saturday, March 15"), session cards each showing focus name + status chip + duration; empty state shows "No sessions. Tap 'Start New Session' to add one."; "Start New Session" / "Log Session" filled button navigates to `/session/standalone`

---

## Block 17 — Dashboard & Navigation ✅ (core implemented)

- [x] Home dashboard: today's session card, goal progress cards (top 3 active), weekly overview strip, quick actions grid
- [x] Missed-day motivation: if user missed yesterday, show encouraging banner (not guilt-based)
- [x] Quick actions: Start Session, Assessment, My Program, Exercises
- [x] Streak counter (consecutive days with a completed session)
- [x] Weekly overview: 7-day strip (M-T-W-T-F-S-S) with filled/empty circles for completed sessions
- [x] Goal progress visualization: mini cards with animated progress bars, current/target values
- [x] Bottom navigation: Home, Calendar, Exercises, Goals, Profile (swapped Progress → Goals)
- [x] GoRouter: onboarding redirect — logged-in users without onboardingComplete → /onboarding
- [x] Profile page: avatar initial + name header, stats row (streak/sessions/goals), nav tiles to all features, sign out
- [x] App theme and styling: uses AppTheme.light/dark throughout, earth tones, rounded cards
- [x] Animated screen transitions: all routes use CustomTransitionPage with fade/slide builders
- [x] Tests: 8 widget tests for HomePage, 7 widget tests for ProfilePage
- [ ] Quick actions: log journal (voice), log meal, log sleep, take progress photo — deferred (Blocks 10–14 not built)
- [ ] Monthly glance heat map — deferred (requires full history aggregation)

### UI — What to test
- **HomePage** (`/`, Home tab):
  - Greeting header with first name + date (e.g. "Good morning, Jane."), streak badge if streak > 0 (fire icon + "N days")
  - **Today's session card**: if no session → "No session today" + "Start Session" button; if session planned → focus name + "Planned" chip + exercise count + "Start Session" button; if completed → green "Great work today!" card; if in progress → primary-color banner "Tap to continue"
  - **Missed-day banner** (inside no-session card): if user had no completed session yesterday → warm "Back on track — every session counts." message
  - **This Week strip**: 7 circles labelled M T W T F S S; today's circle has a primary-colour border; days with completed sessions show a green filled circle with a checkmark
  - **Active Goals section**: if goals exist → "Active Goals" header + "See all" link + up to 3 goal mini-cards (name, progress bar, current/target/unit); if no goals → "No active goals" card with "Start" → Assessment
  - **Quick Actions grid** (2×2): "New Session", "Assessment", "My Program", "Exercises"
- **ProfilePage** (`/profile`, Profile tab):
  - AppBar "Profile" + "Edit" text button → /profile/edit
  - Header: circle avatar with initial letter, name, email, training goal badge (e.g. "Mobility")
  - **Onboarding CTA** (gold card): shown only when `onboardingComplete == false`; "Complete your setup" → /onboarding
  - **Stats row**: streak number / "Day Streak", sessions count / "Sessions", active goals count / "Goals"
  - Section **Training**: My Program → /programs; Movement Assessment → /assessment; Assessment History → /assessment/history
  - Section **Movement**: Compensation Profile → /compensations; Goals → /goals
  - Section **Account**: Edit Profile → /profile/edit; "Sign Out" red outlined button

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
- **Bottom nav** tabs: Home(0), Calendar(1), Exercises(2), Goals(3), Profile(4) — wired in `_AppScaffold` inside `app_router.dart`
- **Firebase options** are placeholder values pointing to `way2move-dev`. Emulator works without real credentials in debug mode
- **Zero lint warnings** before any commit — run `flutter analyze` from `frontend/mobile/` and fix all issues before finishing a task
