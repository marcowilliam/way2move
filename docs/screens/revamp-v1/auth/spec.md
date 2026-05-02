# Auth — Spec (Phase B1)

**Scope:** Splash, Sign In, Sign Up, Onboarding (welcome step + remaining 5 steps).
This spec describes the four screens that gate the rest of the app — everything from first-paint to "first authenticated home view".
**Not in scope:** Forgot-password flow (placeholder no-op TextButton today, see Edge cases), email verification flow, deep-link routing into auth.

**Source files:**

- Splash — `frontend/mobile/lib/core/splash/splash_page.dart`
- Sign In — `frontend/mobile/lib/features/auth/presentation/pages/login_page.dart`
- Sign Up — `frontend/mobile/lib/features/auth/presentation/pages/sign_up_page.dart`
- Onboarding — `frontend/mobile/lib/features/profile/presentation/pages/onboarding_flow.dart`
- Router (auth gating) — `frontend/mobile/lib/core/router/app_router.dart:71-105`

---

## 1. User flows

The router (`app_router.dart:79-105`) is the source of truth. Splash is the initial location and stays mounted until both `authStateProvider` and (when signed in) `profileLoadProvider` resolve.

| Flow | Path |
|---|---|
| First-paint, signed-out | `Routes.splash` → auth resolves to `null` → redirect to `Routes.login` |
| First-paint, signed-in, onboarded | `Routes.splash` → auth resolves to `User` → profile resolves with `onboardingComplete: true` → redirect to `Routes.home` |
| First-paint, signed-in, not onboarded | `Routes.splash` → auth resolves → profile resolves with `onboardingComplete: false` → redirect to `Routes.onboarding` |
| New user signs up | `LoginPage` → "Create account" → `SignUpPage` → submit → `context.go(Routes.home)` → router intercepts and redirects to `Routes.onboarding` (no profile yet) |
| Returning user signs in | `LoginPage` → submit → `context.go(Routes.home)` → router intercepts based on profile state |
| Onboarding — happy path | 6 PageView pages, "Begin" → "Continue" ×4 → "Get Started" → `_complete` writes profile → `context.go(Routes.home)` |
| Onboarding — skip | "Skip" TextButton in header (`onboarding_flow.dart:283-290`) calls `_complete` immediately with whatever fields are filled |

---

## 2. States

### Splash (`splash_page.dart`)
- **Entrance.** `_fadeController` runs 0–900ms: mark fades 0–280ms (`Interval(0.0, 0.31)`), wordmark fades + slides 200–500ms (`Interval(0.22, 0.56)`).
- **Pulse.** `_pulseController` (`WayMotion.reward`, ~680ms) starts via `whenComplete` after the fade — soft scale tween 1.0 → 1.04 → 1.0.
- **Dark vs light.** Mark color is `AppColors.textPrimaryDark` in dark mode, `AppColors.primary` (terracotta) in light. Wordmark always renders the "2" in terracotta.

### Sign In (`login_page.dart`)
- **Idle.** Form rendered, `_isLoading == false`, all CTAs enabled.
- **Email-looks-valid.** When the email field contains both `@` and `.`, a sage `check_circle_outline` (`AppColors.accent`) appears as the email field's `suffixIcon` (`login_page.dart:135-138`).
- **Submitting.** `_isLoading == true` — `FilledButton` swaps its label for a 20×20 `CircularProgressIndicator`. All three OAuth buttons disable via `onPressed: _isLoading ? null : ...`.
- **Error.** `_errorMessage != null` — animated banner appears above the submit button, terracotta-error tinted background, `AnimatedContainer` transition `WayMotion.standard`.
- **Password obscure toggle.** Eye icon in suffix toggles `_obscurePassword`.

### Sign Up (`sign_up_page.dart`)
- **Idle.** Same shape as Sign In with extra `_nameController` and `_confirmController`.
- **Slide-in entrance.** `_slideController` (`WayMotion.settled`) animates the body from `Offset(0, 0.05)` → zero on first build.
- **Submitting.** Same swap as Sign In. `_obscurePassword` is a single flag — toggling it on the password field also obscures/reveals the confirm field (they share state).
- **Error.** Same banner pattern.

