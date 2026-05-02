# Daily Logging — Test Cases (Phase B6)

| # | Type | File | Trigger | Expected outcome |
|---|---|---|---|---|
| 1 | W | `journal_entry_page_test.dart` | Pump with `type: morningCheckIn` | Title is "Morning Check-In", prompt is "How did you sleep? How do you feel?" |
| 2 | W | `journal_entry_page_test.dart` | Pump with `type: postSession` | Title and prompt match the postSession switch case |
| 3 | W | `journal_entry_page_test.dart` | Pump with `linkedSessionId: 'abc'` | "Linked to today's session" sage chip renders |
| 4 | W | `journal_entry_page_test.dart` | Pump without linkedSessionId | Sage chip absent |
| 5 | W | `journal_entry_page_test.dart` | Tap Save with empty content | SnackBar "Please add some content first."; no notifier call |
| 6 | W | `journal_entry_page_test.dart` | Type content + tap Save; mock notifier returns Right(saved); content ≤50 chars | SnackBar "Journal saved!" + Navigator.pop |
| 7 | W | `journal_entry_page_test.dart` | Type 100 chars + tap Save; entity extraction returns sessions | Pushes `Routes.reviewAutoCreated` with extracted payload (verify `extra` map shape) |
| 8 | W | `journal_entry_page_test.dart` | Type content + tap Save; mock notifier returns Left(failure) | SnackBar "Failed to save journal entry."; remains on page |
| 9 | W | `journal_entry_page_test.dart` | Record audio, mock upload to throw, tap Save | Entry still saves with `audioUrl: null`; success SnackBar shown — **currently-missing**, surfaces edge case #1 (silent data loss) |
| 10 | W | `journal_entry_page_test.dart` | Tap mood 4, then tap mood 4 again | `_mood` is null after second tap (toggle deselects) — **currently-missing**, surfaces edge case #8 |
| 11 | W | `journal_entry_page_test.dart` | Drag energy slider to 5 | `_energyLevel` updates; slider label reads "5" |
| 12 | W | `journal_entry_page_test.dart` | Tap "lower back" pain chip twice | First tap selects, second deselects; `_painPoints` is `[]` |
| 13 | W | `journal_entry_page_test.dart` | Type 200 chars + tap Save with `type: morningCheckIn` | No entity extraction (type not in `[postSession, evening, general]`) |
| 14 | W | `journal_entry_page_test.dart` | Mock GoRouter to throw on push; trigger entity-extraction path | Falls through to `Navigator.pop` — **currently-missing**, documents edge case #4 |
| 15 | W | `meal_log_page_test.dart` | Pump with no fields filled | Save button disabled (`_canSave == false`) |
| 16 | W | `meal_log_page_test.dart` | Select type + feeling + type description | Save button enables |
| 17 | W | `meal_log_page_test.dart` | Type in food search "rice" | After 400ms debounce, `searchFoodItemsProvider.call('rice')` fires once |
| 18 | W | `meal_log_page_test.dart` | Type "rice" then immediately type "rice and beans" | Only one call after debounce, with the latest query |
| 19 | W | `meal_log_page_test.dart` | Tap a search result | Item added to `_foodItems`; search results clear |
| 20 | W | `meal_log_page_test.dart` | Set portion to 0g | `_updatePortion` rejects (`if (grams <= 0) return`); food unchanged |
| 21 | W | `meal_log_page_test.dart` | Add 3 foods at 100g, 200g, 50g calories 100/100/100 | `_totalCalories` reflects sum of `scaledCalories` |
| 22 | W | `meal_log_page_test.dart` | Tap Save with `currentUserIdProvider == null` | No navigation, no snackbar — **currently-missing**, surfaces edge case #7 |
| 23 | W | `meal_log_page_test.dart` | Open custom-food dialog → save → result added to list | `_foodItems` length increments by 1 |
| 24 | W | `sleep_log_entry_page_test.dart` | Default render | Bedtime shows 22:00, wake 06:00, duration "8h" |
| 25 | W | `sleep_log_entry_page_test.dart` | Set bedtime 23:00, wake 03:00 | Duration handles overnight: "4h" (wake rolls to next day) |
| 26 | W | `sleep_log_entry_page_test.dart` | Tap Save with `_quality == null` | No call, no SnackBar — **currently-missing**, surfaces edge case #5 |
| 27 | W | `sleep_log_entry_page_test.dart` | Set quality, tap Save; mock returns Right | Green-color SnackBar, Navigator.pop |
| 28 | W | `sleep_log_entry_page_test.dart` | Set quality, tap Save; mock returns Left | Red-color SnackBar, no pop — **currently-missing**, also documents edge case #6 (raw color use) |
| 29 | W | `sleep_log_entry_page_test.dart` | Cancel time picker dialog | No state change |
| 30 | U | `entity_extraction_service_test.dart` | extractSessions on "I trained legs and ran 5km" | Returns 2 session candidates |
| 31 | U | `entity_extraction_service_test.dart` | extractMeals on "lunch was salmon and rice" | Returns 1 meal candidate |
| 32 | I | `journal_repository_int_test.dart` | create() against emulator | Doc exists in `journals/` with the right userId, type, content |
| 33 | I | `journal_audio_storage_int_test.dart` | uploadAudio against emulator | File written to `users/{uid}/journal-audio/{ts}.m4a`; URL returned |
| 34 | I | `meal_repository_int_test.dart` | logMeal against emulator | Meal doc has `foodItems[]` populated; aggregate macros stored |
| 35 | I | `sleep_repository_int_test.dart` | logSleep against emulator | Doc exists with `bedTime` and `wakeTime` server timestamps |
| 36 | E | `integration_test/journal_e2e_test.dart` | Sign in → create journal → land on review-auto-created if extraction matches | Entry persisted; review page reachable |
| 37 | E | `integration_test/sleep_e2e_test.dart` | Open sleep log → fill → save → land on prior page | Sleep log visible in history — **currently-missing E2E** |

---

## Currently-missing scenarios summary

1. **Audio upload data loss is silent (#9 / edge case #1).** No test asserts the swallowed error path; no SnackBar tells the user "audio failed." Recommend a retry queue + visible "audio not uploaded" badge.
2. **Save-with-null-userId silently no-ops (#22, #26 / edge cases #5, #7).** Three logging pages have the same flaw. The CTA should be disabled until userId resolves, OR the no-op should surface as a SnackBar.
3. **GoRouter try/catch fallback masks real failures (#14 / edge case #4).** The fallback was added for tests but now hides production routing bugs. Either remove the catch-all or scope it to a narrower exception type.
4. **Sleep SnackBars use raw `Colors.green` / `Colors.red` (#28 / edge case #6).** Brand v1 should own these. Replace with `AppColors.error` and `AppColors.accent`.
