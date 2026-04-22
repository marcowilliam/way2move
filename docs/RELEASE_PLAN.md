# Way2Move — Release Plan

> **Purpose:** single source of truth for *what ships when*. Use this to decide what goes into each release, what hides behind a flag, and what's still cooking. Pairs with:
> - `docs/FEATURES.md` — full feature catalog (long descriptions, how to test in UI)
> - `docs/FEATURE_FLAGS_INVENTORY.md` — flag catalogue
> - `docs/phases/phase0X-tasks.md` — engineering task lists per phase
>
> **Last updated:** 2026-04-21

---

## Legend

| Status | Meaning |
|---|---|
| ✅ Shipped | Code complete, tested, in main. Ready for prod. |
| 🔧 Polish | Code works but needs UX revamp / minor bugs before v1.0. |
| 🚧 In progress | Actively being built. |
| 🧪 Prototype | Built but unpolished — hide behind flag in v1.0. |
| 📋 Planned | Not started. Scheduled for later release. |
| ⛔ Deferred | Explicitly not shipping (scope cut). |

| Flag state in v1.0 | Meaning |
|---|---|
| `ON` | Visible to all users in first release. |
| `OFF` | Hidden from all users; enable for internal / beta only. |
| `—` | Feature is always-on (no flag wrapping it). |

> ⚠️ **Reality check:** as of 2026-04-21, **no feature flags are actually wired in code yet**. The column below is the *target* for v1.0. Before v1.0 ships, each `OFF` feature must be wrapped in a `FeatureGate` reading from Firebase Remote Config. See `docs/FEATURE_FLAGS_INVENTORY.md`.

---

## Platform assignment

| Platform | Scope |
|---|---|
| **Mobile (Flutter)** | All Phase 1–4 features. The athlete-facing app. |
| **Web (React)** | Phase 5 only — coach dashboard. *Not scaffolded yet.* |

v1.0 is **mobile-only**. Web is post-v1.0.

---

## Master feature matrix

### Phase 1 — Training + Body Awareness MVP  *(98% done — 3 polish tasks pending)*

| # | Feature | Platform | Status | Flag in v1.0 | One-liner |
|---|---|---|---|---|---|
| 1 | Authentication | Mobile | ✅ Shipped | — | Email + Google + Apple sign-in via Firebase. |
| 2 | Exercise Library | Mobile | ✅ Shipped | — | 60+ PRI/DNS/mobility exercises, search + filter + custom. |
| 3 | Assessment System | Mobile | ✅ Shipped | — | Questionnaire detects compensations; weekly pulse check. |
| 4 | Programs | Mobile | ✅ Shipped | — | Auto-generated or hand-built weekly training templates. |
| 5 | Session Tracking | Mobile | ✅ Shipped | — | Log sets/reps/weight/RPE per exercise block. |
| 6 | Profile & Onboarding | Mobile | ✅ Shipped | — | 6-step onboarding; profile editor. |
| 7 | Compensation Profile | Mobile | ✅ Shipped | — | Body-map of active compensations with severity + history. |
| 8 | Goal System | Mobile | ✅ Shipped | — | Suggested + manual goals linked to compensations/exercises. |
| 9 | Journaling (voice-first) | Mobile | 🔧 Polish | `OFF` | Voice → text; auto-creates sessions/meals for review. STT quality is device-only for now — flag it until cloud STT (Phase 3 Block 0) lands. |
| 10 | Nutrition MVP | Mobile | 🔧 Polish | `OFF` | Meal log + stomach feeling. Flag until macro upgrade (Phase 3 Block 2) replaces it. |
| 11 | Sleep Logging | Mobile | ✅ Shipped | `OFF` (optional) | Bed/wake time, quality 1–5, history chart. Low-risk — can ship `ON` if you want. |
| 12 | Progress Photos & Weight | Mobile | ✅ Shipped | `OFF` (optional) | Guided photo capture + weight trends. Privacy-sensitive; consider flagging. |
| 13 | Auto-Progression | Mobile | ✅ Shipped | — | Recovery-aware rep/load/variation suggestions after sessions. |
| 14 | Calendar | Mobile | ✅ Shipped | `OFF` | Month/week view with session dots. Flag pending Google/Apple calendar sync polish. |
| 15 | Dashboard & Navigation | Mobile | 🔧 Polish | — | Home + bottom nav + profile. Part of revamp-v1 in-flight. |
| — | **UI revamp v1.1 (dark mode + brand)** | Mobile | 🚧 In progress | — | 20-screen dark-mode + token revamp. 5/20 migrated per last commit. Must complete before v1.0 for visual consistency. |