### Onboarding (`onboarding_flow.dart`)
- **Step 0 — Welcome.** `_GroundedFigure` SVG-style `CustomPainter` + Fraunces italic 36px headline. CTA always reads "Begin".
- **Step 1 — Basic info.** Name + age + height + weight `TextField`s. `_canAdvance` returns `true` even if every field is blank — fields are optional. Empty name falls back to `'Athlete'` in `_complete` (`onboarding_flow.dart:120-122`).
- **Step 2 — Goal.** 6 `_OnboardingOptionCard`s. `_canAdvance` returns `false` until `_selectedGoal != null` — Continue button visually dims to 40% opacity (`AnimatedOpacity`, `WayMotion.micro`).
- **Step 3 — Activity level.** 5 `_OnboardingOptionCard`s + a 7-circle "training days per week" picker (defaults to 3).
- **Step 4 — Sports.** Multi-select `_OnboardingTagPill` grid over `_sportOptions` (15 sports). Always advanceable.
- **Step 5 — Equipment.** Multi-select grid over `_equipmentOptions` (11 items). Final step — CTA reads "Get Started".
- **Submitting.** `_saving == true` — pinned button shows a 22×22 spinner, Skip is also disabled.
- **Save failure.** `result.fold` left branch shows `SnackBar('Failed to save profile')` and clears `_saving`. The user stays on the current step.

---

## 3. Edge cases the spec author dug out of the actual code

These are the cases a fresh reader of `plan.md` would miss without reading the `.dart` files.

1. **Forgot-password is a no-op.** `login_page.dart:175-194` renders "Forgot password?" as a styled TextButton with `onPressed: () {}`. There is no route, no dialog, no snackbar. Tapping it does nothing visible. **This is shipped.**
2. **OAuth cancellation is silently swallowed — but only for Google/Apple.** `login_page.dart:341-349` and `:360-368` explicitly check for `AuthFailure.code == 'sign-in-cancelled'` and skip showing an error banner in that case. Email/password sign-in has no equivalent escape hatch — every `Left(failure)` becomes a banner.
3. **The email-valid check is loose.** `_reevaluateEmail` only checks `contains('@') && contains('.')` (`login_page.dart:57-63` and `sign_up_page.dart:66-72`) — `a@.` triggers the sage check. The form-level `validator` is even looser — it only requires `contains('@')`, so a user can submit `foo@` and the FE accepts it; Firebase's `invalid-email` will then come back over the wire and is mapped via `_mapFailureToMessage`.
4. **Onboarding's empty-name fallback is hidden.** `onboarding_flow.dart:120-122` silently substitutes the literal string `'Athlete'` if the user leaves Name blank on step 1. There is no UI hint that this will happen. The Skip button compounds this — a user who skips immediately gets a profile named "Athlete".
5. **The onboarding email field is hardcoded empty on save.** `onboarding_flow.dart:122` writes `email: ''` into the `UserProfile` and relies on the Firestore datasource to merge the existing email from `onUserCreate`. If the merge order ever flips, the profile lands without an email. No assertion guards this.
6. **Sign Up's password-eye toggle is shared between two fields.** `_obscurePassword` controls both the password and confirm fields (`sign_up_page.dart:184` and `:213`). Tapping the eye on either one toggles both — the confirm field has no eye icon of its own. Easy to miss if reading just one widget.
7. **Sign Up doesn't auto-load profile after success.** `sign_up_page.dart:317` calls `context.go(Routes.home)` but the router's redirect (`app_router.dart:97-103`) re-routes to onboarding because `profileAsync.valueOrNull?.onboardingComplete` is false. The flash from sign-up → home → onboarding can be visible on a slow profile-load.
8. **Splash never times out.** `splash_page.dart` only owns the visual; if `authStateChanges()` never emits or the profile stream stalls, the splash sits forever (`app_router.dart:82-94` returns `Routes.splash` on every redirect). No watchdog.

---

## 4. Animation triggers

