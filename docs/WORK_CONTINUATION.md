# Work Continuation — Next Session Handoff

> Last updated: 2026-03-31
> Last commit: `6c0843f` — Phase 2 Blocks 4-5 + Phase 4 Blocks 0-1

---

## What was completed in this session

| Phase | Block | Description |
|---|---|---|
| Phase 2 | Block 4 | Before/After Comparison UI — `ReAssessmentComparisonPage`, `PoseLandmarkOverlay`, `MovementScoreChart`, `CompensationImprovementCard`, `SideBySideVideoPlayer` |
| Phase 2 | Block 5 | Re-assessment scheduling, `AssessmentTimelinePage`, FCM notifications, `onAssessmentComplete` + `sendReAssessmentReminders` Cloud Functions |
| Phase 4 | Block 0 | Recovery Score engine — `RecoveryService` formula, `RecoveryScore` entity, nightly Cloud Function `calculateNightlyRecoveryScores` |
| Phase 4 | Block 1 | Training recommendations — `RecoveryBanner` on home dashboard, `RecoveryDetailPage` at `/recovery` |

**Phase 2 is now 100% complete** (all blocks done, 0 remaining tasks).

---

## What remains — priority order

### 1. Phase 4 — Smart Recovery (14 tasks remaining)

**Block 2 — Wearable Integration** *(can start immediately)*
- `WearableDataSource` abstract interface (over HealthKit + Garmin)
- Apple Watch / HealthKit integration: sleep, HRV, resting HR, activity
- Garmin Connect API integration: sleep, body battery, stress
- Pull wearable data into recovery score components
- `WearableConnectionPage` at `/settings/wearables`
- Handle missing wearable data gracefully (score still works without it)
- Tests: unit tests for wearable data normalization

**Block 3 — Recovery Trends Dashboard** *(can start immediately, parallel with Block 2)*
- Recovery score trend chart (7-day, 30-day, 90-day) — add to `RecoveryDetailPage` or new page
- Correlation view: overlay recovery score with training volume + sleep quality
- Weekly recovery summary (avg score, best/worst days, key factors)
- CSV export or share-as-image
- Widget tests for trend charts

---

### 2. Phase 3 — Advanced Nutrition (43 tasks remaining)

**Block 0 — Cloud STT Upgrade** *(app-wide, no dependencies, start anytime)*
- Evaluate cloud STT APIs (Google Cloud Speech-to-Text, Whisper, Deepgram)
- Cloud Function proxy (keep API key server-side)
- Replace `speech_to_text` device package with cloud API for all voice features
- Keep device STT as offline fallback
- Tests for cloud STT integration

**Block 2 — Full Meal Tracking (Macro Upgrade)** *(depends on Phase 1 only — already done)*
- Upgrade `Meal` entity: add `calories`, `protein`, `carbs`, `fat`, `foodItems: List<FoodItem>`
- `FoodItem` entity (name, portion, calories, protein, carbs, fat)
- Upgrade `MealRepository` with macro-aware methods
- Food database search (Open Food Facts API or similar open-source)
- `MealEntryPage` upgrade — photo or manual entry, edit items with macros, meal type
- `DailyMealsView` upgrade — running macro totals
- Tests

**Block 3 — Macro Targets** *(depends on Block 2)*
- Calculate daily calorie target from user profile (TDEE formula)
- Macro split based on training goal
- `NutritionTarget` entity + `NutritionTargetRepository`
- `NutritionTargetSettingsPage`
- Adjust targets on training vs rest days

**Block 4 — Daily/Weekly Nutrition Dashboard** *(depends on Block 3)*
- Daily view: macro ring charts, calorie bar, stomach feeling trend
- Weekly view: average intake, consistency score, trend lines
- Stomach–food correlation view
- Meal history with quick-add from previous meals
- Streak tracking for logging consistency

**Block 5 — Meal Planning** *(depends on Block 4)*
- Create meal plans for upcoming days/weeks
- Copy meals from previous days
- Grocery list generation
- Meal plan templates

> **Block 1 (Photo Food Recognition)** is marked "not for now" — skip it.

---

### 3. Phase 5 — Social & Coaching (27 tasks remaining)

> Blocks 0–3 are marked "not for now". Only **Block 4** is active:

**Block 4 — Progress Sharing** *(can start anytime after Phase 1 — already done)*
- Generate progress report (assessment improvements, consistency stats, program completion)
- Share progress report as image card or PDF
- Coach can view athlete progress timeline *(skip if coach role deferred)*
- Opt-in leaderboards: consistency streaks, sessions completed
- Widget tests for progress report generation

---

### 4. Phase 6 — Deployment & Distribution (49 tasks remaining)

> Can run in parallel with everything. Non-code steps are marked.