### Phase 2 — AI Movement Assessment  *(100% done — 53/53 tasks)*

| # | Feature | Platform | Status | Flag in v1.0 | One-liner |
|---|---|---|---|---|---|
| 16 | ML Pose Estimation (infrastructure) | Mobile | ✅ Shipped | — | On-device MediaPipe BlazePose, 33 landmarks per frame. |
| 17 | Video Analysis Pipeline | Mobile | ✅ Shipped | — | Record 5 screening movements, analyze on-device. |
| 18 | Compensation Detection from Video | Mobile | ✅ Shipped | — | Pose-based detection of knee valgus, rounded shoulders, etc. |
| 19 | AI Program Recommendations | Mobile | ✅ Shipped | — | Rule-based engine generates personalized program from findings. |
| 20 | Before/After Comparison UI | Mobile | ✅ Shipped | — | Side-by-side video + radar chart of reassessment scores. |
| 21 | Re-Assessment Scheduling + Notifications | Mobile | ✅ Shipped | `OFF` | FCM push requires Phase 6 notification setup; keep off until notifications wired. |

### Phase 3 — Advanced Nutrition  *(60% done — 26/43 tasks)*

| # | Feature | Platform | Status | Flag in v1.0 | One-liner |
|---|---|---|---|---|---|
| 22 | Cloud STT upgrade | Mobile | ✅ Shipped | `OFF` (`feature_cloud_stt`) | Cloud Whisper/Deepgram for better voice accuracy; device STT as fallback. |
| 23 | Full Meal Tracking + Macros | Mobile | ✅ Shipped | `OFF` (`feature_nutrition`) | Calories/protein/carbs/fat + food DB search. Replaces Nutrition MVP. |
| 24 | Macro Targets | Mobile | ✅ Shipped | `OFF` (`feature_nutrition`) | Daily targets from profile; training-vs-rest-day adjustments. |
| 25 | Nutrition Dashboard | Mobile | ✅ Shipped | `OFF` (`feature_nutrition_dashboard`) | Macro rings, weekly trends, stomach-food correlation. |
| 26 | Meal Planning | Mobile | 📋 Planned | — | Plan upcoming meals, reuse weekly templates, grocery lists. |
| 27 | Photo Food Recognition | Mobile | ⛔ Deferred | — | AI camera-based meal logging. Explicitly cut from scope. |

### Phase 4 — Smart Recovery  *(44% done — 11/25 tasks)*

| # | Feature | Platform | Status | Flag in v1.0 | One-liner |
|---|---|---|---|---|---|
| 28 | Recovery Score | Mobile | ✅ Shipped | `OFF` (`feature_recovery`) | Nightly score from sleep + load + pulse + gut. |
| 29 | Training Adjustment Recommendations | Mobile | ✅ Shipped | `OFF` (`feature_recovery`) | Green/yellow/red zones trigger session modifications. |
| 30 | Wearable Integration (HealthKit, Garmin) | Mobile | 📋 Planned | — | Feed HRV / RHR / sleep into recovery score. |
| 31 | Recovery Trends Dashboard | Mobile | 📋 Planned | — | 7/30/90-day trend charts + correlations. |
| 32 | FCM Push Notifications | Mobile | 📋 Planned | `OFF` (`feature_notifications`) | Infrastructure for reassessment reminders etc. |

### Phase 5 — Social & Coaching  *(deferred except Block 4)*

| # | Feature | Platform | Status | Flag in v1.0 | One-liner |
|---|---|---|---|---|---|
| 33 | Coach Role & Permissions | Web + Mobile | ⛔ Deferred | — | Coach-athlete invite + dashboard. Not in this cycle. |
| 34 | Coach Creates Programs | Web + Mobile | ⛔ Deferred | — | Coach edits athlete programs. Not in this cycle. |
| 35 | Sharing Workouts & Programs | Mobile | ⛔ Deferred | — | Share cards + deep links. Not in this cycle. |
| 36 | Community Exercise Library | Mobile | ⛔ Deferred | — | User-submitted exercises with moderation. Not in this cycle. |
| 37 | Progress Sharing | Mobile | 📋 Planned | — | Export report image/PDF. Only active Phase 5 block. |

### Phase 6 — Deployment & Distribution  *(0% — all remaining)*

