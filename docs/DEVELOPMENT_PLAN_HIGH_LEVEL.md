# Way2Move -- High-Level Development Plan

## Phase Overview

| Phase | Name | Core Deliverable | Duration (est.) |
|---|---|---|---|
| Phase 1 | Training + Body Awareness MVP | Exercise library, programs, sessions (training + recovery), journaling (voice-first), compensation profile, goal system, nutrition MVP, sleep, progress photos, motivating dashboard | 12-16 weeks |
| Phase 2 | AI-Powered Assessment | Video-based movement assessment, AI-generated programs, compensation detection | 6-8 weeks |
| Phase 3 | Advanced Nutrition | Photo food recognition, full macro tracking, meal planning, cloud speech-to-text upgrade | 6-8 weeks |
| Phase 4a | Smart Recovery v1 | Recovery score (sleep + training load + weekly pulse + gut), deload recommendations | 3-4 weeks |
| Phase 4b | Enhanced Recovery | Add nutrition adherence to recovery score (requires Phase 3) | 1-2 weeks |
| Phase 5 | Social & Coaching | Coach role, team workouts, social feed, web dashboard | 8-10 weeks |
| Phase 6 | Distribution | App Store (iOS + Android), TestFlight beta, marketing site | 4-6 weeks |

---

## Dependency Diagram

```
                    ┌──────────────────────┐
                    │   Phase 1            │
                    │ Training + Body      │
                    │ Awareness MVP        │
                    │ (foundation)         │
                    └──────┬───────────────┘
                           │
              ┌────────────┼────────────┬────────────┐
              │            │            │            │
              ▼            ▼            ▼            ▼
   ┌──────────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────┐
   │  Phase 2     │ │ Phase 3   │ │ Phase 4a │ │  Phase 5     │
   │ AI           │ │ Advanced  │ │ Recovery │ │  Social &    │
   │ Assessment   │ │ Nutrition │ │ Score v1 │ │  Coaching    │
   └──────────────┘ └─────┬─────┘ └──────────┘ └──────────────┘
                          │
                          │ full nutrition data
                          ▼
                   ┌─────────────┐
                   │  Phase 4b   │
                   │  Enhanced   │
                   │  Recovery   │
                   └─────────────┘

   Phase 6 (Distribution) can overlap with late Phase 1+
   ┌──────────────┐
   │  Phase 6     │──── starts mid-Phase 1 (app store setup,
   │ Distribution │     CI/CD, TestFlight), full push after Phase 1
   └──────────────┘
```

### Dependency rules

- **Phase 1 is the foundation** -- every other phase depends on it
- **Phases 2, 3, 4a, 5 are independent** of each other after Phase 1 is complete
- **Phase 4a (Recovery v1) depends only on Phase 1** -- sleep quality, session data, weekly pulse, and stomach feeling are enough for a useful v1 recovery score
- **Phase 4b (Enhanced Recovery) depends on Phase 3** -- adds caloric deficit/surplus, macro adherence, and hydration data to the recovery formula
- **Phase 6 can start mid-Phase 1** -- app store accounts, CI/CD pipeline, TestFlight beta setup are independent of feature work; full distribution push happens after Phase 1

---

## Phase 1: Training + Body Awareness MVP

**Goal:** A usable training and body awareness app. Users can journal (voice-first), track compensations, set movement goals, browse exercises (PRI/DNS focus with gait cycle education), follow programs, log training + recovery sessions, track nutrition (meals + stomach feeling), log sleep, take progress photos, track weight, and see motivating progress — all with voice as primary input.

### Blocks

