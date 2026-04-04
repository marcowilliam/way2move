# way2move - Feature Flags Inventory

> All prototype features that need to be wrapped in Firebase Remote Config flags before refinement.

## Flags to Create

| Flag Name | Feature | Default | Priority | Notes |
|-----------|---------|---------|----------|-------|
| feature_cloud_stt | Cloud STT (Whisper API) | false | Medium | Phase 3 Block 0 |
| feature_nutrition | Meal Tracking + Macros | false | High | Phase 3 Blocks 2-3 |
| feature_nutrition_dashboard | Nutrition Dashboard | false | High | Phase 3 Block 4 |
| feature_journal | Voice-First Journal | false | Medium | Phase 3 |
| feature_calendar | Calendar View | false | Low | Phase 3 |
| feature_sleep | Sleep Tracking | false | Medium | Phase 4 |
| feature_recovery | Recovery Score | false | Medium | Phase 4 Block 0-1 |
| feature_progress_photos | Progress Photos | false | Low | Phase 4 |
| feature_notifications | FCM Notifications | false | Low | Phase 4 |

## Implementation Steps
1. Add each flag to the FeatureFlag enum
2. Add parameter in Firebase Remote Config with default `false`
3. Wrap feature entry points with FeatureGate widget
4. Test that disabling flag hides the feature completely
5. Enable flag for development/testing

## Already Flagged
None yet - all prototype features are currently always visible.
