# Phase 3 — Advanced Nutrition: Implementation Checklist

> **Depends on:** Phase 1 (User system, profile, nutrition MVP with meals + stomach tracking)
> **Can run parallel with:** Phase 2, Phase 5
> **Blocks:** Phase 4 (partially — recovery score uses full nutrition data)

**Status: Not started (2026-03-31). Block 1 is explicitly deferred. Start with Block 0, then Block 2.**

### Recommended start order
1. **Block 0** (Cloud STT) — app-wide improvement, no deps, start immediately in parallel with Phase 4 Blocks 2–3
2. **Block 2** (Meal tracking macro upgrade) — core nutrition work, depends only on Phase 1
3. **Block 3** (Macro targets) — depends on Block 2
4. **Block 4** (Dashboard) — depends on Block 3
5. **Block 5** (Meal planning) — depends on Block 4
6. Skip **Block 1** (Photo food recognition) — marked "not for now"

---

## Block 0 — Cloud Speech-to-Text Upgrade ← START HERE (parallel with Phase 4 Blocks 2–3)

> **Note: This block is app-wide, not nutrition-specific.** Cloud STT improves all voice features (journaling, session logging, meal logging, bedtime summary). It is placed here because Phase 3 benefits most from improved accuracy (food name recognition), but it could be started independently after Phase 1 without waiting for other Phase 3 blocks.

- [x] Evaluate cloud STT APIs (Google Cloud Speech-to-Text, Whisper API, Deepgram)
- [x] Set up API integration via Cloud Function proxy (keep API keys server-side)
- [x] Replace device speech_to_text with cloud API for all voice features app-wide
- [x] Maintain device STT as offline fallback
- [ ] A/B comparison: measure accuracy improvement over device STT
- [x] Tests: unit tests for cloud STT integration

### Implementation notes for next AI
- Current STT: `speech_to_text` Flutter package used in journal, session logging, and meal logging — find all usages with `grep -r "speech_to_text\|SpeechToText" lib/`
- Recommended API: **OpenAI Whisper** (best accuracy, simple API, cheap) or **Google Cloud Speech-to-Text v2** (good for food names specifically)
- Pattern: create `CloudSttService` abstract interface + `WhisperSttService` implementation + `DeviceSttService` fallback (existing); choose via feature flag (Firebase Remote Config)
- Cloud Function proxy at `backend/functions/src/stt/transcribeAudio.ts` — callable function; client sends base64 audio, function calls Whisper API with API key stored in Firebase Functions config, returns transcript
- Audio format: the `speech_to_text` package records in WAV/PCM; Whisper accepts mp3/wav/m4a/webm — WAV is fine
- Keep device STT as fallback: if cloud call fails or device is offline, fall back to `speech_to_text` package

---

## Block 1 — External AI API Setup & Photo Food Recognition ⛔ DEFERRED — skip entirely

- [ ] Evaluate food recognition APIs (Google Cloud Vision, Clarifai, LogMeal, or similar)
- [ ] Set up API integration via Cloud Function proxy (keep API keys server-side)
- [ ] Define FoodRecognitionResult model (food items, estimated portions, confidence scores, macros)
- [ ] Camera integration for meal photo capture
- [ ] Send photo to recognition API via callable Cloud Function
- [ ] Display recognized food items with confidence, portion estimates, and macros
- [ ] Allow user to confirm, edit, or reject each recognized item
- [ ] Gallery picker as alternative to camera
- [ ] Implement fallback for low-confidence results (manual entry prompt)
- [ ] Tests: unit tests for API response parsing
- [ ] Tests: widget tests for photo capture and review flow

---

## Block 2 — Full Meal Tracking (Macro Upgrade) ← START AFTER Block 0

- [x] Upgrade Meal entity: add calories, protein, carbs, fat, foodItems array
- [x] Domain: FoodItem entity (name, portion, calories, protein, carbs, fat)
- [x] Upgrade MealRepository with macro-aware methods
- [x] Food database search (external API or open-source nutritional data)
- [x] Presentation: MealEntryPage upgrade — photo or manual entry, edit items with macros, set meal type
- [x] Presentation: DailyMealsView upgrade — list all meals with running macro totals
- [x] Manual food search and entry (text-based lookup from food database)
- [x] Carry forward stomach feeling tracking from Phase 1 nutrition MVP
- [x] Tests: unit tests for upgraded use cases, widget tests for meal entry

