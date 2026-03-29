# Phase 4 — Smart Recovery: Implementation Checklist

> **Depends on:** Phase 1 (Sleep logging, sessions), Phase 3 (Nutrition data)
> **Can run parallel with:** Phase 5
> **Blocks:** nothing

---

## Block 0 — Recovery Score Calculation

- [ ] Domain: RecoveryScore entity (id, userId, date, score, components, recommendation)
- [ ] Define recovery score formula: weighted composite of sleep quality, training load, nutrition adherence, weekly pulse data
- [ ] Domain: RecoveryService (calculateDailyScore, getTrend)
- [ ] Cloud Function: nightly recovery score calculation (scheduled trigger)
- [ ] Store daily recovery scores in Firestore
- [ ] Tests: unit tests for scoring formula with various input combinations

---

## Block 1 — Training Adjustment Recommendations

- [ ] Map recovery score ranges to training intensity recommendations (green/yellow/red zones)
- [ ] Auto-suggest session modifications when recovery is low (reduce volume, swap to mobility, take rest day)
- [ ] Integrate with auto-progression system (Phase 1 Block 8) — recovery overrides progression
- [ ] Presentation: RecoveryBanner on home dashboard with today's score and recommendation
- [ ] Presentation: RecoveryDetailPage (score breakdown, contributing factors)
- [ ] Tests: unit tests for recommendation logic

---

## Block 2 — Wearable Integration

- [ ] Apple Watch: HealthKit integration (sleep, HRV, resting HR, activity)
- [ ] Garmin: Garmin Connect API integration (sleep, body battery, stress)
- [ ] Domain: WearableDataSource interface (abstract over providers)
- [ ] Pull wearable data into recovery score calculation as additional inputs
- [ ] Presentation: WearableConnectionPage (connect/disconnect, sync status)
- [ ] Handle missing wearable data gracefully (score still works without it)
- [ ] Tests: unit tests for wearable data normalization

---

## Block 3 — Recovery Trends Dashboard

- [ ] Recovery score trend chart (7-day, 30-day, 90-day)
- [ ] Correlation view: overlay recovery score with training volume and sleep quality
- [ ] Weekly recovery summary (average score, best/worst days, key factors)
- [ ] Export recovery data (CSV or share as image)
- [ ] Tests: widget tests for trend charts and summary
