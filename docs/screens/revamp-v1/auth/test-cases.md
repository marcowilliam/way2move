# Auth — Test Cases (Phase B1)

Mapped to `.claude/rules/testing.md`. Legend: `U` = unit · `W` = widget · `I` = integration (Firebase emulator) · `E` = E2E (real emulator + app).

Every test is one scenario. Mocks only across process boundaries.

---

## Splash — `SplashPage`

File: `frontend/mobile/lib/core/splash/splash_page_test.dart` (already exists, 2 tests).

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 1 | W | `splash_page_test.dart` | Pump `SplashPage` in `MaterialApp` | `Way2MoveLogoMark`, `WAY`, `2`, `MOVE` rendered (✅ passing) |
| 2 | W | `splash_page_test.dart` | Pump 16ms, then 950ms | Wordmark `FadeTransition.opacity` < 0.1 early, > 0.9 late (✅ passing) |
| 3 | W | `splash_page_test.dart` | Pump in light theme | Logo mark resolves to `AppColors.primary` (terracotta) — **currently-missing** |
| 4 | W | `splash_page_test.dart` | Pump in dark theme | Logo mark resolves to `AppColors.textPrimaryDark` — **currently-missing** |
| 5 | W | `splash_page_test.dart` | Pump 1000ms (after fade complete) | `_pulseController` ran exactly once (verify final mark scale ≈ 1.0) — **currently-missing** |
| 6 | I | `integration_test/splash_redirect_int_test.dart` | Mount with `authStateChanges` stalled (never emits) | After 5s wait, page is still `SplashPage` (no navigation) — **currently-missing watchdog test** |

---

## Sign In — `LoginPage`

File: `frontend/mobile/lib/features/auth/presentation/pages/login_page_test.dart` (already exists, 7 tests).

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 7 | W | `login_page_test.dart` | Pump | Email + password fields + submit button rendered (✅) |
| 8 | W | `login_page_test.dart` | Tap submit with empty form | "Email is required" shown (✅) |
| 9 | W | `login_page_test.dart` | Enter `not-an-email`, submit | "Enter a valid email" shown (✅) |
| 10 | W | `login_page_test.dart` | Enter valid email, empty password, submit | "Password is required" shown (✅) |
| 11 | W | `login_page_test.dart` | Mock repo returns `AuthFailure('wrong-password')`, submit | Banner shows "Incorrect email or password." (✅) |
| 12 | W | `login_page_test.dart` | Pump | "Create account" button rendered (✅) |
| 13 | W | `login_page_test.dart` | Pump | Google + Apple buttons rendered (✅) |
| 14 | W | `login_page_test.dart` | Enter `foo@bar.com` | Sage `check_circle_outline` appears as suffix on email field — **currently-missing** |
| 15 | W | `login_page_test.dart` | Enter `foo@bar.com` then erase to `foo@` | Sage check disappears — **currently-missing** |
| 16 | W | `login_page_test.dart` | Mock repo returns `AuthFailure('sign-in-cancelled')` from `signInWithGoogle`, tap Google button | No error banner shown (silent dismiss) — **currently-missing** (regression coverage for `login_page.dart:341-349`) |
| 17 | W | `login_page_test.dart` | Mock `signIn` that takes 200ms; tap submit | During pending state, all 3 OAuth buttons are disabled (`onPressed == null`) — **currently-missing** |
| 18 | W | `login_page_test.dart` | Tap "Forgot password?" | Documents that nothing happens (`onPressed: () {}`); test asserts no navigation, no snackbar — **currently-missing, surfaces a dead button** |
| 19 | W | `login_page_test.dart` | Tap password eye icon | `obscureText` flips on the password field — **currently-missing** |
| 20 | I | `integration_test/login_int_test.dart` | Sign in with seeded emulator user | `FirebaseAuth.instance.currentUser.email` matches input — **currently-missing** |
| 21 | E | `integration_test/auth_flow_test.dart` | Sign in via UI on emulator | App lands on `Routes.home` (or `Routes.onboarding` if profile incomplete) — **currently-missing E2E** |

---

## Sign Up — `SignUpPage`

