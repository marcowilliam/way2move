# Phase 4 — Smart Recovery: Implementation Checklist

> **Phase 4a depends on:** Phase 1 only (sleep logging, sessions, weekly pulse, stomach feeling)
> **Phase 4b depends on:** Phase 3 (full nutrition data — caloric deficit/surplus, macro adherence)
> **Can run parallel with:** Phase 2, Phase 3, Phase 5 (Phase 4a starts after Phase 1)
> **Blocks:** nothing

**Status: Blocks 0 and 1 complete (2026-03-31). Blocks 2 and 3 are next.**

Phase 4 is split into two stages:
- **Phase 4a** — Recovery Score v1 using Phase 1 data. Can start immediately after Phase 1 without waiting for Phase 3. Uses sleep quality (30%), training load (40%), weekly pulse (20%), and gut feeling (10%).
- **Phase 4b** — Enhanced Recovery Score. Adds caloric deficit/surplus, macro adherence, and hydration from Phase 3. Rebalances weights: sleep (25%), training load (35%), nutrition adherence (20%), weekly pulse (10%), gut feeling (10%).

---

## Block 0 — Recovery Score Calculation (Phase 4a — no Phase 3 dependency) ✅

- [x] Domain: RecoveryScore entity (id, userId, date, score, components, recommendation)
- [x] Define recovery score v1 formula: sleep quality (30%) + training load trend (40%) + weekly pulse composite (20%) + stomach/gut feeling (10%)
- [x] Domain: RecoveryService (calculateDailyScore, getTrend)
- [x] Cloud Function: nightly recovery score calculation (scheduled trigger)
- [x] Store daily recovery scores in Firestore
- [x] Tests: unit tests for scoring formula with various input combinations
- [ ] **Phase 4b upgrade:** add nutrition adherence component, rebalance weights when Phase 3 data is available *(do this after Phase 3 Block 3 is complete)*

### What was implemented (2026-03-31)
- `RecoveryScore` entity with `RecoveryScoreComponents` (sleepComponent, trainingLoadComponent, weeklyPulseComponent, gutFeelingComponent) and `RecoveryZone` enum (green/yellow/red)
- `RecoveryRecommendation` entity with `SuggestedSessionType`
- `RecoveryService` — pure Dart static service at `lib/features/recovery/domain/services/recovery_service.dart`
  - Sleep component: averages quality of last 3 sleep sessions (quality 1–5 → 0–100%)
  - Training load: compares last 3 days vs 7-day average; recovery score improves when load is decreasing
  - Weekly pulse: averages energy + (100 − soreness) + motivation + sleep from `WeeklyPulseEntry`
  - Gut feeling: averages stomach feeling from `NutritionEntry` (1–5 → 0–100%)
- `calculateNightlyRecoveryScores` — scheduled Cloud Function at 2 AM daily; writes to `recoveryScores/{userId}/daily/{date}` and updates `users/{userId}.todayRecoveryScore`
- Firestore collection: `recoveryScores/{userId}/daily/{YYYY-MM-DD}`
- 25 Flutter unit tests + 20 TypeScript unit tests

---

## Block 1 — Training Adjustment Recommendations (Phase 4a) ✅

- [x] Map recovery score ranges to training intensity recommendations (green/yellow/red zones)
- [x] Auto-suggest session modifications when recovery is low (reduce volume, swap to mobility, take rest day)
- [ ] Integrate with auto-progression system (Phase 1 Block 8) — recovery overrides progression *(deferred — do after wearables, low priority)*
- [x] Presentation: RecoveryBanner on home dashboard with today's score and recommendation
- [x] Presentation: RecoveryDetailPage (score breakdown, contributing factors)
- [x] Tests: unit tests for recommendation logic

### What was implemented (2026-03-31)
- Score zones: green (75–100) / yellow (50–74) / red (0–49)
- `GenerateRecoveryRecommendation` use case — maps zone to headline + detail + `SuggestedSessionType`
- `RecoveryBanner` widget at `lib/features/recovery/presentation/widgets/recovery_banner.dart` — animated score counter, zone color chip, tap → RecoveryDetailPage; wired into home dashboard
- `RecoveryDetailPage` at `/recovery` — animated ring, 4-component breakdown with animated bars, recommendation card, 7-day sparkline, slide-in transition
- Riverpod providers: `todayRecoveryScoreProvider`, `recoveryTrendProvider`, `recoveryRecommendationProvider` at `lib/features/recovery/presentation/providers/recovery_providers.dart`

---

## Block 2 — Wearable Integration (Phase 4a) ← NEXT

- [ ] Apple Watch: HealthKit integration (sleep, HRV, resting HR, activity)
- [ ] Garmin: Garmin Connect API integration (sleep, body battery, stress)
- [ ] Domain: `WearableDataSource` abstract interface (unifies both providers)
- [ ] Pull wearable data into recovery score calculation as additional inputs
- [ ] Presentation: `WearableConnectionPage` at `/settings/wearables` (connect/disconnect, sync status)
- [ ] Handle missing wearable data gracefully (recovery score still works without it)
- [ ] Tests: unit tests for wearable data normalization

### Implementation notes for next AI
- Use `health` Flutter package (pub.dev) — wraps both HealthKit (iOS) and Health Connect (Android); no separate Garmin SDK needed at this level
- Garmin Connect sync happens through HealthKit/Health Connect on device — no direct Garmin API integration needed unless we want web-based OAuth
- `WearableDataSource` interface should mirror `RecoveryScoreComponents` inputs: provide sleep duration, HRV, resting HR, body battery (Garmin)
- `RecoveryService` already accepts optional wearable inputs — just wire the new datasource in
- `WearableConnectionPage` needs platform permission requests (HealthKit entitlement on iOS, Health Connect permissions on Android)
- Android: add `com.google.android.gms.permission.HEALTH` and Health Connect permissions to `AndroidManifest.xml`
- iOS: add `NSHealthShareUsageDescription` to `Info.plist`, enable HealthKit capability in Xcode

---

## Block 3 — Recovery Trends Dashboard (Phase 4a) ← NEXT (parallel with Block 2)

- [ ] Recovery score trend chart (7-day, 30-day, 90-day) — add as a new section on `RecoveryDetailPage` or a separate `RecoveryTrendsPage`
- [ ] Correlation view: overlay recovery score with training volume and sleep quality on the same chart
- [ ] Weekly recovery summary (average score, best/worst days, key factors)
- [ ] Export recovery data (CSV or share as image)
- [ ] Tests: widget tests for trend charts and summary

### Implementation notes for next AI
- `recoveryTrendProvider` already exists in `lib/features/recovery/presentation/providers/recovery_providers.dart` — fetches last N days of `RecoveryScore` from Firestore subcollection `recoveryScores/{userId}/daily/`
- Use `fl_chart` package for line charts (already likely in pubspec — check first; add if not)
- For the correlation view, fetch training sessions and sleep sessions in the same date range and plot on a shared time axis
- Weekly summary: group `RecoveryScore` documents by week, compute avg/min/max, identify dominant contributing factor per week
- CSV export: use `csv` package; share via `share_plus`; image export: use `RepaintBoundary` + `RenderRepaintBoundary.toImage()`
