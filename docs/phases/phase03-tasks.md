# Phase 3 — Advanced Nutrition: Implementation Checklist

> **Depends on:** Phase 1 (User system, profile, nutrition MVP with meals + stomach tracking)
> **Can run parallel with:** Phase 2, Phase 5
> **Blocks:** Phase 4 (partially — recovery score uses full nutrition data)

---

## Block 0 — Cloud Speech-to-Text Upgrade

- [ ] Evaluate cloud STT APIs (Google Cloud Speech-to-Text, Whisper API, Deepgram)
- [ ] Set up API integration via Cloud Function proxy (keep API keys server-side)
- [ ] Replace device speech_to_text with cloud API for all voice features app-wide
- [ ] Maintain device STT as offline fallback
- [ ] A/B comparison: measure accuracy improvement over device STT
- [ ] Tests: unit tests for cloud STT integration

---

## Block 1 — External AI API Setup & Photo Food Recognition not for now

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

## Block 2 — Full Meal Tracking (Macro Upgrade)

- [ ] Upgrade Meal entity: add calories, protein, carbs, fat, foodItems array
- [ ] Domain: FoodItem entity (name, portion, calories, protein, carbs, fat)
- [ ] Upgrade MealRepository with macro-aware methods
- [ ] Food database search (external API or open-source nutritional data)
- [ ] Presentation: MealEntryPage upgrade — photo or manual entry, edit items with macros, set meal type
- [ ] Presentation: DailyMealsView upgrade — list all meals with running macro totals
- [ ] Manual food search and entry (text-based lookup from food database)
- [ ] Carry forward stomach feeling tracking from Phase 1 nutrition MVP
- [ ] Tests: unit tests for upgraded use cases, widget tests for meal entry

---

## Block 3 — Macro Targets

- [ ] Calculate daily calorie target from user profile (age, weight, height, activity level, goal)
- [ ] Calculate macro split (protein/carbs/fat) based on training goal
- [ ] Domain: NutritionTarget entity and NutritionTargetRepository
- [ ] Presentation: NutritionTargetSettingsPage (view/edit targets, select goal preset)
- [ ] Adjust targets on training vs rest days
- [ ] Tests: unit tests for calculation formulas

---

## Block 4 — Daily/Weekly Nutrition Dashboard

- [ ] Daily view: macro ring charts (protein, carbs, fat vs targets), calorie bar, stomach feeling trend
- [ ] Weekly view: average daily intake, consistency score, trend lines
- [ ] Stomach-food correlation view: highlight foods that correlate with poor stomach ratings
- [ ] Meal history list with quick-add from previous meals
- [ ] Streak tracking for logging consistency
- [ ] Tests: widget tests for dashboard components

---

## Block 5 — Meal Planning

- [ ] Create meal plans for upcoming days/weeks
- [ ] Copy meals from previous days
- [ ] Grocery list generation from planned meals
- [ ] Meal plan templates (save and reuse weekly plans)
- [ ] Tests: widget tests for meal planning flow
