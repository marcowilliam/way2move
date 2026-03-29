# Phase 1 — Training System (MVP): Implementation Checklist

> **Depends on:** nothing (first phase)
> **Can run parallel with:** Phase 6 (Deployment) from mid-phase onward
> **Blocks:** Phase 2, Phase 3, Phase 4, Phase 5

**Current test count: 75 passing** (auth: 21, exercises: 17, assessments: 21, programs: 16, placeholder: 1)

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

## Block 6 — Sessions

- [ ] Domain: Session entity (id, userId, programId, date, status, exerciseBlocks, notes, duration)
- [ ] Domain: ExerciseBlock entity (exerciseId, plannedSets, actualSets, rpe, notes)
- [ ] Domain: SessionRepository interface (create, complete, getByDate, getHistory)
- [ ] Domain: CreateSession, CompleteSession, GetSessionsByDate, GetSessionHistory use cases
- [ ] Data: SessionModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreSessionDatasource
- [ ] Data: SessionRepositoryImpl
- [ ] Presentation: SessionView (today's workout — exercise list with sets/reps, mark complete, RPE input)
- [ ] Presentation: SessionSummaryPage (post-workout: planned vs actual, notes)
- [ ] Presentation: CreateStandaloneSessionPage (quick workout without program — pick exercises freely)
- [ ] Session generation from program weekly template (auto-create session for today based on active program)
- [ ] Tests: unit tests for use cases and session generation logic
- [ ] Tests: widget tests for session view and summary pages

---

## Block 7 — Sleep Logging

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

## Block 8 — Auto-Progression

- [ ] Domain: ProgressionRule entity (exerciseId, completionThreshold, sleepThreshold, pulseThreshold)
- [ ] Domain: ProgressionService (evaluate readiness, suggest next step)
- [ ] Logic: check completion count (default 3x successful completions before advancing)
- [ ] Logic: check sleep quality (average over last 3 days must meet threshold)
- [ ] Logic: check weekly pulse score (energy + soreness + motivation composite)
- [ ] Progression actions: increase reps, increase load, advance to harder variation (via progressionIds)
- [ ] Deload triggers: poor sleep trend, low pulse score, pain reported in weekly pulse
- [ ] Presentation: ProgressionSettingsPage (configure thresholds per exercise or globally)
- [ ] Presentation: ProgressionSuggestionCard (shown after session completion — accept/dismiss/modify)
- [ ] Tests: unit tests for progression logic (all paths: advance, hold, deload)

---

## Block 9 — Calendar

- [ ] Calendar view (month + week toggle modes) showing scheduled sessions
- [ ] Tap day to view existing sessions or create new session
- [ ] Color-coded by status (planned=blue, completed=green, skipped=gray, rest=transparent)
- [ ] Google Calendar sync (one-way push via Google Calendar API)
- [ ] Apple Calendar sync (one-way push via device_calendar package)
- [ ] Tests: widget tests for calendar rendering and day tap interaction

---

## Block 10 — Dashboard & Navigation

- [ ] Home dashboard: today's session card, current program progress bar, streak counter, weekly overview (days trained vs planned)
- [ ] Bottom navigation: Home, Calendar, Exercises, Progress, Profile
- [ ] GoRouter setup with all routes and auth guard
- [ ] Progress page: consistency charts, assessment score comparison over time, total sessions count
- [ ] Profile page: edit name, avatar, training preferences, notification settings
- [ ] App theme and styling (dark-mode-first, high contrast, generous tap targets)
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
