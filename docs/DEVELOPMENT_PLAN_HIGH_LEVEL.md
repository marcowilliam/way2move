# Way2Move -- High-Level Development Plan

## Phase Overview

| Phase | Name | Core Deliverable | Duration (est.) |
|---|---|---|---|
| Phase 1 | Training MVP | Exercise library, program builder, session tracking, sleep log, basic assessment | 8-10 weeks |
| Phase 2 | AI-Powered Assessment | Video-based movement assessment, AI-generated programs, compensation detection | 6-8 weeks |
| Phase 3 | Nutrition | Meal planning, macro tracking, AI-generated nutrition plans | 6-8 weeks |
| Phase 4 | Smart Recovery | Recovery score (sleep + nutrition + training load), deload recommendations | 4-6 weeks |
| Phase 5 | Social & Coaching | Coach role, team workouts, social feed, web dashboard | 8-10 weeks |
| Phase 6 | Distribution | App Store (iOS + Android), TestFlight beta, marketing site | 4-6 weeks |

---

## Dependency Diagram

```
                    ┌──────────────────┐
                    │   Phase 1        │
                    │ Training MVP     │
                    │ (foundation)     │
                    └──────┬───────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
   ┌──────────────┐ ┌───────────┐ ┌──────────────┐
   │  Phase 2     │ │ Phase 3   │ │  Phase 5     │
   │ AI           │ │ Nutrition │ │  Social &    │
   │ Assessment   │ │           │ │  Coaching    │
   └──────────────┘ └─────┬─────┘ └──────────────┘
                          │
                          │ nutrition data needed
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
- **Phase 4 depends on Phase 1 + Phase 3** -- recovery score needs nutrition data (calorie deficit/surplus, hydration) plus training load and sleep data from Phase 1
- **Phase 6 can start mid-Phase 1** -- app store accounts, CI/CD pipeline, TestFlight beta setup are independent of feature work; full distribution push happens after Phase 1

---

## Phase 1: Training MVP

**Goal:** A usable training app. Users can browse exercises, follow a program, log sessions, track sleep, and see basic progress.

### Blocks

1. **Project Setup** -- repo, Flutter scaffold, Firebase project, emulators, CI
2. **Auth** -- email/password sign-up/sign-in, onUserCreate trigger, auth state management
3. **User Profile** -- onboarding flow (goals, equipment, schedule), profile editing
4. **Exercise Library** -- seed data, browse/search/filter, exercise detail screen
5. **Program Builder** -- create program from template, week/day structure, exercise selection
6. **Session Tracking** -- planned sessions from program, mark complete/skip, log actual performance
7. **Sleep Logging** -- manual entry (bed time, wake time, quality), sleep history
8. **Basic Assessment** -- initial questionnaire, weekly pulse check-in
9. **Auto-Progression** -- progression rules, suggest harder/easier exercises based on performance + recovery
10. **Dashboard** -- home screen with today's session, weekly overview, streaks

### Key decisions
- No coach role yet
- No AI (assessment scoring is rule-based in Phase 1)
- No social features
- Firebase Spark (free) plan

---

## Phase 2: AI-Powered Assessment

**Goal:** Replace rule-based assessment with AI. Users upload movement videos, AI detects compensations and generates personalized programs.

**Depends on:** Phase 1 (exercise library, program structure, user profile)

### Blocks

1. **Video Upload** -- camera integration, Storage upload, compression
2. **AI Assessment Pipeline** -- Cloud Function calls external AI API, parses response
3. **Compensation Detection** -- body map visualization, compensation descriptions
4. **AI Program Generation** -- generate program from assessment results + user profile
5. **Re-assessment Flow** -- full re-assessment every 4-8 weeks, compare scores over time
6. **Assessment History** -- score trends, improvement visualization

### Key decisions
- AI API calls proxied through Cloud Functions (API keys stay server-side)
- Video stored in Firebase Storage
- Assessment results cached in Firestore
- Fallback to rule-based assessment if AI API is unavailable

---

## Phase 3: Nutrition

**Goal:** Nutrition tracking and AI-generated meal plans. Users log meals, track macros, and receive personalized nutrition guidance.

**Depends on:** Phase 1 (user profile with goals, weight, activity level)

### Blocks

1. **Food Database** -- search foods, nutritional info (external API or seed data)
2. **Meal Logging** -- log meals, portion sizes, quick-add favorites
3. **Macro Tracking** -- daily macro targets based on goal, visual progress
4. **AI Meal Planning** -- Cloud Function calls AI API, generates weekly meal plan
5. **Grocery List** -- auto-generated from meal plan
6. **Nutrition History** -- calorie/macro trends over time

### Key decisions
- External food database API (or open-source nutritional data)
- AI meal plans via Cloud Functions (same proxy pattern as Phase 2)
- Meal plan data stored in Firestore
- Macro targets calculated from user profile (weight, goal, activity level)

---

## Phase 4: Smart Recovery

**Goal:** Holistic recovery scoring that combines sleep, nutrition, and training load. Recommends deload weeks and rest days.

**Depends on:** Phase 1 (sleep data, training load) + Phase 3 (nutrition data)

### Blocks

1. **Recovery Score Algorithm** -- weighted composite of sleep quality, nutrition adherence, training volume trends
2. **Training Load Tracking** -- rolling 7-day and 28-day load (volume * intensity)
3. **Deload Recommendations** -- suggest lighter week when recovery score drops
4. **Recovery Dashboard** -- daily recovery score, trend chart, actionable advice
5. **Wearable Integration** (optional) -- Apple Health / Google Fit for sleep and HRV data

### Key decisions
- Recovery score is a Cloud Function (callable) -- complex calculation stays server-side
- Score components: sleep (30%), nutrition (30%), training load trend (40%)
- Wearable integration is optional (enhances score but not required)

---

## Phase 5: Social & Coaching

**Goal:** Add coach role, team workouts, social feed. Web dashboard for coaches.

**Depends on:** Phase 1 (training infrastructure)

### Blocks

1. **Coach Role** -- coach accounts, coach-athlete relationship
2. **Program Assignment** -- coach creates and assigns programs to athletes
3. **Athlete Monitoring** -- coach views athlete's sessions, progress, recovery
4. **Team Workouts** -- shared sessions for group training
5. **Social Feed** -- activity feed, workout sharing, comments
6. **Web Dashboard** -- React + Vite app for coaches (session review, athlete management)
7. **Messaging** -- in-app messaging between coach and athlete

### Key decisions
- Web app is coach-focused (athlete experience stays mobile)
- Introduce Node.js API + PostgreSQL (Supabase) for social features
- Firebase Auth remains the identity provider
- Coach-athlete relationship is per-user (not per-session like Way2Fly)

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
Month:  1    2    3    4    5    6    7    8    9    10   11   12
        ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
Phase 1 ████████████████████                                      Training MVP
Phase 6      ░░░░░░░░░░░░░░████                                  Distribution
Phase 2                     ████████████████                      AI Assessment
Phase 3                     ████████████████                      Nutrition
Phase 5                     ████████████████████                  Social & Coaching
Phase 4                                     ████████████          Smart Recovery

████ = primary development
░░░░ = setup/overlap work (CI/CD, store accounts)
```

**Notes:**
- Phases 2, 3, and 5 can run in parallel after Phase 1 (with sufficient team capacity)
- Phase 4 starts after Phase 3 is feature-complete (needs nutrition data)
- Phase 6 setup begins during Phase 1; full push after Phase 1 ships
- Timeline assumes a small team (1-2 developers); parallel phases require more capacity
- Each phase includes testing, polish, and documentation as part of the estimate

---

## Success Metrics (per Phase)

| Phase | Key Metric | Target |
|---|---|---|
| Phase 1 | Users can complete a full training week | 100% of core flows working, zero critical bugs |
| Phase 2 | AI assessment accuracy | >80% agreement with manual assessment on test set |
| Phase 3 | Nutrition plan adherence | Users log >3 meals/day on average |
| Phase 4 | Recovery score correlation | Recovery score predicts next-session performance within 15% |
| Phase 5 | Coach adoption | >50% of coaches use web dashboard weekly |
| Phase 6 | App Store approval | First-submission approval on both stores |
