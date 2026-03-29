# Phase 1 — Training System (MVP): Implementation Checklist

> **Depends on:** nothing (first phase)
> **Can run parallel with:** Phase 6 (Deployment) from mid-phase onward
> **Blocks:** Phase 2, Phase 3, Phase 4, Phase 5

---

## Block 0 — Project Setup

- [ ] Initialize Flutter project with proper package name (com.way2move.app)
- [ ] Configure Firebase project (dev environment)
- [ ] Set up Riverpod, GoRouter, fpdart dependencies
- [ ] Set up Lefthook (pre-commit: analyze+format, pre-push: test)
- [ ] Set up Nx workspace configuration
- [ ] Configure Firebase emulator suite (Auth, Firestore, Functions, Storage)
- [ ] Create core/ folder structure (theme, router, errors, constants, utils)

---

## Block 1 — Auth

- [ ] Domain: User entity (id, email, name, avatarUrl, createdAt)
- [ ] Domain: AuthRepository interface (signIn, signUp, signOut, currentUser, authStateChanges)
- [ ] Domain: SignIn, SignUp, SignOut use cases
- [ ] Data: FirebaseAuthDatasource (email+password, Google, Apple sign-in)
- [ ] Data: UserModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: AuthRepositoryImpl with Either error handling
- [ ] Presentation: AuthNotifier provider (AsyncNotifierProvider)
- [ ] Presentation: LoginPage (email + password, social sign-in buttons)
- [ ] Presentation: SignUpPage (email, password, confirm password, name)
- [ ] Tests: unit tests for SignIn, SignUp, SignOut use cases
- [ ] Tests: widget tests for LoginPage and SignUpPage
- [ ] Cloud Function: onUserCreate trigger (creates user doc in Firestore with default fields)

---

## Block 2 — Exercise Library (Domain + Data)

- [ ] Domain: Exercise entity with full taxonomy (id, name, description, videoUrl, sportTags, patternTags, planeTags, typeTags, regionTags, equipmentTags, difficulty, progressionIds, regressionIds, cues)
- [ ] Domain: ExerciseRepository interface (getExercises, getExerciseById, searchExercises, addCustomExercise)
- [ ] Domain: GetExercises, SearchExercises, AddExercise use cases
- [ ] Data: ExerciseModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreExerciseDatasource
- [ ] Data: ExerciseRepositoryImpl with caching (seed data cached permanently after first load)
- [ ] Tests: unit tests for all use cases and model serialization
- [ ] Seed data: create exercises.json with ~60-80 curated exercises (DNS, PRI, mobility, stability, strength, breathing, hypermobility)

---

## Block 3 — Exercise Library (Presentation)

- [ ] ExerciseListPage with filtering (by sport, type, region, equipment)
- [ ] ExerciseSearchDelegate (search by name, pattern, tags)
- [ ] ExerciseDetailPage (video player, description, cues, progressions/regressions links)
- [ ] AddExerciseDialog (name, description, video URL from YouTube/Instagram, tag selection)
- [ ] Exercise card widget with tags display and difficulty indicator
- [ ] Providers: exerciseListProvider, exerciseSearchProvider, exerciseFilterProvider
- [ ] Tests: widget tests for exercise list, detail, and add dialog

---

## Block 4 — Assessment System

- [ ] Domain: Assessment entity (id, userId, date, answers, compensationResults, movementScores)
- [ ] Domain: AssessmentRepository interface (create, getLatest, getHistory)
- [ ] Domain: CreateAssessment, GetLatestAssessment, GetAssessmentHistory use cases
- [ ] Data: AssessmentModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreAssessmentDatasource
- [ ] Data: AssessmentRepositoryImpl
- [ ] Presentation: InitialAssessmentFlow (multi-step: record movements, answer questions, view results)
- [ ] Presentation: WeeklyPulseDialog (quick 2-min check-in: energy, soreness, motivation, sleep)
- [ ] Presentation: AssessmentHistoryPage (list past assessments with scores)
- [ ] Video recording integration (camera package for recording screening movements)
- [ ] Compensation detection from questionnaire answers (rule-based, not AI)
- [ ] Tests: unit tests for use cases and compensation detection logic
- [ ] Tests: widget tests for assessment flow and weekly pulse

---

## Block 5 — Programs

- [ ] Domain: Program entity (id, userId, name, goal, durationWeeks, weekTemplate, isActive, createdAt)
- [ ] Domain: WeekTemplate entity (days: Map of DayTemplate)
- [ ] Domain: DayTemplate entity (focus, exerciseBlocks: list of planned exercises with sets/reps)
- [ ] Domain: ProgramRepository interface (create, getActive, update, deactivate, getHistory)
- [ ] Domain: CreateProgram, GetActiveProgram, UpdateProgram, DeactivateProgram use cases
- [ ] Data: ProgramModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreProgramDatasource
- [ ] Data: ProgramRepositoryImpl
- [ ] Presentation: ProgramBuilderPage (set name, goal, duration, weekly template)
- [ ] Presentation: WeekTemplateEditor (assign focus + exercises to each training day)
- [ ] Presentation: ProgramDetailPage (view active program, weekly overview, progress)
- [ ] Auto-generate starter program from assessment results (map compensations to corrective exercises)
- [ ] Tests: unit tests for use cases and program generation logic
- [ ] Tests: widget tests for program builder and detail pages

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