1. **Project Setup** -- repo, Flutter scaffold, Firebase project, emulators, CI
2. **Auth** -- email/password sign-up/sign-in, onUserCreate trigger, auth state management
3. **User Profile** -- onboarding flow (goals, equipment, schedule), profile editing
4. **Exercise Library** -- seed data (PRI/DNS focus), browse/search/filter, exercise detail, gait phase tags, compensation-targeted tags
5. **Gait Cycle Education** -- gait phase breakdown, exercises mapped to phases, educational content
6. **Assessment System** -- initial questionnaire, weekly pulse (with stomach feeling), full re-assessment, compensation detection (rule-based)
7. **Compensation Profile** -- body map, compensation tracking (active/improving/resolved), fed by assessments + journals
8. **Goal System** -- suggested goals from compensations + sport, custom goals, linked to exercises, progress tracking
9. **Program Builder** -- create program from template, week/day structure, exercise selection, linked goals
10. **Sessions** -- planned sessions from program, standalone sessions, recovery sessions (foam roller, meditation, breathwork), mark complete/skip, log actual performance
11. **Journaling** -- voice-first (device STT), 4 types (wake-up, pre-session, post-session, bedtime), auto-create sessions/meals from bedtime journal
12. **Voice Daily Summary** -- speech-to-text parsing, entity extraction (sessions + meals), review & edit auto-created entities
13. **Nutrition MVP** -- meal logging (description + stomach feeling), voice/text/manual input, daily meal overview
14. **Sleep Logging** -- manual entry (bed time, wake time, quality), sleep history
15. **Progress Photos + Weight** -- photo capture (front/side/back), timeline, weight logging, trend chart
16. **Auto-Progression** -- progression rules, suggest harder/easier based on performance + recovery
17. **Calendar** -- month/week view, training + recovery sessions, Google/Apple Calendar sync
18. **Dashboard** -- motivating home: today's tasks, weekly overview, monthly glance, goal progress, missed-day encouragement

### Key decisions
- Voice-first: device speech-to-text (free, offline) for MVP
- No coach role yet
- No AI assessment (scoring is rule-based in Phase 1)
- No macro/calorie tracking (nutrition is awareness-only)
- No social features
- Firebase Spark (free) plan
- PRI/DNS methodology is core, not optional
- Recovery sessions are first-class (not hidden under exercises)
- Bedtime journal is the catch-all logging mechanism

---

## Phase 2: AI-Powered Assessment

**Goal:** Add on-device video-based movement analysis that detects compensations from pose landmarks and generates personalized corrective programs.

**Depends on:** Phase 1 (exercise library, program structure, user profile, compensation profile)

### Blocks

0. **ML Model Integration** -- evaluate and integrate `flutter_pose_detection` (MediaPipe BlazePose), build `PoseEstimationService` wrapper, landmark extraction pipeline ✅
1. **Video Analysis Pipeline** -- camera recording flow (5 screening movements), on-device NPU pose analysis, video compression + Firebase Storage upload, save `VideoAnalysis` to Firestore ✅
2. **Compensation Detection** -- threshold-based detection from pose frames, severity scoring by frame ratio, merge AI + questionnaire results via `CompensationReport` ✅
3. **AI-Generated Program Recommendations** -- rule-based `ProgramRecommendationEngine` (severity-prioritized compensation → exercise selection → weekly template), review UI, accept → `CreateProgram`
4. **Before/After Comparison UI** -- side-by-side video playback, pose overlay with `CustomPainter`, color-coded joints, radar/bar chart, compensation improvement summary
5. **Re-Assessment Scheduling** -- `ReAssessmentSchedule` entity, Cloud Function trigger on assessment complete, FCM push notifications, assessment timeline page

### Key decisions
- **On-device ML, not Cloud Function proxy** -- pose estimation runs entirely on-device via `flutter_pose_detection` (MediaPipe BlazePose, 33 landmarks). No external AI API needed, no API keys, works offline. Android minSdkVersion raised to 31.
- **Two inference modes** -- GPU (~3ms/frame) for live camera, NPU (~13ms/frame) for batch video analysis (battery-efficient)
- **Threshold-based compensation detection** -- pure Dart rules evaluate joint angles/positions per frame. No ML model for compensation classification (deterministic, debuggable, tunable).
- **Program generation is rule-based** -- maps detected compensations to exercises using existing `GetSuggestedGoals` mapping + severity prioritization. No LLM or external API needed.
- Video clips stored in Firebase Storage (`users/{userId}/assessments/{assessmentId}/{movement}.mp4`)
- Assessment results merge with questionnaire via `CompensationReport.merge()` (video severity takes precedence)

