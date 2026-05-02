# Profile — Spec (Phase B7)

**Scope:** Profile page (the user's home for personal info + the navigation hub for everything that doesn't live on the bottom-nav).
**Not in scope:** Edit Profile (own page, linked from here), Onboarding (own page, conditionally linked from here), the screens linked from the four nav-group cards (each spec'd elsewhere).

**Source files:**

- Profile — `frontend/mobile/lib/features/profile/presentation/pages/profile_page.dart` (481 lines)
- Edit Profile (linked) — `frontend/mobile/lib/features/profile/presentation/pages/profile_edit_page.dart` (384 lines)
- Test — `frontend/mobile/lib/features/profile/presentation/pages/profile_page_test.dart`

---

## 1. User flows

### Profile — happy path
1. Bottom nav → Profile tab → `ProfilePage` builds.
2. Reads 5 providers in parallel (`:21–28`):
   - `profileStreamProvider` (the user document) → `valueOrNull`
   - `hasCompletedOnboardingProvider` (sync bool)
   - `streakProvider`, `totalCompletedSessionsProvider`
   - `currentUserIdProvider` → if non-null, `activeGoalsProvider(uid)` → `valueOrNull?.length ?? 0`
3. Header renders: 80×80 sage-bordered terracotta-tinted circle with the first letter of `profile.name` (or `?` if name empty), the name (or "Way2Move Athlete" fallback), and the email if present (`:189–235`).
4. `_StatsRow` shows `streak` / `sessions` / `goals` separated by 1×32 vertical dividers — 28px Fraunces numbers above 11px label text.
5. If `!onboardingDone`, the sage `_OnboardingCta` card renders below the stats with "Complete your setup" → `Routes.onboarding`.
6. Four `_NavGroupCard`s render in sequence (Training · Body awareness · Daily · You), each a card with a Fraunces 20px section title above and a column of `_NavTile`s separated by indented `Divider`s.
7. Centered `TextButton.icon` "Sign Out" at the bottom → `authNotifierProvider.notifier.signOut()`.

### Sign-out flow
1. Tap "Sign Out" → fires `signOut()` → returns to splash → router redirects to login (per B1 spec).
2. **No confirmation dialog.** Single tap signs the user out.

---

## 2. States

| Element | Condition | Render |
|---|---|---|
| Profile header | profile null (stream loading) | name `''` → fallback "Way2Move Athlete"; initial `?`; no email line |
| Profile header | profile loaded, name == "" | "Way2Move Athlete" + `?` initial |
| Profile header | profile.email == "" | email row hidden |
| Stats row | always renders | `streak` / `sessions` / `goals` computed from providers |
| Stats row | userId null | `goals` is 0 (early return at `:26–28`) |
| Stats row | activeGoalsProvider loading | `goals` is 0 (`valueOrNull?.length ?? 0`) — loading is invisible |
| Onboarding CTA | `!onboardingDone` | sage tinted card visible |
| Onboarding CTA | onboardingDone | absent (no animation) |
| Nav groups | always | 4 cards × 2–3 tiles each, all routes hardcoded |
| Sign Out | always | TextButton, no confirmation |

---

## 3. Edge cases (dug out of code, not paraphrased)

1. **No sign-out confirmation.** `profile_page.dart:151–152` calls `signOut()` immediately on tap. A user fat-fingering the centered TextButton signs themselves out instantly. Compare with industry norm (most apps confirm). Either add a confirmation dialog or move the button further out of reach.
2. **`activeGoalsCount` falls back to 0 silently** at `:26–28` if `currentUserIdProvider` is null OR if `activeGoalsProvider(uid)` is loading. The "0 Goals" stat is indistinguishable from "loading goals" and from "really has zero goals." A user who hasn't loaded yet sees "0 Goals" and may assume their goals are gone.
3. **Header initial uses `name[0].toUpperCase()`** at `:189`. For non-Latin / multi-byte characters (e.g., emoji-name "🏋️ Lifter"), `name[0]` returns a surrogate-pair fragment that renders as a placeholder box. UTF-16 vs grapheme-cluster mismatch.
4. **Nav uses a mix of `context.go` and `context.push`.** `Routes.exercises`, `Routes.programs`, `Routes.goals`, `Routes.nutrition` use `context.go` (replace history). Everything else uses `context.push` (add to history). Inconsistent — back from Exercises pops to Home, back from Compensation Profile pops to Profile. User mental model fractures.
5. **`_NavTile` `minHeight: AppSpacing.minTapTarget`** at `:449` enforces 48px ✅ — but the divider is `indent: AppSpacing.xxl` (`:421`) which leaves the divider not flush with the icon column. Visually hangs left of the icon, not aligned with the label text. Minor cosmetic.
6. **"Way2Move Athlete" fallback name** is hardcoded at `:220`. If the user has set their name to literally empty string in Edit Profile (not blocked by validation?), they see this generic placeholder forever. Should probably surface "Add your name" in this case.
7. **`profileStreamProvider.valueOrNull`** at `:21` swallows error states. If the profile stream errors (network drop, doc deleted), the user sees the empty-name fallback with no indication anything is wrong.
8. **No pull-to-refresh.** The page is a `SingleChildScrollView`. If a user just changed their name in Edit Profile and the stream hasn't propagated, there's no manual refresh affordance — they have to leave and come back to the tab.

---

## 4. Animation triggers

| Element | File:line | Type | Spec |
|---|---|---|---|
| Onboarding CTA → push | `:316` | `InkWell` ripple → router transition | Default Material |
| Nav tile press | `:441` | `InkWell` ripple → router transition | Default Material |
| Sign-out button | `:149` | `TextButton` ripple | Default Material |

The page itself has no entry animation (no fade, no stagger). Compare with Goals List (B5) which uses `WayMotion.reward` stagger — Profile feels visually static by contrast.

---

## 5. A11y notes

### Semantic labels

- **Stats numbers** (`28` Fraunces) have no semantic context. Screen reader reads "28" with no unit. **Gap:** wrap each `_StatColumn` in `Semantics(label: '$value $label')` (e.g., "12 Day Streak").
- **Header initial** circle is decorative — should be `Semantics(label: '${name}\\u2019s profile')`.
- **Nav tile chevron** is icon-only at the right edge — purely decorative, but Flutter exposes it. Should be `ExcludeSemantics`.
- **`_NavGroupCard` title** ("Training", "Body awareness", etc.) is styled but not `Semantics(header: true)` — screen reader doesn't navigate by section.
- **Sign Out button** label is fine, but no destructive-action hint — many a11y users expect `Semantics(button: true, hint: 'Double-tap to sign out')`.

### Contrast

- 80×80 header circle: terracotta @ 12% on warm linen, sage 2px border. Color-on-color may fall below AA at the border for color-blind users.
- "Way2Move Athlete" fallback in `displaySmall` Fraunces — bold serif on warm linen passes easily.
- Email line at 13px Manrope `onSurfaceVariant` — borderline at small size; verify against `colorScheme.onSurfaceVariant` token.

### Tap targets

- **Sign Out button** — TextButton with `vertical: AppSpacing.sm` padding. ⚠️ May be <48px tall on small screens.
- **Nav tiles** — explicit `minHeight: AppSpacing.minTapTarget` ✅.
- **Onboarding CTA** — full-width row with `padding: AppSpacing.md`. ✅.
- **Stats columns** — non-interactive, no tap target needed.

### Focus & keyboard

- All interactive elements are standard Material widgets (`InkWell`, `TextButton`) — keyboard navigable by default but no custom focus ring.
- Section titles aren't headers semantically → no fast-jump for screen reader users.
