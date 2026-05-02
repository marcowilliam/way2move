# Body Awareness — Test Cases (Phase B5)

Mapped to `.claude/rules/testing.md`. Type column: U=unit · W=widget · I=integration · E=E2E.

| # | Type | File | Trigger | Expected outcome |
|---|---|---|---|---|
| 1 | W | `compensation_profile_page_test.dart` | Pump with stream loading | Center spinner, no other content |
| 2 | W | `compensation_profile_page_test.dart` | Pump with stream error | "Error loading compensations: ..." rendered |
| 3 | W | `compensation_profile_page_test.dart` | Pump with `[]` | `_EmptyState` with "Add Compensation" CTA |
| 4 | W | `compensation_profile_page_test.dart` | Pump with all-active list | Only "Active" header + tiles render — no Improving/Resolved sections |
| 5 | W | `compensation_profile_page_test.dart` | Pump with one of each status | All three section headers render in order: Active → Improving → Resolved |
| 6 | W | `compensation_profile_page_test.dart` | Tap empty-state CTA | Pushes `Routes.compensationAdd` |
| 7 | W | `compensation_profile_page_test.dart` | Tap a `_CompensationTile` | Pushes `Routes.compensationDetail(id)` with the tile's id |
| 8 | W | `compensation_profile_page_test.dart` | Pump with mild severity | `_SeverityBadge` paints `AppColors.severityMild` |
| 9 | W | `compensation_profile_page_test.dart` | Pump with moderate severity | `_SeverityBadge` paints `AppColors.severityModerate` |
| 10 | W | `compensation_profile_page_test.dart` | Pump with severe severity | `_SeverityBadge` paints `AppColors.severitySignificant` |
| 11 | W | `compensation_profile_page_test.dart` | Pump and tap a region on the body map (mock onRegionTap) | Pushes `Routes.compensationDetail(c.id)` for the tapped region |
| 12 | W | `compensation_profile_page_test.dart` | Add a hypothetical 4th status (e.g., `archived`) | Tile is present in the data but renders nowhere — **currently-missing**, surfaces edge case #8 |
| 13 | W | `goal_list_page_test.dart` | Pump with `currentUserIdProvider == null` | Bare `CircularProgressIndicator`, no AppBar |
| 14 | W | `goal_list_page_test.dart` | Pump with provider loading | Center spinner inside scaffold with "Goals" app bar |
| 15 | W | `goal_list_page_test.dart` | Pump with provider error | "Error: $e" raw — **currently-missing**, no friendly error UI |
| 16 | W | `goal_list_page_test.dart` | Pump with `[]` | `_EmptyGoalsView` with copy mentioning assessment + add button |
| 17 | W | `goal_list_page_test.dart` | Pump with 1 goal | One `_AnimatedGoalCard`, stagger animation completes |
| 18 | W | `goal_list_page_test.dart` | Pump with 12 goals | All 12 render, last card delay clamps at `0.9` (so animation window is 0.9–1.0) |
| 19 | W | `goal_list_page_test.dart` | Pump, tap "+ add" | `AddGoalDialog` opens with userId passed |
| 20 | W | `goal_list_page_test.dart` | Pump with goal of `origin == suggested` | `_OriginChip` renders with "Suggested" + gold accent |
| 21 | W | `goal_list_page_test.dart` | Pump with goal of `status == achieved` | `_StatusBadge` renders with sage tint and "Achieved" label |
| 22 | W | `goal_list_page_test.dart` | Pump with goal of `status == active` | No `_StatusBadge` renders (active is implicit) |
| 23 | W | `goal_list_page_test.dart` | Pull to refresh, return new list | List rebuilds; **currently-missing** assertion: stagger does NOT re-trigger (edge case #5) |
| 24 | W | `goal_list_page_test.dart` | Pump with goal `currentValue == targetValue` | Progress ring shows "100%", goal still active until marked achieved — **currently-missing** |
| 25 | W | `goal_detail_page_test.dart` | Pump with goalId not in list | Bare scaffold "Goal not found" — **currently-missing**, surfaces edge case #3 (no back button) |
| 26 | W | `goal_detail_page_test.dart` | Pump with achieved goal | `_AchievementCard` renders, "Mark as achieved" CTA absent |
| 27 | W | `goal_detail_page_test.dart` | Pump with paused goal | "Paused" badge visible, CTA still active |
| 28 | W | `goal_detail_page_test.dart` | Pump with goal that has `description == ""` | Description block does not render |
| 29 | W | `goal_detail_page_test.dart` | Pump with goal that has `compensationIds == []` | Linked compensations section does not render |
| 30 | W | `goal_detail_page_test.dart` | Pump with goal having 5 linked exercises | 5 `_LinkedExerciseTile`s render in order |
| 31 | W | `goal_detail_page_test.dart` | Tap "Mark as achieved", mock notifier returns `Right(_)` | Spinner shows in icon slot, sage SnackBar "Goal achieved!" displayed |
| 32 | W | `goal_detail_page_test.dart` | Tap "Mark as achieved", mock notifier returns `Left(failure)` | Spinner clears, "Failed to update goal" SnackBar — **currently-missing**, button re-enables for retry-spam (edge case #4) |
| 33 | W | `goal_detail_page_test.dart` | Tap "Mark as achieved", unmount mid-call | No setState-on-unmounted error (covers `if (!mounted) return` at `:153`) |
| 34 | I | `goal_repository_int_test.dart` | `markAchieved` against emulator | Goal doc has `status: 'achieved'` and `achievedAt` server timestamp |
| 35 | I | `compensation_repository_int_test.dart` | `compensationStream` against emulator | Stream emits when a compensation document is updated |
| 36 | E | `integration_test/body_awareness_e2e_test.dart` | Open compensation profile → tap body region → land on detail page | Detail page shows the tapped compensation — **currently-missing E2E** |
| 37 | E | `integration_test/goals_e2e_test.dart` | Add goal via dialog → tap card → mark as achieved | Goal moves to achieved state, stagger animation visible on first load only |

---

## Currently-missing scenarios summary

1. **Goal-not-found dead end (#25 / edge case #3).** The bare scaffold has no back button. A user who deep-links into a deleted goal gets stuck.
2. **markAchieved retry-spam (#32 / edge case #4).** Failure leaves the button enabled with no rate limit and no diagnostic info — repeated taps fire repeated requests.
3. **Stagger animation does not re-run on refresh (#23 / edge case #5).** Visual inconsistency: pulled-in lists look static, mounted lists animate.
4. **Empty-state body-map icon uses sage (wellness color) on an issue-tracker page (edge case #2).** Color-token misuse; worth a brand audit.