---

## Phase 3: Advanced Nutrition

**Goal:** Upgrade nutrition MVP with AI-powered tracking, full macro targets, and meal planning. Upgrade voice input to cloud API.

**Depends on:** Phase 1 (user profile with goals, weight, activity level, nutrition MVP data)

### Blocks

1. **Cloud Speech-to-Text Upgrade** -- replace device STT with cloud API for better accuracy across all voice features
2. **Food Database** -- search foods, nutritional info (external API or seed data)
3. **Photo Food Recognition** -- camera → AI API → identified foods with macros
4. **Full Meal Tracking** -- calories, protein, carbs, fat per meal (upgrade from description-only)
5. **Macro Targets** -- daily targets based on goal, visual progress (ring charts)
6. **Meal Planning** -- schedule meals for the week, copy from previous days
7. **Grocery List** -- auto-generated from meal plan
8. **Nutrition History** -- calorie/macro trends, stomach feeling correlation with foods

### Key decisions
- External food database API (or open-source nutritional data)
- AI meal recognition via Cloud Functions (same proxy pattern as Phase 2)
- Stomach feeling data from Phase 1 nutrition MVP carries over
- Cloud STT upgrade benefits all voice features app-wide, not just nutrition

---

## Phase 4: Smart Recovery

**Goal:** Holistic recovery scoring that combines sleep, nutrition, gut health, and training load. Recommends deload weeks and rest days.

**Depends on:** Phase 1 (sleep data, training load, gut/stomach data)
**Enhanced by:** Phase 3 (full nutrition data — adds caloric deficit/surplus to score)

### Phase 4a — Recovery Score v1 (after Phase 1, no Phase 3 dependency)

Uses data already available from Phase 1: sleep quality, training load (session volume/intensity), weekly pulse (energy, soreness, motivation), and stomach feeling from meals.

### Phase 4b — Enhanced Recovery Score (after Phase 3)

Adds caloric deficit/surplus, macro adherence, and hydration data from Phase 3 to the recovery formula for a more comprehensive score.

### Blocks

0. **Recovery Score Algorithm** -- weighted composite; v1 uses sleep (30%), training load (40%), weekly pulse (20%), gut feeling (10%); v2 adds nutrition adherence from Phase 3
1. **Training Load Tracking** -- rolling 7-day and 28-day load (volume * intensity)
2. **Training Adjustment Recommendations** -- green/yellow/red zones, auto-suggest modifications, recovery overrides progression
3. **Recovery Dashboard** -- daily recovery score, trend chart, contributing factors, actionable advice
4. **Wearable Integration** (optional) -- Apple Health / Google Fit for sleep and HRV data

### Key decisions
- **Phase 4a can start after Phase 1** -- Phase 1 already provides sleep quality, session data, weekly pulse, and stomach feeling. Enough for a useful v1 recovery score.
- Recovery score is a Cloud Function (callable) -- complex calculation stays server-side
- Score components v1: sleep (30%), training load trend (40%), weekly pulse (20%), gut feeling (10%)
- Score components v2 (after Phase 3): sleep (25%), training load (35%), nutrition adherence (20%), weekly pulse (10%), gut feeling (10%)
- Wearable integration is optional (enhances score but not required)
- Recovery sessions from Phase 1 positively influence recovery score

---

## Phase 5: Social & Coaching

**Goal:** Add coach role, team workouts, social feed. Web dashboard for coaches.

**Depends on:** Phase 1 (training infrastructure)

### Blocks