| # | Feature | Platform | Status | Flag in v1.0 | One-liner |
|---|---|---|---|---|---|
| 38 | Developer accounts (Apple/Google) | — | 📋 Planned | — | Paid accounts, signing keys, bundle IDs. **Blocks v1.0.** |
| 39 | App identity (icon, splash, name) | Mobile | 📋 Planned | — | Final icon + adaptive icon + splash. **Blocks v1.0.** |
| 40 | Production Firebase project | — | 📋 Planned | — | Separate prod project, rules deploy, Crashlytics. **Blocks v1.0.** |
| 41 | Privacy Policy + ToS | — | 📋 Planned | — | GDPR-compliant policy, account deletion. **Blocks v1.0.** |
| 42 | Store listings | — | 📋 Planned | — | Screenshots, descriptions, ASO. **Blocks v1.0.** |
| 43 | Test builds (TestFlight, Play internal) | Mobile | 🚧 In progress | — | Codemagic pipeline scaffolded; see `ios-staging-codemagic` skill. |
| 44 | Freemium model / RevenueCat | Mobile | 📋 Planned | — | Paywall + subscription. Post-v1.0. |
| 45 | Public launch | — | 📋 Planned | — | App Store + Play submissions. |

---

## First release (v1.0) — recommended scope

**Goal:** ship the core training + body-awareness loop. Hide anything that isn't bulletproof.

### Include (flags `ON` or always-on)

- Auth · Exercise Library · Assessment · Programs · Sessions · Profile/Onboarding · Compensations · Goals · Auto-Progression · Dashboard
- All of Phase 2 AI Assessment (except reassessment notifications — needs FCM setup)
- Sleep logging (optional — low risk)

### Hide (flags `OFF`)

- Journaling — voice quality is inconsistent until cloud STT is enabled in prod
- Nutrition (MVP and macro upgrade) — behavior overlap; pick one after testing
- Nutrition dashboard — depends on nutrition being on
- Calendar — external sync polish pending
- Recovery score + training adjustments — needs more data collection period to be meaningful
- Progress photos — privacy-sensitive; want explicit opt-in UX first
- Notifications — depends on Phase 6 FCM wiring
- Reassessment scheduling (depends on notifications)

### Blocks v1.0 ship (Phase 6 work that must land)

1. Apple + Google developer accounts
2. Final app identity (icon, name, bundle IDs)
3. Production Firebase project
4. Privacy policy + ToS
5. Store listing assets
6. UI revamp-v1.1 dark mode rollout — finish the remaining 15 screens

---

## v1.1 — candidates (next release after v1.0)

Unflagging happens here once each feature has been observed in prod through the flag:

1. Sleep logging (if not already ON in v1.0)
2. Nutrition + Nutrition dashboard (cutover: turn OFF MVP, turn ON macro upgrade at the same time)
3. Cloud STT + Journaling (pair them — cloud STT must be on first)
4. Recovery score + adjustment recommendations
5. FCM notifications + reassessment scheduling
6. Calendar (after Google/Apple sync polish)
7. Progress photos (after privacy UX review)

---

## v1.2+ / future

- **Meal Planning** (Phase 3 Block 5) — the last Phase 3 feature.
- **Wearable integration + Recovery trends** (Phase 4 Blocks 2–3) — unlocks the "smart" in Smart Recovery.
- **Progress Sharing** (Phase 5 Block 4) — only active Phase 5 item.
- **Freemium / RevenueCat** (Phase 6 Block 6) — monetisation.
- **Web coach dashboard + coaching flows** (Phase 5 Blocks 0–3) — requires scaffolding `frontend/web/` and committing to the coach role. Currently deferred.

Explicitly **not** planned:
- Photo Food Recognition (Phase 3 Block 1) — cut from scope.
- Community Exercise Library (Phase 5 Block 3) — cut from scope.

---

## Maintenance & ongoing work

| Area | Notes |
|---|---|
| Brand revamp v1.1 | Dark mode + token system. 5/20 screens migrated (commit `264889c`). Finish before v1.0. |
| Feature flags wiring | **Not yet implemented.** Must land `FeatureGate` + Remote Config before v1.0 so the `OFF` column above is real. |
| Test coverage | Phase 1: 582 tests. Phase 2: 92 tests. Keep pre-push running unit + integration. |
| Observability | Sentry initialized. Add Crashlytics when production Firebase project lands. |
| CI/CD | GitHub Actions (Android + web + functions). Codemagic (iOS → TestFlight). |

---

## How to keep this doc alive

- **When a feature moves status** (e.g. 🚧 → ✅), update the row and the `Last updated` date at the top.
- **When you decide a flag state** for a release, update the `Flag in v1.0` column (or add a `Flag in v1.1` column as releases approach).
- **When scope changes** (deferral, new feature), update both this doc and `docs/FEATURES.md`.
- **When a phase task file gets tasks checked off**, reflect the % in the phase header here.
- Rename this file to `RELEASE_PLAN_v1.md` and start a fresh one for each major release if it gets too long.
