# Phase 4 — Smart Recovery: Implementation Checklist

> **Phase 4a depends on:** Phase 1 only (sleep logging, sessions, weekly pulse, stomach feeling)
> **Phase 4b depends on:** Phase 3 (full nutrition data — caloric deficit/surplus, macro adherence)
> **Can run parallel with:** Phase 2, Phase 3, Phase 5 (Phase 4a starts after Phase 1)
> **Blocks:** nothing

Phase 4 is split into two stages:
- **Phase 4a** — Recovery Score v1 using Phase 1 data. Can start immediately after Phase 1 without waiting for Phase 3. Uses sleep quality (30%), training load (40%), weekly pulse (20%), and gut feeling (10%).
- **Phase 4b** — Enhanced Recovery Score. Adds caloric deficit/surplus, macro adherence, and hydration from Phase 3. Rebalances weights: sleep (25%), training load (35%), nutrition adherence (20%), weekly pulse (10%), gut feeling (10%).

---

## Block 0 — Recovery Score Calculation (Phase 4a — no Phase 3 dependency)

- [ ] Domain: RecoveryScore entity (id, userId, date, score, components, recommendation)
- [ ] Define recovery score v1 formula: sleep quality (30%) + training load trend (40%) + weekly pulse composite (20%) + stomach/gut feeling (10%)
- [ ] Domain: RecoveryService (calculateDailyScore, getTrend)
- [ ] Cloud Function: nightly recovery score calculation (scheduled trigger)
- [ ] Store daily recovery scores in Firestore
- [ ] Tests: unit tests for scoring formula with various input combinations
- [ ] **Phase 4b upgrade:** add nutrition adherence component, rebalance weights when Phase 3 data is available

---

## Block 1 — Training Adjustment Recommendations (Phase 4a)

- [ ] Map recovery score ranges to training intensity recommendations (green/yellow/red zones)
- [ ] Auto-suggest session modifications when recovery is low (reduce volume, swap to mobility, take rest day)
- [ ] Integrate with auto-progression system (Phase 1 Block 8) — recovery overrides progression
- [ ] Presentation: RecoveryBanner on home dashboard with today's score and recommendation
- [ ] Presentation: RecoveryDetailPage (score breakdown, contributing factors)
- [ ] Tests: unit tests for recommendation logic

---

## Block 2 — Wearable Integration (Phase 4a)

- [ ] Apple Watch: HealthKit integration (sleep, HRV, resting HR, activity)
- [ ] Garmin: Garmin Connect API integration (sleep, body battery, stress)
- [ ] Domain: WearableDataSource interface (abstract over providers)
- [ ] Pull wearable data into recovery score calculation as additional inputs
- [ ] Presentation: WearableConnectionPage (connect/disconnect, sync status)
- [ ] Handle missing wearable data gracefully (score still works without it)
- [ ] Tests: unit tests for wearable data normalization

---

## Block 3 — Recovery Trends Dashboard (Phase 4a)

- [ ] Recovery score trend chart (7-day, 30-day, 90-day)
- [ ] Correlation view: overlay recovery score with training volume and sleep quality
- [ ] Weekly recovery summary (average score, best/worst days, key factors)
- [ ] Export recovery data (CSV or share as image)
- [ ] Tests: widget tests for trend charts and summary
