# Body Awareness — Spec (Phase B5)

**Scope:** Compensation Profile (the body-awareness landing page), Goals List, Goal Detail.
The body-awareness surface is the lens through which the user sees what their body is doing wrong — compensation patterns mapped onto a body diagram — and what they're working on — goals with progress rings.
**Not in scope:** Compensation Detail page (linked from the profile but its own spec next pass), Goal Setup wizard (linked from elsewhere), Add Compensation flow.

**Source files:**

- Compensation Profile — `frontend/mobile/lib/features/compensations/presentation/pages/compensation_profile_page.dart` (325 lines)
- Goals List — `frontend/mobile/lib/features/goals/presentation/pages/goal_list_page.dart` (472 lines)
- Goal Detail — `frontend/mobile/lib/features/goals/presentation/pages/goal_detail_page.dart` (503 lines)
- Body map widget — `frontend/mobile/lib/features/compensations/presentation/widgets/compensation_body_map.dart`
- Compensation entity — `frontend/mobile/lib/features/compensations/domain/entities/compensation.dart`
- Goal entity — `frontend/mobile/lib/features/goals/domain/entities/goal.dart`

---

## 1. User flows

### Compensation profile — happy path
1. User navigates to body awareness via bottom nav or profile card.
2. `compensationStreamProvider` resolves a list of `Compensation`s.
3. `_CompensationBody` (`:53`) splits the list into three sections by `CompensationStatus`: active · improving · resolved. Sections only render if non-empty (`:91`, `:100`, `:109`).
4. Left 4/10 of the screen is the `CompensationBodyMap` aspect-ratio 0.5 vertical body diagram. Tapping a region pushes `Routes.compensationDetail(c.id)` (`:81`).
5. Right 6/10 is a scrollable list of `_CompensationTile`s grouped by section. Tapping a tile also pushes the detail route (`:170`).
6. Empty list renders `_EmptyState` with terracotta `FilledButton.icon` "Add Compensation" (`:280`) → `Routes.compensationAdd`.

### Goals list — happy path
1. User opens Goals via bottom nav or profile.
2. `currentUserIdProvider` must return non-null; otherwise the page renders a bare `CircularProgressIndicator` with no message (`:49–53`) — looks identical to a network spinner.
3. `goalNotifierProvider` resolves a list of `Goal`s.
4. `_staggerController` (duration `WayMotion.reward`) animates each card in with a per-index delay of `index * 0.08` clamped to `[0, 0.9]` (`:128–134`). The animation runs once on mount via `addPostFrameCallback`.
5. Each `_GoalCard` shows: progress ring (`_ProgressRing` 56×56), goal name, category chip, optional "Suggested" chip if `origin == GoalOrigin.suggested`, "current / target unit" text, and a status badge (only rendered when status ≠ active, `:324`).
6. Tap card → push `Routes.goalDetail(goal.id)`.
7. Pull-to-refresh re-invalidates `goalNotifierProvider`.

### Goal detail — happy path
1. Page receives `goalId` via constructor.
2. Watches `goalNotifierProvider`; locates the goal by `id` from the resolved list using `cast<Goal?>().firstWhere(... orElse: () => null)` (`:60–63`).
3. If not found, renders a bare `Scaffold` with center text "Goal not found" — no app bar, no back button.
4. `_entryController` runs a fade + 6%-slide-in over `WayMotion.settled` once (`:30–41`).
5. Body lists: hero ring (180×180 with 52px Fraunces percentage), description (only if non-empty), linked compensations chip row (only if `compensationIds` non-empty), linked exercises tile column (only if `exerciseIds` non-empty), achievement card (only if `achievedAt != null`), and the terracotta "Mark as achieved" `FilledButton.icon` (only if `status != GoalStatus.achieved`, `:118`).
6. Tapping "Mark as achieved" sets `_achieveAnimating = true`, swaps the icon for an inline spinner, calls `markAchieved(goal.id)`, then shows a SnackBar — error or success depending on the `Either` fold (`:155–169`).

---

## 2. States

| Page | State | Trigger | Render |
|---|---|---|---|
| Compensation Profile | loading | Stream initial | center spinner |
| Compensation Profile | error | Stream error | "Error loading compensations: $e" — raw exception in UI |
| Compensation Profile | empty | resolved list `[]` | terracotta-tinted body icon + CTA |
| Compensation Profile | data — all sections empty | possible if every compensation is filtered out | renders an empty `Row` — body map left, empty `ListView` right |
| Goals List | uid null | `currentUserIdProvider == null` | bare spinner, no app bar |
| Goals List | loading | Provider loading | center spinner inside scaffold |
| Goals List | error | Provider error | "Error: $e" raw |
| Goals List | empty | `goals.isEmpty` | sage-tinted flag icon + copy |
| Goals List | data | resolved list non-empty | stagger-animated list |
| Goal Detail | loading | Provider loading | bare scaffold spinner, no back |
| Goal Detail | not-found | id mismatch | bare scaffold "Goal not found", no back |
| Goal Detail | data + active | status == active | full body + Mark-achieved CTA |
| Goal Detail | data + achieved | status == achieved | achievement card visible, no CTA |
| Goal Detail | data + paused | status == paused | "Paused" badge but Mark-achieved CTA still active |