File: `frontend/mobile/lib/features/auth/presentation/pages/sign_up_page_test.dart` (already exists, 5 tests).

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 22 | W | `sign_up_page_test.dart` | Pump | Name, email, password, confirm fields + submit rendered (✅) |
| 23 | W | `sign_up_page_test.dart` | Submit empty form | "Name is required" shown (✅) |
| 24 | W | `sign_up_page_test.dart` | Mismatched passwords + submit | "Passwords do not match" shown (✅) |
| 25 | W | `sign_up_page_test.dart` | 5-char password + submit | "Password must be at least 8 characters" shown (✅) |
| 26 | W | `sign_up_page_test.dart` | Mock `AuthFailure('email-already-in-use')` + submit | Banner: "An account with this email already exists." (✅) |
| 27 | W | `sign_up_page_test.dart` | 1-char name (e.g. "M") + submit | "Name must be at least 2 characters" shown — **currently-missing** (`sign_up_page.dart:148-152`) |
| 28 | W | `sign_up_page_test.dart` | Tap password eye | Both password AND confirm fields un-obscure (shared `_obscurePassword`) — **currently-missing**, documents shared state |
| 29 | W | `sign_up_page_test.dart` | Mock `AuthFailure('weak-password')` + submit | Banner: "Password is too weak. Use at least 8 characters." — **currently-missing** |
| 30 | W | `sign_up_page_test.dart` | Mock `AuthFailure('network-request-failed')` + submit | Banner: "No internet connection." — **currently-missing** |
| 31 | I | `integration_test/sign_up_int_test.dart` | Submit valid sign-up against emulator | New user exists in Auth emulator + `users/{uid}` doc created by `onUserCreate` Cloud Function — **currently-missing** |
| 32 | E | `integration_test/auth_flow_test.dart` | Sign up via UI on emulator | Lands on `Routes.onboarding` (router redirects away from home because profile is incomplete) — **currently-missing E2E**, covers the flicker described in spec edge case #7 |

---

## Onboarding — `OnboardingFlow`

File: `frontend/mobile/lib/features/profile/presentation/pages/onboarding_flow_test.dart` (already exists, ~16 tests).

| # | Type | File | Trigger | Expected |
|---|---|---|---|---|
| 33 | W | `onboarding_flow_test.dart` | Pump | Welcome screen Fraunces text + "Begin" CTA rendered (✅) |
| 34 | W | `onboarding_flow_test.dart` | Tap Continue from welcome | PageView advances to step 1 (basic info) (✅) |
| 35 | W | `onboarding_flow_test.dart` | Pump step 0 | No back button visible (✅) |
| 36 | W | `onboarding_flow_test.dart` | Advance to step 1, tap back | Returns to step 0 (✅) |
| 37 | W | `onboarding_flow_test.dart` | Advance to goal step | All 6 `TrainingGoal` option cards rendered (✅) |
| 38 | W | `onboarding_flow_test.dart` | Goal step with no selection | Continue button has 0.4 opacity (✅) |
| 39 | W | `onboarding_flow_test.dart` | Sports step | All 15 `_sportOptions` chips rendered (✅) |
| 40 | W | `onboarding_flow_test.dart` | Step 5 | "Get Started" CTA visible (✅) |
| 41 | W | `onboarding_flow_test.dart` | Steps 1–5 | Each shows the Fraunces italic prompt (✅) |
| 42 | W | `onboarding_flow_test.dart` | Pump | Header has 6 progress dots (✅) |
| 43 | W | `onboarding_flow_test.dart` | Leave Name blank, walk through to step 5, tap Get Started | Mock `completeOnboarding` invocation: profile is saved with `name: 'Athlete'` — **currently-missing** (covers spec edge case #4) |
| 44 | W | `onboarding_flow_test.dart` | Tap Skip from step 0 | `completeOnboarding` is invoked immediately with default-empty profile — **currently-missing** |
| 45 | W | `onboarding_flow_test.dart` | Mock `completeOnboarding` → `Left(failure)` + tap Get Started | SnackBar "Failed to save profile" shown; remains on step 5; CTA re-enables — **currently-missing** |
| 46 | W | `onboarding_flow_test.dart` | Step 3 (activity), tap day-count circle "5" | `_trainingDaysPerWeek` updates and circle fills terracotta — **currently-missing** |
| 47 | W | `onboarding_flow_test.dart` | Try to swipe horizontally on `PageView` | No advance (uses `NeverScrollableScrollPhysics`) — **currently-missing**, documents intentional gesture lock |
| 48 | I | `integration_test/onboarding_int_test.dart` | Complete onboarding against emulator | `users/{uid}` doc has `onboardingComplete: true` and all selected fields populated — **currently-missing** |
| 49 | E | `integration_test/onboarding_e2e_test.dart` | Sign up + complete all 6 steps | App lands on `Routes.home` after final step — **currently-missing E2E** |

---

## Currently-missing scenarios summary

These four are flagged as the most valuable gaps in the current test coverage:

1. **Forgot-password is a dead button (#18).** No test exists asserting the no-op; if someone wires it up later, no test will fail to flag the silent regression — but more importantly, no test currently surfaces the dead UX. Worth either fixing the prod code (route to a dialog) or asserting "is dead" so future work hits a tripwire.
2. **Empty-name → 'Athlete' fallback (#43).** Production code silently rewrites the user's name. There's no test guarding the fallback, and no UI hint to the user.
3. **Splash watchdog (#6).** If `authStateChanges` never emits (e.g., Firebase init quietly fails), the splash hangs forever. No test, no production timeout. **Recommend adding a 10s timer with a "tap to retry" affordance + integration test.**
4. **OAuth cancellation silently swallowed (#16).** The `'sign-in-cancelled'` skip is a real branch in `login_page.dart:341-349` and `:360-368` with zero coverage. A future refactor that flips the operator could swallow real failures and the tests wouldn't catch it.
