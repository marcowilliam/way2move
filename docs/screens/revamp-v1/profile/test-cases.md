# Profile — Test Cases (Phase B7)

| # | Type | File | Trigger | Expected outcome |
|---|---|---|---|---|
| 1 | W | `profile_page_test.dart` | Pump with no profile (stream `valueOrNull` is null) | Header initial is "?", name reads "Way2Move Athlete", email row absent |
| 2 | W | `profile_page_test.dart` | Pump with profile `name: 'Marco', email: 'm@a.com'` | Initial "M", name "Marco", email row visible |
| 3 | W | `profile_page_test.dart` | Pump with name "🏋️ Lifter" | Initial renders without UTF-16 surrogate corruption — **currently-missing**, surfaces edge case #3 |
| 4 | W | `profile_page_test.dart` | Pump with profile `name: ''` | Fallback "Way2Move Athlete" + initial "?" — **currently-missing**, surfaces edge case #6 (no "Add your name" affordance) |
| 5 | W | `profile_page_test.dart` | Pump with `streakProvider == 7`, `totalCompletedSessionsProvider == 42`, `activeGoalsProvider == 3 goals` | Stats row shows 7 / 42 / 3 |
| 6 | W | `profile_page_test.dart` | Pump with `currentUserIdProvider == null` | Stats row shows `goals: 0` regardless of activeGoalsProvider — **currently-missing**, surfaces edge case #2 |
| 7 | W | `profile_page_test.dart` | Pump with `activeGoalsProvider` loading | `goals: 0` rendered — indistinguishable from "really has zero" |
| 8 | W | `profile_page_test.dart` | Pump with `hasCompletedOnboardingProvider == false` | `_OnboardingCta` sage card visible |
| 9 | W | `profile_page_test.dart` | Pump with `hasCompletedOnboardingProvider == true` | `_OnboardingCta` not in tree |
| 10 | W | `profile_page_test.dart` | Tap onboarding CTA | Pushes `Routes.onboarding` |
| 11 | W | `profile_page_test.dart` | Pump | Four `_NavGroupCard`s render in order: Training, Body awareness, Daily, You |
| 12 | W | `profile_page_test.dart` | Pump | Each nav card has the expected number of tiles (3, 3, 3, 2) |
| 13 | W | `profile_page_test.dart` | Tap "Exercises" tile | `context.go(Routes.exercises)` invoked (history replaced) |
| 14 | W | `profile_page_test.dart` | Tap "Compensation Profile" tile | `context.push(Routes.compensationProfile)` invoked (history added) |
| 15 | W | `profile_page_test.dart` | Tap "My Program" tile | `context.go(Routes.programs)` |
| 16 | W | `profile_page_test.dart` | Tap "Edit Profile" tile | `context.push(Routes.profileEdit)` |
| 17 | W | `profile_page_test.dart` | Tap each tile in turn, snapshot the navigation method (push vs go) | Document the inconsistency from edge case #4 — **currently-missing** |
| 18 | W | `profile_page_test.dart` | Tap "Sign Out" | `authNotifierProvider.notifier.signOut()` invoked once with no confirmation — **currently-missing**, surfaces edge case #1 (no confirm dialog) |
| 19 | W | `profile_page_test.dart` | Pump and find divider beneath nav tile | Divider has `indent: AppSpacing.xxl` (visually misaligned per edge case #5) |
| 20 | W | `profile_page_test.dart` | Pump with profile stream emitting an error | Page renders empty-name fallback, no error indicator — **currently-missing**, surfaces edge case #7 |
| 21 | W | `profile_page_test.dart` | Pump and try to pull-to-refresh | No refresh affordance exists — **currently-missing**, documents edge case #8 |
| 22 | I | `profile_repository_int_test.dart` | profileStream watches `users/{uid}` against emulator | Stream emits when document is updated by another writer |
| 23 | I | `auth_repository_int_test.dart` | signOut against emulator | `authStateChanges()` emits null after signOut completes |
| 24 | E | `integration_test/profile_e2e_test.dart` | Sign in → land on profile → tap Edit Profile → return → confirm name updated | Header reflects new name on return — **currently-missing E2E** |
| 25 | E | `integration_test/sign_out_e2e_test.dart` | Tap Sign Out → land on login | Splash → Login transition fires; session cleared — **currently-missing E2E** |

---

## Currently-missing scenarios summary

1. **No confirmation on Sign Out (#18 / edge case #1).** A single tap on the centered TextButton signs the user out. Add a `showDialog` confirm step, or document the deliberate one-tap design and add a test asserting the no-confirm behavior so it can't drift unnoticed.
2. **`activeGoalsCount` falls back to 0 silently (#6 / edge case #2).** Loading-state goals look like zero goals. Either show a small skeleton dot, or distinguish "loading" with an `AsyncValue.when`.
3. **Profile stream errors are swallowed (#20 / edge case #7).** A network drop shows the user a generic empty profile with no diagnostic. Surface the error somewhere — even a small toast.
4. **No pull-to-refresh (#21 / edge case #8).** SingleChildScrollView with no RefreshIndicator. After Edit Profile the user has no manual way to force a refresh.
5. **Header initial may corrupt on multi-byte names (#3 / edge case #3).** `name[0]` is UTF-16 byte access, not grapheme cluster. Use `name.characters.first` from `package:characters`.