---

## 3. Edge cases (dug out of code, not paraphrased)

1. **Body Awareness app bar title is `displaySmall`** at `compensation_profile_page.dart:25` but the route is "Body awareness" — heading-style text on a tab page is non-standard for Material 3 (most other pages use `titleLarge`). Possible visual inconsistency vs. Goals List which uses `displaySmall` too (`:63`). Audit other top-level pages for heading scale consistency.
2. **`_EmptyState` body diagram icon is `accessibility_new_rounded` tinted with `AppColors.accent` (sage)**, but everywhere else in the file severity is communicated with `AppColors.severityModerate` (clay). The empty-state color contradicts the "issue tracker" framing of the rest of the page — looks more like a wellness empty-state than a body-issue tracker.
3. **Goal "not found" leaves the user stranded.** `goal_detail_page.dart:65–69` renders a `Scaffold` without an `AppBar` when the goal id doesn't match. There's no back button, no retry. Deep-linking to a stale/deleted goal traps the user — they have to kill the app or use system back.
4. **`markAchieved` SnackBar leaves status unchanged on failure.** `goal_detail_page.dart:155–158` shows "Failed to update goal" but does not retry, does not surface what failed, and the button re-enables — the user can spam-tap it.
5. **`_AnimatedGoalCard` stagger animation only runs once on mount.** A pull-to-refresh that produces new goals (`onRefresh` invalidates the provider, `:83`) will *not* re-trigger the stagger — new cards appear instantly with no animation, while existing cards retain the faded-in state. Visual inconsistency between mount and refresh.
6. **`_ProgressRing` uses raw `3.14159`** at `:309` instead of `math.pi`. Cosmetic, but a refactoring smell: arc precision matters less for a 56×56 ring but is *visible* on the 180×180 hero ring at `:280`.
7. **"Suggested" chip color is `AppColors.reward` (gold)** at `:415`, the only place gold appears in this surface. Brand v1 reserves gold for milestones (per `brand-identity-plan.md`). Suggested-by-AI is not a milestone — likely a token misuse. Compare with `_OriginChip` rendering elsewhere.
8. **`compensationStreamProvider`'s "all sections empty" branch is unreachable in practice** but defensively renders an empty `ListView` rather than the empty state. If a future status enum is added (e.g., `archived`) and not added to the three filter clauses, the whole right panel goes silent with no indication.

---

## 4. Animation triggers

| Element | File:line | Type | Spec |
|---|---|---|---|
| Goal cards stagger-in | `goal_list_page.dart:128–134` | Fade + 15% upward slide | `WayMotion.reward` total, `0.4`-wide window per card, `0.08` delay step, clamped — runs once on mount |
| Goal Detail entry | `goal_detail_page.dart:30–41` | Fade + 6% upward slide | `WayMotion.settled` |
| Mark-achieved button → SnackBar | `goal_detail_page.dart:149–169` | Spinner swap; default Material SnackBar | No celebratory animation today (gap — see test-cases) |
| Compensation tile press | `compensation_profile_page.dart:168–171` | Material `InkWell` ripple | Default theme |
| Body map region tap | external widget | Region highlight + push | See `compensation_body_map.dart` |

---

## 5. A11y notes

### Semantic labels

- **Body map regions** are `GestureDetector`s inside `CompensationBodyMap` — likely no `Semantics` wrapper around each tappable region. **Gap:** wrap each region in `Semantics(label: 'Lower back compensation, moderate severity')`.
- **`_SeverityBadge`** is a 10×10 dot at `:222` with no label. Color is the only severity indicator. **Gap:** parent tile should have a merged semantic label including severity.
- **`_ProgressRing`** is a `CustomPaint` displaying the raw "%". Screen reader reads "75 percent" but doesn't say what percent — of what goal. **Gap:** wrap in `Semantics(label: 'Goal progress: 75 percent of target')`.
- **`_StatusBadge` only renders when status ≠ active** at `:324`. Active goals have *no badge at all* — sighted users infer from the absence; screen readers infer nothing. **Gap:** explicit "Active" semantic label even when no badge renders.

### Contrast

- `AppColors.severityMild` and `AppColors.severityModerate` color dots — small (8–10px) targets, color-blind users may not distinguish. Severity should also be encoded in label text or icon shape.
- "Suggested" gold chip on warm-linen background — gold-on-cream contrast may be borderline at 11px label size.

### Tap targets

- **`_CompensationTile`** — InkWell wrapping ~56px-tall content row. ≥48px ✅.
- **`_GoalCard`** — content padding `AppSpacing.md` around a 56px ring. ≥48px ✅.
- **Body map regions** — depend on the SVG path size. Smaller regions (e.g., cervical spine, ankles) may violate 48×48 min-touch — verify in the widget test.
- **Mark-achieved CTA** — explicit `Size(double.infinity, 56)` ✅.

### Focus & keyboard

- No `FocusableActionDetector` on any tile — keyboard users can't navigate tile-to-tile within the list.
- The achievement SnackBar uses a Row of children with no merged semantics — screen reader reads "check circle. Goal achieved!" as two phrases.
