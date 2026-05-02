# Daily Logging — Spec (Phase B6)

**Scope:** Journal Entry, Meal Log, Sleep Log Entry — the three single-purpose logging forms users hit daily.
Each shares a common shape (form fields + a save CTA + SnackBar feedback) but differs in inputs and downstream behavior.
**Not in scope:** Journal History, Review Auto-Created (downstream of journal save), Nutrition Dashboard, Stomach Pattern, Sleep History.

**Source files:**

- Journal Entry — `frontend/mobile/lib/features/journal/presentation/pages/journal_entry_page.dart` (400 lines)
- Meal Log — `frontend/mobile/lib/features/nutrition/presentation/pages/meal_log_page.dart` (885 lines)
- Sleep Log Entry — `frontend/mobile/lib/features/sleep/presentation/pages/sleep_log_entry_page.dart` (365 lines)
- Voice input widget (shared, journal & meal) — `frontend/mobile/lib/features/journal/presentation/widgets/voice_input_widget.dart`

---

## 1. User flows

### Journal Entry — happy path
1. Page constructed with optional `type` (default `general`) + optional `linkedSessionId`. Title and Fraunces italic prompt switch on `type` (`:57–72`).
2. User dictates via `VoiceInputWidget` → `_contentController.text` updates with the transcription. Audio file path captured separately to `_recordedAudioPath` (`:262–272`).
3. Optional fields: mood (5 emoji `GestureDetector`s with `AnimatedContainer` 200ms selection ring), energy (1–5 `Slider`), pain points (`FilterChip` multi-select from `_painPointOptions`).
4. Tap "Save entry" → `_save()`:
   - Empty content → SnackBar "Please add some content first." and return (`:76–80`).
   - If audio path present and userId resolves, attempt upload via `journalAudioStorageProvider`. Upload failure is **silently swallowed** (`:96–98`) — entry saves without `audioUrl`.
   - Build `JournalEntry` with empty `id` and `userId` (Firestore replaces). Call `journalNotifierProvider.create()`.
   - On success: if `(type == postSession || eveningReflection || general) && content.length > 50`, run `EntityExtractionService` (sync) and check for sessions/meals/bodyMentions. If any extracted, push `Routes.reviewAutoCreated` with the parsed payload. Otherwise SnackBar "Journal saved!" and pop.
   - On failure: SnackBar "Failed to save journal entry." — no retry, no diagnostic.

### Meal Log — happy path
1. User selects `MealType` (breakfast/lunch/dinner/snack), feeling (1–5), and types a description.
2. Optional voice input for description — toggled via `_showVoiceInput` (`:31`).
3. Optional food-item search: `_onSearchChanged` debounces 400ms, hits `searchFoodItemsProvider`, shows top 5 results. Tapping a result adds it to `_foodItems`. Custom food via `_CreateCustomFoodDialog`.
4. Per-food portion editor: `_updatePortion` rejects ≤0 grams (`:103–107`). Removed via `_removeFoodItem(index)`.
5. Macro totals (`_totalCalories`, `_totalProtein`, `_totalCarbs`, `_totalFat`) recompute on every `_foodItems` change via getters (`:53–57`).
6. `_canSave` requires type + feeling + non-empty description (`:48–51`).
7. Save → builds `Meal` with `userId` from provider; bails silently if userId is null (`:113`).

### Sleep Log Entry — happy path
1. Defaults: bedtime 22:00, wake 06:00 (`:19–20`).
2. `_pickBedTime` / `_pickWakeTime` use `showTimePicker`. If user cancels, no state change.
3. `_calculateDuration` adds a day to `wake` if it's before `bed` — handles overnight sleeps (`:37–39`).
4. Quality is required (1–5). Save bails silently if `_quality == null` at `:70`.
5. Save → builds `SleepLog`, calls `sleepNotifierProvider.logSleep`. Success SnackBar uses raw `Colors.green`, failure SnackBar uses raw `Colors.red`.

---

## 2. States

| Page | State | Render |
|---|---|---|
| Journal | content empty → Save tapped | SnackBar "Please add some content first." — does NOT disable the button preemptively |
| Journal | saving | App bar replaces "Save" TextButton with 20×20 spinner; CTA at the bottom is disabled |
| Journal | saved + content >50 chars + entities found | navigates to `Routes.reviewAutoCreated` with extracted payload |
| Journal | saved + content ≤50 chars | SnackBar "Journal saved!" + pop |
| Journal | save failed | SnackBar "Failed to save journal entry." — no retry, no error code |
| Journal | audio upload failed mid-save | Silently swallowed (`:96–98`) — entry saves without audio reference |
| Meal | description empty / type missing / feeling missing | Save button disabled (`_canSave == false`) |
| Meal | userId null at Save | Silent return — no SnackBar |
| Meal | submitting | `_isSubmitting == true` — button shows loading state (verify) |
| Meal | food search empty query | clears results without hitting backend |
| Meal | food search debounce in flight | `_isSearching == true` |
| Sleep | quality null | Save bails silently; no SnackBar, no button-disabled affordance |
| Sleep | overnight sleep (bed > wake by clock) | duration calculation rolls wake into next day |
| Sleep | success | green SnackBar + pop |
| Sleep | failure | red SnackBar — no retry path |

