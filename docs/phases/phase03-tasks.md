# Phase 3 — Nutrition: Implementation Checklist

> **Depends on:** Phase 1 (User system, profile)
> **Can run parallel with:** Phase 2, Phase 5
> **Blocks:** Phase 4 (partially — recovery score uses nutrition data)

---

## Block 0 — External AI API Setup

- [ ] Evaluate food recognition APIs (Google Cloud Vision, Clarifai, LogMeal, or similar)
- [ ] Set up API integration via Cloud Function proxy (keep API keys server-side)
- [ ] Define FoodRecognitionResult model (food items, estimated portions, confidence scores)
- [ ] Implement fallback for low-confidence results (manual entry prompt)
- [ ] Tests: unit tests for API response parsing

---

## Block 1 — Photo Capture and Food Recognition

- [ ] Camera integration for meal photo capture
- [ ] Send photo to recognition API via callable Cloud Function
- [ ] Display recognized food items with confidence and portion estimates
- [ ] Allow user to confirm, edit, or reject each recognized item
- [ ] Gallery picker as alternative to camera
- [ ] Tests: widget tests for photo capture and review flow

---

## Block 2 — Meal Tracking

- [ ] Domain: Meal entity (id, userId, date, mealType, items, photoUrl, totalMacros)
- [ ] Domain: FoodItem entity (name, portion, calories, protein, carbs, fat)
- [ ] Domain: MealRepository interface (create, update, delete, getByDate, getHistory)
- [ ] Data: MealModel, FirestoreMealDatasource, MealRepositoryImpl
- [ ] Presentation: MealEntryPage (photo or manual entry, edit items, set meal type)
- [ ] Presentation: DailyMealsView (list all meals for a day with running totals)
- [ ] Manual food search and entry (text-based lookup from food database)
- [ ] Tests: unit tests for use cases, widget tests for meal entry

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

- [ ] Daily view: macro ring charts (protein, carbs, fat vs targets), calorie bar
- [ ] Weekly view: average daily intake, consistency score, trend lines
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
