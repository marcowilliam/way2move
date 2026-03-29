# Way2Move -- High-Level Development Plan

## Phase Overview

| Phase | Name | Core Deliverable | Duration (est.) |
|---|---|---|---|
| Phase 1 | Training + Body Awareness MVP | Exercise library, programs, sessions (training + recovery), journaling (voice-first), compensation profile, goal system, nutrition MVP, sleep, progress photos, motivating dashboard | 12-16 weeks |
| Phase 2 | AI-Powered Assessment | Video-based movement assessment, AI-generated programs, compensation detection | 6-8 weeks |
| Phase 3 | Advanced Nutrition | Photo food recognition, full macro tracking, meal planning, cloud speech-to-text upgrade | 6-8 weeks |
| Phase 4 | Smart Recovery | Recovery score (sleep + nutrition + training load + gut), deload recommendations | 4-6 weeks |
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
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
   ┌──────────────┐ ┌───────────┐ ┌──────────────┐
   │  Phase 2     │ │ Phase 3   │ │  Phase 5     │
   │ AI           │ │ Advanced  │ │  Social &    │
   │ Assessment   │ │ Nutrition │ │  Coaching    │
   └──────────────┘ └─────┬─────┘ └──────────────┘
                          │
                          │ full nutrition data needed
                          ▼
                   ┌─────────────┐
                   │  Phase 4    │
                   │  Smart      │
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
- **Phases 2, 3, 5 are independent** of each other after Phase 1 is complete
- **Phase 4 depends on Phase 1 + Phase 3** -- recovery score needs full nutrition data (calorie deficit/surplus, hydration) plus training load, gut feeling, and sleep data from Phase 1
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

**Goal:** Replace rule-based assessment with AI. Users upload movement videos, AI detects compensations and generates personalized programs.

**Depends on:** Phase 1 (exercise library, program structure, user profile, compensation profile)

### Blocks

1. **Video Upload** -- camera integration, Storage upload, compression
2. **AI Assessment Pipeline** -- Cloud Function calls external AI API, parses response
3. **Compensation Detection** -- AI-powered body map visualization, auto-update compensation profile
4. **AI Program Generation** -- generate program from assessment results + user profile + compensation profile + goals
5. **Re-assessment Flow** -- full re-assessment every 4-8 weeks, compare scores over time
6. **Assessment History** -- score trends, improvement visualization, before/after photo comparison

### Key decisions
- AI API calls proxied through Cloud Functions (API keys stay server-side)
- Video stored in Firebase Storage
- Assessment results auto-update the compensation profile
- Fallback to rule-based assessment if AI API is unavailable

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

**Depends on:** Phase 1 (sleep data, training load, gut/stomach data) + Phase 3 (full nutrition data)

### Blocks

1. **Recovery Score Algorithm** -- weighted composite of sleep quality, nutrition adherence, gut health, training volume trends
2. **Training Load Tracking** -- rolling 7-day and 28-day load (volume * intensity)
3. **Deload Recommendations** -- suggest lighter week when recovery score drops
4. **Recovery Dashboard** -- daily recovery score, trend chart, actionable advice
5. **Wearable Integration** (optional) -- Apple Health / Google Fit for sleep and HRV data

### Key decisions
- Recovery score is a Cloud Function (callable) -- complex calculation stays server-side
- Score components: sleep (25%), nutrition (25%), gut health (10%), training load trend (40%)
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
Phase 5                             ████████████████████                  Social & Coaching
Phase 4                                             ████████████          Smart Recovery

████ = primary development
░░░░ = setup/overlap work (CI/CD, store accounts)
```

**Notes:**
- Phase 1 is larger now (12-16 weeks) due to journaling, voice, compensation profile, goals, nutrition MVP, photos
- Phases 2, 3, and 5 can run in parallel after Phase 1 (with sufficient team capacity)
- Phase 4 starts after Phase 3 is feature-complete (needs full nutrition data)
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
| Phase 4 | Recovery score correlation | Recovery score predicts next-session performance within 15% |
| Phase 5 | Coach adoption | >50% of coaches use web dashboard weekly |
| Phase 6 | App Store approval | First-submission approval on both stores |