| Screen | Trigger | Animation |
|---|---|---|
| Splash | Mount | Mark fade 0–280ms (`WayMotion.easeStandard`), then 1.0→1.04→1.0 pulse (`WayMotion.reward`, `easeReward`) |
| Splash | Mount | Wordmark fade + 0.3y slide 200–500ms |
| Sign In | Mount | Body fade 0→1 over 600ms (`WayMotion.easeStandard`) |
| Sign In | `_errorMessage` set | `AnimatedContainer` standard transition for banner appearance |
| Sign In | Email becomes valid | `setState` adds the `check_circle_outline` (no implicit anim — instant) |
| Sign Up | Mount | Body slide-in `Offset(0, 0.05)→0` over `WayMotion.settled` |
| Onboarding | `_currentStep` changes | `_pageController.animateToPage`, `WayMotion.standard`, `easeStandard` |
| Onboarding | `_currentStep` changes | Header dot at index `_currentStep` grows 8→24px wide (`AnimatedContainer`, standard) |
| Onboarding | `_canAdvance` flips | CTA opacity 0.4 ↔ 1.0 (`AnimatedOpacity`, micro) |
| Onboarding | Option card selected | 4px terracotta strip slides in via `Stack`+`Positioned`, padding shifts left by 4px (`AnimatedContainer`, standard) |
| Onboarding | Day count selected | Day-circle fill (`AnimatedContainer`, micro) |

---

## 5. A11y notes

### Semantic labels

- **Splash** has no `Semantics` wrapper — the wordmark is rendered as three separate `Text` widgets ("WAY", "2", "MOVE"). Screen readers will announce each independently. **Gap:** wrap in a single `Semantics(label: 'Way2Move')` or a `MergeSemantics`.
- **Sign In email field** uses the form-level `validator` only — there is no `semanticsLabel` on the field. Material's `TextFormField` exposes `decoration.hintText` ("you@email.com") and the floating label, which is fine.
- **The email-valid check icon** (`Icons.check_circle_outline`) has no `Semantics` label. To a screen-reader user it's invisible; the input passes/fails silently. **Gap:** wrap in `Semantics(label: 'Email looks valid')` when present.
- **Password eye icon** is an `IconButton` — its tooltip is unset, so screen readers announce only "button". **Gap:** add `tooltip: 'Show password'` / `'Hide password'`.
- **Onboarding skip button** announces "Skip" but doesn't telegraph that it submits the profile. **Gap:** consider `tooltip: 'Skip remaining steps and finish setup'`.
- **Onboarding option cards** use `InkWell.onTap` — the selected state is conveyed visually (4px terracotta strip + check icon) but the `Semantics` of the card don't expose `selected: true`. **Gap:** wrap in `Semantics(selected: selected, button: true)`.

### Contrast

- All body text uses theme tokens (`textTheme.displaySmall`, `bodyMedium`, etc.) which are defined in `app_typography.dart` against `AppColors.textPrimary` (#1F1815) on `AppColors.background` (#FAF6F0) — well above WCAG AA.
- **Gap:** the "Forgot password?" link is `AppColors.primary` (#C4622D) on `AppColors.background`. Contrast is ~4.5:1 — borderline. Since the link is not a critical action (and is a no-op, see Edge cases), this is acceptable but should be flagged.
- The Stone metadata color (`AppColors.textSecondary` = #716660) on Warm Linen passes AA for body text but is on the edge for the 11px tracked uppercase labels (`_LabeledField`). Consider bumping to weight 800 or up-tinting in dark mode.

### Tap targets

- All `FilledButton`s on these screens are sized 56px tall (Sign In CTA via theme, Sign Up CTA, Onboarding pinned CTA explicitly `height: 56`). Above the 48px minimum.
- **Gap:** Sign In's "Forgot password?" `TextButton` has `minimumSize: Size.zero` and `tapTargetSize: shrinkWrap` (`login_page.dart:182-183`) — its tap area collapses to the text bounds. Same pattern on the create-account link (`login_page.dart:301-302`) and the sign-in link (`sign_up_page.dart:288-289`). **The text size is 13–14px, so the tap targets are roughly ~28×80 — under 48px tall.** This is a deliberate density choice but technically violates the project's 48×48 rule.
- The 7-day-count circles in onboarding step 3 are `AppSpacing.minTapTarget - 8` = 40px. **Under the 48px rule** (`onboarding_flow.dart:481-482`).
- The header back arrow (`IconButton`, `onboarding_flow.dart:251-257`) uses default `IconButton` sizing — 48px, OK.

### Focus & keyboard

- `LoginPage`/`SignUpPage` use standard `TextFormField` so tab/next traversal works.
- Onboarding's `PageView` uses `NeverScrollableScrollPhysics` — gesture-only step navigation is disabled; screen readers must rely on Continue/Back. This is intentional (prevents lost form state from a stray swipe).