### Implementation notes for next AI
- Existing meal code: `lib/features/nutrition/` — read this first before touching anything
- Existing `Meal` entity at `lib/features/nutrition/domain/entities/meal.dart` — upgrade it; add `foodItems: List<FoodItem>`, `calories`, `protein`, `carbs`, `fat` (nullable initially for backwards compat)
- Food database: use **Open Food Facts** (free, open-source, no API key needed) — REST API at `https://world.openfoodfacts.org/cgi/search.pl?search_terms={query}&json=1`
- Create `FoodDatabaseService` that queries Open Food Facts and maps results to `FoodItem` entities
- `MealEntryPage` upgrade: keep existing stomach feeling slider; add food search field at top; each added food item shows name + macros + portion size (editable)
- Backwards compatibility: existing meals without `foodItems` should still display (show "No items tracked" gracefully)

---

## Block 3 — Macro Targets ← AFTER Block 2

- [x] Calculate daily calorie target from user profile (age, weight, height, activity level, goal)
- [x] Calculate macro split (protein/carbs/fat) based on training goal
- [x] Domain: NutritionTarget entity and NutritionTargetRepository
- [x] Presentation: NutritionTargetSettingsPage (view/edit targets, select goal preset)
- [x] Adjust targets on training vs rest days
- [x] Tests: unit tests for calculation formulas

### Implementation notes for next AI
- TDEE formula: BMR (Mifflin-St Jeor) × activity multiplier — inputs from `UserProfile` (age, weight, height, activityLevel)
- Check `UserProfile` entity at `lib/features/profile/domain/entities/user_profile.dart` — may already have some of these fields
- Macro split presets: Fat loss (40% protein, 30% carbs, 30% fat), Maintenance (30/40/30), Muscle gain (30/50/20)
- Training day adjustment: +10–15% calories on training days, −10% on rest days
- Firestore collection: `nutritionTargets/{userId}` — single document per user
- **After this block is done**: trigger Phase 4b upgrade — update `RecoveryService` to include `nutritionAdherenceComponent` (actual macros vs targets) and rebalance weights per the Phase 4b formula

---

## Block 4 — Daily/Weekly Nutrition Dashboard ✅

- [x] Daily view: macro ring charts (protein, carbs, fat vs targets), calorie bar, stomach feeling trend
- [x] Weekly view: average daily intake, consistency score, trend lines
- [x] Stomach-food correlation view: highlight foods that correlate with poor stomach ratings
- [x] Meal history list with quick-add from previous meals
- [x] Streak tracking for logging consistency
- [x] Tests: widget tests for dashboard components

### What was implemented (2026-03-31)
- `DailyNutritionSummary` entity for per-day macro aggregation
- `StomachFoodCorrelation` entity for food-stomach analysis
- Three new use cases: `GetWeeklyNutritionSummary`, `GetStomachFoodCorrelations`, `GetLoggingStreak` — all with unit tests (13 tests)
- `getMealsByDateRange` added to `MealRepository` interface + Firestore implementation
- Upgraded `DailyNutritionPage` summary card: calorie progress bar, 3 animated macro ring charts (fl_chart PieChart), streak fire badge, stomach feeling emoji
- New `NutritionDashboardPage` at `/nutrition/dashboard` with 4 sections: weekly calorie bar chart with target line, consistency stats (days logged + streak), stomach-food correlation list, meal history quick-add
- Reusable widgets: `MacroRingChart`, `CalorieProgressBar`, `WeeklyNutritionChart`, `StomachCorrelationList`, `MealHistoryQuickAdd`
- Riverpod providers: `weeklyNutritionProvider`, `stomachCorrelationsProvider`, `loggingStreakProvider`
- Widget tests for dashboard page, macro ring chart, calorie bar, correlation list (8 tests)
- `fl_chart: ^0.69.0` added as dependency

---

## Block 5 — Meal Planning

- [ ] Create meal plans for upcoming days/weeks
- [ ] Copy meals from previous days
- [ ] Grocery list generation from planned meals
- [ ] Meal plan templates (save and reuse weekly plans)
- [ ] Tests: widget tests for meal planning flow