1. **Coach Role** -- coach accounts, coach-athlete relationship
2. **Program Assignment** -- coach creates and assigns programs to athletes
3. **Athlete Monitoring** -- coach views athlete's sessions, progress, compensations, recovery, goals
4. **Team Workouts** -- shared sessions for group training
5. **Social Feed** -- activity feed, workout sharing, comments
6. **Web Dashboard** -- React + Vite app for coaches (session review, athlete management, compensation profiles)
7. **Messaging** -- in-app messaging between coach and athlete

### Key decisions
- Web app is coach-focused (athlete experience stays mobile)
- Introduce Node.js API + PostgreSQL (Supabase) for social features
- Firebase Auth remains the identity provider
- Coach sees athlete's compensation profile, goals, and journal summaries (not raw journal audio)

---

## Phase 6: Distribution

**Goal:** Get the app into users' hands. App Store submissions, beta testing, marketing.

**Can start:** Mid-Phase 1 (CI/CD and store accounts are independent of features)

### Blocks

1. **App Store Accounts** -- Apple Developer Program, Google Play Console
2. **CI/CD Pipeline** -- GitHub Actions (Android), Codemagic (iOS -> TestFlight)
3. **TestFlight Beta** -- internal testing, beta group management
4. **App Store Submission** -- screenshots, descriptions, review guidelines compliance
5. **Marketing Site** -- landing page, waitlist, app store links
6. **Analytics** -- Firebase Analytics, Sentry error tracking, key metrics dashboard

### Key decisions
- Codemagic for iOS builds (Mac required, GitHub Actions runners are Linux)
- GitHub Actions for Android builds and Firebase deploys
- Sentry for crash reporting from day one
- Firebase Remote Config for feature flags (gradual rollout)

---

## Timeline (Estimated)

```
Month:  1    2    3    4    5    6    7    8    9    10   11   12   13   14
        ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
Phase 1 ████████████████████████████                                      Training + Body Awareness MVP
Phase 6      ░░░░░░░░░░░░░░░░░░░████                                    Distribution
Phase 2                             ████████████████                      AI Assessment
Phase 3                             ████████████████                      Advanced Nutrition
Phase 4a                            ████████████                          Recovery Score v1
Phase 5                             ████████████████████                  Social & Coaching
Phase 4b                                            ████                  Enhanced Recovery (after Phase 3)

████ = primary development
░░░░ = setup/overlap work (CI/CD, store accounts)
```

**Notes:**
- Phase 1 is larger now (12-16 weeks) due to journaling, voice, compensation profile, goals, nutrition MVP, photos
- Phases 2, 3, 4a, and 5 can run in parallel after Phase 1 (with sufficient team capacity)
- Phase 4a (Recovery v1) can start right after Phase 1 — uses sleep, sessions, weekly pulse, and stomach data already available
- Phase 4b (Enhanced Recovery) starts after Phase 3 is feature-complete (adds nutrition adherence to score)
- Phase 6 setup begins during Phase 1; full push after Phase 1 ships
- Timeline assumes a small team (1-2 developers); parallel phases require more capacity
- Each phase includes testing, polish, and documentation as part of the estimate

---

## Success Metrics (per Phase)

| Phase | Key Metric | Target |
|---|---|---|
| Phase 1 | Users can complete a full training week with journaling, goals, and nutrition tracking | 100% of core flows working, zero critical bugs |
| Phase 1 | Voice logging creates accurate sessions/meals | >80% of voice-created entities need no manual editing |
| Phase 2 | AI assessment accuracy | >80% agreement with manual assessment on test set |
| Phase 3 | Nutrition plan adherence | Users log >3 meals/day on average |
| Phase 3 | Cloud STT accuracy improvement | >90% transcription accuracy (up from device STT baseline) |
| Phase 4a | Recovery score v1 usefulness | >70% of deload/intensity recommendations feel accurate to users |
| Phase 4b | Enhanced recovery score correlation | Recovery score predicts next-session performance within 15% |
| Phase 5 | Coach adoption | >50% of coaches use web dashboard weekly |
| Phase 6 | App Store approval | First-submission approval on both stores |
