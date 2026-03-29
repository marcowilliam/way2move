# Phase 1 — Training + Body Awareness MVP: Implementation Checklist

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
- [ ] Add speech_to_text package for voice features

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

## Block 2 — User Profile & Onboarding

- [ ] Domain: UserProfile entity (full profile with goals, sports, equipment, injuries)
- [ ] Domain: ProfileRepository interface (getProfile, updateProfile)
- [ ] Domain: GetProfile, UpdateProfile use cases
- [ ] Data: UserProfileModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: ProfileRepositoryImpl
- [ ] Presentation: OnboardingFlow (multi-step: name, age, goals, sports, equipment, training days, injuries)
- [ ] Presentation: ProfileEditPage (edit all profile fields)
- [ ] Tests: unit tests for profile use cases
- [ ] Tests: widget tests for onboarding flow

---

## Block 3 — Exercise Library (Domain + Data)

- [ ] Domain: Exercise entity with full taxonomy (id, name, description, videoUrl, sportTags, patternTags, planeTags, typeTags, regionTags, equipmentTags, gaitPhaseTags, difficulty, progressionIds, regressionIds, cues, compensationsTargeted)
- [ ] Domain: ExerciseRepository interface (getExercises, getExerciseById, searchExercises, addCustomExercise, getByGaitPhase, getByCompensation)
- [ ] Domain: GetExercises, SearchExercises, AddExercise, GetExercisesByGaitPhase, GetExercisesByCompensation use cases
- [ ] Data: ExerciseModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreExerciseDatasource
- [ ] Data: ExerciseRepositoryImpl with caching (seed data cached permanently after first load)
- [ ] Tests: unit tests for all use cases and model serialization
- [ ] Seed data: create exercises.json with ~80-100 curated exercises (DNS, PRI, mobility, stability, strength, breathing, recovery, gait-specific, hypermobility)
- [ ] Seed data: create gait_cycle.json with phase definitions and educational content

---

## Block 4 — Exercise Library (Presentation) + Gait Cycle Education

- [ ] ExerciseListPage with filtering (by sport, type, region, equipment)
- [ ] ExerciseSearchDelegate (search by name, pattern, tags)
- [ ] ExerciseDetailPage (video player, description, cues, progressions/regressions, compensations targeted, gait phases)
- [ ] AddExerciseDialog (name, description, video URL from YouTube/Instagram, tag selection including gait phase)
- [ ] Exercise card widget with tags display and difficulty indicator
- [ ] GaitCycleView — educational breakdown of stance and swing phases with visuals
- [ ] GaitPhaseExerciseList — exercises grouped by gait phase they help with
- [ ] Providers: exerciseListProvider, exerciseSearchProvider, exerciseFilterProvider, gaitCycleProvider
- [ ] Tests: widget tests for exercise list, detail, gait cycle view, and add dialog

---

## Block 5 — Assessment System

- [ ] Domain: Assessment entity (id, userId, date, type, responses, compensationsFound, bodyMapPainPoints, stomachFeeling)
- [ ] Domain: AssessmentRepository interface (create, getLatest, getHistory)
- [ ] Domain: CreateAssessment, GetLatestAssessment, GetAssessmentHistory use cases
- [ ] Data: AssessmentModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreAssessmentDatasource
- [ ] Data: AssessmentRepositoryImpl
- [ ] Presentation: InitialAssessmentFlow (multi-step: record movements, answer questions, view results)
- [ ] Presentation: WeeklyPulseDialog (quick 2-min check-in: energy, soreness, motivation, sleep, stomach feeling)
- [ ] Presentation: AssessmentHistoryPage (list past assessments with scores)
- [ ] Video recording integration (camera package for recording screening movements)
- [ ] Compensation detection from questionnaire answers (rule-based, not AI)
- [ ] Auto-populate compensation profile from assessment results
- [ ] Tests: unit tests for use cases and compensation detection logic
- [ ] Tests: widget tests for assessment flow and weekly pulse

---

## Block 6 — Compensation Profile

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

## Block 7 — Goal System

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

## Block 8 — Programs

- [ ] Domain: Program entity (id, userId, name, goal, durationWeeks, weekTemplate, isActive, linkedGoalIds, createdAt)
- [ ] Domain: WeekTemplate entity (days: Map of DayTemplate)
- [ ] Domain: DayTemplate entity (focus, exerciseBlocks: list of planned exercises with sets/reps)
- [ ] Domain: ProgramRepository interface (create, getActive, update, deactivate, getHistory)
- [ ] Domain: CreateProgram, GetActiveProgram, UpdateProgram, DeactivateProgram use cases
- [ ] Data: ProgramModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreProgramDatasource
- [ ] Data: ProgramRepositoryImpl
- [ ] Presentation: ProgramBuilderPage (set name, goal, duration, weekly template, linked goals)
- [ ] Presentation: WeekTemplateEditor (assign focus + exercises to each training day)
- [ ] Presentation: ProgramDetailPage (view active program, weekly overview, progress toward linked goals)
- [ ] Auto-generate starter program from assessment results (map compensations to corrective exercises)
- [ ] Tests: unit tests for use cases and program generation logic
- [ ] Tests: widget tests for program builder and detail pages

---

## Block 9 — Sessions (Training + Recovery)

- [ ] Domain: Session entity (id, userId, programId, date, status, type, focus, exerciseBlocks, notes, duration, source)
- [ ] Domain: ExerciseBlock entity (exerciseId, plannedSets, actualSets, rpe, notes)
- [ ] Domain: SessionRepository interface (create, complete, getByDate, getHistory, getByType)
- [ ] Domain: CreateSession, CompleteSession, GetSessionsByDate, GetSessionHistory use cases
- [ ] Data: SessionModel (fromFirestore/toFirestore/toEntity)
- [ ] Data: FirestoreSessionDatasource
- [ ] Data: SessionRepositoryImpl
- [ ] Presentation: SessionView (today's workout — exercise list with sets/reps, mark complete, RPE input)
- [ ] Presentation: SessionSummaryPage (post-workout: planned vs actual, notes, prompt for post-session journal)
- [ ] Presentation: CreateStandaloneSessionPage (quick workout without program — pick exercises freely)
- [ ] Presentation: RecoverySessionPage (foam roller, lacrosse ball, meditation, breathwork — track duration and body areas)
- [ ] Recovery session templates (common recovery routines: foam roller full body, breathing reset, standing meditation)
- [ ] Session generation from program weekly template (auto-create session for today based on active program)
- [ ] Tests: unit tests for use cases and session generation logic
- [ ] Tests: widget tests for session view, recovery session, and summary pages

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