---

## 3. Edge cases (dug out of code, not paraphrased)

1. **Audio upload failure is swallowed** at `journal_entry_page.dart:96–98`. The user sees "Journal saved!" but the audio they recorded is gone. No visible indication, no retry queue. If audio is "the point" (post-session reflection with detailed pain notes dictated), this is data loss.
2. **Entity extraction runs synchronously on the UI thread.** `EntityExtractionService.extractSessions/Meals/BodyMentions` (`:137–139`) — for content >50 chars on every successful save. Long entries (a 2-page evening reflection) may jank the SnackBar/navigation.
3. **`extra` map for routeReviewAutoCreated** at `:155–161` — passes the *extracted payload* (which is mutable / non-trivial) via go_router's `extra`. Plan.md flags `extra` as fragile for deep-linking. If the user backgrounds the app between save and review, the payload is lost.
4. **`context.push` wrapped in try/catch at `journal_entry_page.dart:152–166`** — catches "GoRouter not available" by silently popping. This is a test workaround leaking into production; it masks any real GoRouter error (e.g., a route name typo would silently pop instead of crashing).
5. **Sleep save bails silently when `_quality == null`** at `sleep_log_entry_page.dart:70`. The button is *not* preemptively disabled — the user can tap it and nothing happens. No tooltip, no SnackBar. Likely a UX confusion.
6. **Sleep SnackBars use raw `Colors.green` / `Colors.red`** at `sleep_log_entry_page.dart:104, 113`. Brand v1 doesn't use Material's default red/green — should use `AppColors.error` / `AppColors.accent`. Stale code from before brand v1 landed.
7. **Meal save bails silently when `userId == null`** at `meal_log_page.dart:113` — same pattern as Sleep, same UX flaw.
8. **Mood selector toggle behavior**: tapping the currently-selected mood emoji deselects it (`mood = selected ? null : value`). No tutorial / hint indicates this is possible. Useful for "I started selecting and changed my mind" but invisible.
9. **`_painPointOptions` is hardcoded** to 6 strings at `journal_entry_page.dart:40–47`. Compensation profile uses `CompensationRegion` enum (15 regions). Pain points and compensations are conceptually overlapping but use different vocabularies — risks divergence in entity extraction.

---

## 4. Animation triggers

| Element | File:line | Type | Spec |
|---|---|---|---|
| Mood emoji selection ring | `journal_entry_page.dart:313–331` | `AnimatedContainer` | 200ms |
| Save spinner swap (app bar) | `journal_entry_page.dart:193–209` | Conditional render | None — instant swap |
| Sleep / Meal Save button | (varies) | None | No loading state animation today |
| Voice transcription text injection | `journal_entry_page.dart:262–268` | None | Text appears instantly with caret jump to end |

---

## 5. A11y notes

### Semantic labels

- **Mood emojis** are bare `Text` widgets inside `GestureDetector`s — screen reader reads only the emoji shape's default label (e.g., "smiling face with smiling eyes"). **Gap:** `Semantics(label: 'Mood: 4 of 5')`.
- **Energy slider** has a `label` (`:351`) but only when energy is set — the default-3 case shows label `'3'` which is semantically equivalent. ✅
- **Pain point `FilterChip`s** have label text but no `Semantics(toggled:)`. Flutter's default `FilterChip` may not announce selection state.
- **Mood / Energy section labels** are styled as `labelSmall` Text (`:303, 338, 363`). They're not `Semantics(header: true)` — screen reader treats them as flat body text, not section dividers.
- **Sleep "Bed time" / "Wake time"** are `helpText` on the time picker — readable, but the row showing the selected time may not be wrapped in `MergeSemantics`.

### Contrast

- **Mood selection ring** uses `AppColors.primary.withValues(alpha: 0.12)` fill + full-opacity border. The 12% terracotta tint on warm linen background is borderline at the 1.5:1 non-text contrast threshold for UI controls.
- **Sleep red/green SnackBars** — Material's default colors do not match brand v1. Visual inconsistency.

### Tap targets

- **Mood emojis** — `padding: AppSpacing.sm` on a 28px emoji = ~44–46px effective. ⚠️ Borderline-fails 48×48.
- **`FilterChip` pain points** — Material default ~32–36px tall depending on density. ⚠️ May fail.
- **Sleep time picker rows** — depend on row height; likely OK but verify.
- **Save CTA** — explicit `Size.fromHeight(56)` ✅.

### Focus & keyboard

- All three pages are `ListView` scrolling forms — keyboard insets handled by Flutter automatically.
- No `FocusableActionDetector` on emoji or chip rows → keyboard users tab through but can't see focus highlight.