**Block 0 — App Store + Play Accounts** *(manual/external — no code)*
- Create Apple Developer account
- Create Google Play Developer account
- Set up App Store Connect + Google Play Console app entries
- Configure signing keys (Android keystore, iOS certs + provisioning profiles)

**Block 1 — App Identity** *(code)*
- Design + export app icon (1024×1024, all sizes)
- Adaptive icon for Android (foreground + background layers)
- Splash screen via `flutter_native_splash`
- Set bundle ID `com.way2move.app`, app display name
- Configure iOS launch screen storyboard

**Block 2 — Production Firebase** *(code + config)*
- Create production Firebase project (separate from dev)
- Configure Auth providers (email, Google, Apple) for production
- Deploy Firestore security rules + indexes to production
- Deploy all Cloud Functions to production
- Run seed script against production Firestore
- Set up Firebase Crashlytics for production
- Environment-based Firebase config switching (dev vs prod)

**Block 3 — Privacy Policy + ToS** *(writing/external)*
- Draft privacy policy + terms of service
- Host at public URL (Firebase Hosting or GitHub Pages)
- Add links in app settings + sign-up flow
- GDPR compliance (data export, account deletion)

**Block 4 — Store Listings** *(writing/design)*
- App Store + Google Play descriptions (short + long)
- Screenshots (6.7", 6.5", 5.5", phone + tablet)
- Feature graphic for Google Play (1024×500)
- Category, keywords for ASO
- Preview video (optional)

**Block 5 — Test Builds** *(CI/CD code)*
- Codemagic for iOS builds + TestFlight upload
- GitHub Actions for Android signed APK/AAB
- Internal Testing on Google Play
- First test build to internal testers
- Sentry for error monitoring in test builds

**Block 6 — Freemium Model** *(code)*
- Define free tier limits + premium features
- Integrate RevenueCat for subscription management
- Paywall UI (shown on premium feature access)
- Configure subscription products in App Store Connect + Google Play
- Handle subscription status in app (entitlement checks, feature gating)
- Tests for entitlement checks

**Block 7 — Public Launch** *(manual)*
- Submit to App Store + Google Play review
- Address review feedback
- Phased rollout on Google Play (start 10%)
- Monitor crash-free rate post-launch
- Firebase Analytics for key events (sign_up, session_completed, program_created)

---

## Recommended parallel execution (next session)

Run these 3 in parallel (no conflicts):

| Agent | Work |
|---|---|
| **Agent A** | Phase 4 Block 2 (Wearable Integration — HealthKit + Garmin) |
| **Agent B** | Phase 4 Block 3 (Recovery Trends Dashboard) |
| **Agent C** | Phase 3 Block 0 (Cloud STT Upgrade) |

Then next wave:
| Agent | Work |
|---|---|
| **Agent A** | Phase 3 Blocks 2–3 (Full meal tracking + macro targets) |
| **Agent B** | Phase 5 Block 4 (Progress sharing) |
| **Agent C** | Phase 6 Block 1 (App identity — icon, splash, bundle ID) |

Then:
| Agent | Work |
|---|---|
| **Agent A** | Phase 3 Block 4 (Nutrition dashboard) |
| **Agent B** | Phase 6 Block 2 (Production Firebase config) |
| **Agent C** | Phase 6 Block 5 (CI/CD: Codemagic + GitHub Actions) |

Then:
| Agent | Work |
|---|---|
| **Agent A** | Phase 3 Block 5 (Meal planning) |
| **Agent B** | Phase 6 Block 6 (Freemium + RevenueCat) |
| **Agent C** | Phase 4 Block 2b (Phase 4b nutrition integration into recovery score, after Phase 3 is done) |

---

## Architecture reminders

- Flutter app: `frontend/mobile/` — Clean Architecture + Riverpod 2.x + GoRouter
- Cloud Functions: `backend/functions/src/` — TypeScript, exported from `index.ts`
- TDD always: write failing test first, then implementation
- Zero lint warnings before finishing: `flutter analyze && dart format .` from `frontend/mobile/`
- All screen transitions animated — no raw `MaterialPageRoute`
- Dispose all `AnimationController`s
- Firebase emulator for all tests (never hit real Firebase in tests)
- Phase 3 Block 1 (photo food recognition) is explicitly deferred — do not implement
- Phase 5 Blocks 0–3 (coach role, coach programs, workout sharing, community library) are explicitly deferred

## Key file locations

| What | Path |
|---|---|
| Route constants | `lib/core/router/routes.dart` |
| GoRouter definition | `lib/core/router/app_router.dart` |
| Home dashboard | `lib/features/dashboard/presentation/pages/home_page.dart` |
| Cloud Functions index | `backend/functions/src/index.ts` |
| Phase task files | `docs/phases/phase0X-tasks.md` |
| Recovery feature | `lib/features/recovery/` |
| Assessment feature | `lib/features/assessments/` |
