# Phase 2 — AI Movement Assessment: Implementation Checklist

> **Depends on:** Phase 1 (Assessment System, Exercise Library)
> **Can run parallel with:** Phase 3, Phase 5
> **Blocks:** nothing

---

## Block 0 — ML Model Integration ✅ (framework selected, integration pending)

- [x] Evaluate and select pose estimation framework (MediaPipe vs ML Kit)
- [ ] Integrate pose estimation SDK into Flutter project
- [ ] Build PoseEstimationService wrapper (abstract interface + implementation)
- [ ] Create landmark extraction pipeline (key joint positions per frame)
- [ ] Handle on-device inference (no server round-trip for pose detection)
- [ ] Tests: unit tests for pose data parsing and landmark extraction

### Framework decision: `flutter_pose_detection` v0.4.1

**Selected package:** `flutter_pose_detection` ^0.4.1 (pub.dev)
**Decision date:** 2026-03-30

#### Why not the alternatives

| Package | Reason ruled out |
|---|---|
| `google_mlkit_pose_detection` | Only 17 landmarks (COCO topology) — missing wrists and feet, insufficient for knee/hip/shoulder angle biomechanics |
| `pose_detection` (TFLite) | Viable but smaller community, no built-in joint angle utilities, less battle-tested |
| `thinksys_mediapipe_plugin` | iOS only — no Android support |

#### Why `flutter_pose_detection`

- **33 MediaPipe BlazePose landmarks** — covers every joint needed: shoulders, elbows, wrists, hips, knees, ankles, feet
- **Built-in video file processing** with progress tracking (live camera AND recorded video — both needed for Phase 2)
- **Built-in joint angle calculation utilities** (knee angle, hip angle, shoulder angle) — saves building from scratch
- **3D landmarks** (Z-axis depth) — better biomechanical analysis than 2D-only
- **Hardware acceleration on both platforms:**
  - iOS: CoreML + Metal GPU
  - Android: GPU + NPU (Snapdragon devices)
- **Performance:** ~3ms per frame on GPU mode (Galaxy S25 Ultra), 13–16ms NPU mode (battery-efficient)
- MIT license, actively maintained (2-month-old update at time of research)
- Publisher verified (hugocornellier.com)

#### Key integration notes

```yaml
# pubspec.yaml
dependencies:
  flutter_pose_detection: ^0.4.1
```

- Android min SDK: **API 31** (raised from API 21 — check if this conflicts with existing min SDK)
- iOS min: 14.0+
- Inference runs **on-device only** — no network calls, no privacy concerns, works offline
- Two inference modes to consider per use case:
  - **GPU mode** (~3ms): live camera feed during assessment recording
  - **NPU mode** (~13ms): batch video processing after recording (preserves battery)
- The 33 BlazePose landmarks use MediaPipe numbering — map to our domain `JointLandmark` enum in `PoseEstimationService`

#### Landmark map (MediaPipe index → body part, relevant ones)

| Index | Landmark | Used for |
|---|---|---|
| 11 | Left shoulder | Shoulder angle, rounded shoulders pattern |
| 12 | Right shoulder | Shoulder angle |
| 13 | Left elbow | Elbow angle |
| 14 | Right elbow | Elbow angle |
| 15 | Left wrist | Wrist position |
| 16 | Right wrist | Wrist position |
| 23 | Left hip | Hip angle, anterior pelvic tilt |
| 24 | Right hip | Hip angle |
| 25 | Left knee | Knee angle, valgus/varus detection |
| 26 | Right knee | Knee angle |
| 27 | Left ankle | Ankle dorsiflexion |
| 28 | Right ankle | Ankle dorsiflexion |
| 29 | Left heel | Foot contact |
| 30 | Right heel | Foot contact |
| 31 | Left foot index | Foot angle |
| 32 | Right foot index | Foot angle |
| 0 | Nose | Head position, forward head posture |

#### Screening movements to support (Phase 2)

These are the movements used in the video assessment flow. Each maps to specific compensation patterns from Phase 1:

| Movement | Key joint angles | Compensation patterns detected |
|---|---|---|
| Overhead squat | Knee angle, hip angle, ankle dorsiflexion, shoulder angle | `kneeValgus`, `limitedDorsiflexion`, `anteriorPelvicTilt`, `roundedShoulders` |
| Single-leg stance | Hip drop (pelvic drop angle), knee alignment | `weakGluteMed`, `kneeValgus` |
| Forward bend | Hip hinge angle, spine curvature | `anteriorPelvicTilt`, `excessiveLumbarLordosis`, `poorCoreStability` |
| Shoulder raise (arms overhead) | Shoulder elevation, thoracic extension | `roundedShoulders`, `limitedThoracicRotation`, `forwardHeadPosture` |
| Walking gait (5 steps) | Hip extension, knee flexion timing, ankle push-off | `limitedDorsiflexion`, `weakGluteMed` |

> **Note:** Video recording for movement screening was deferred in Phase 1 (questionnaire-only). Phase 2 adds the camera-based flow on top of the existing questionnaire results.

---

## Block 1 — Video Analysis Pipeline

- [ ] Domain: `PoseLandmark` entity (index, x, y, z, visibility)
- [ ] Domain: `PoseFrame` entity (timestamp, landmarks: List\<PoseLandmark\>)
- [ ] Domain: `VideoAnalysis` entity (id, assessmentId, movementName, frames: List\<PoseFrame\>, detectedCompensations, analyzedAt)
- [ ] Domain: `VideoAnalysisRepository` interface (save, getByAssessment)
- [ ] Domain: `PoseEstimationService` abstract interface (analyzeFrame, analyzeVideo)
- [ ] Data: `FlutterPoseEstimationService` — wraps `flutter_pose_detection`, maps landmarks to domain entities
- [ ] Data: `FirestoreVideoAnalysisDatasource` + `VideoAnalysisRepositoryImpl`
- [ ] Video recording flow: camera screen that guides user through each screening movement, records clips per movement
- [ ] Video analysis pipeline: feed each recorded clip through `PoseEstimationService`, collect frames
- [ ] Extract joint angles from landmark positions at key checkpoints (bottom of squat, mid-stride, etc.)
- [ ] Store analysis results in Firestore linked to assessment record
- [ ] Handle video compression before upload: target < 10MB per clip (use `video_compress` or similar)
- [ ] Firebase Storage: upload raw clips to `users/{userId}/assessments/{assessmentId}/{movement}.mp4`
- [ ] Tests: unit tests for landmark → joint angle calculation (pure math, no ML)
- [ ] Tests: integration tests with pre-recorded sample video frames (mock the pose estimator)

---

## Block 2 — Compensation Detection

- [ ] Define compensation threshold rules as structured data (angle thresholds per movement per compensation)
- [ ] `CompensationDetector` service: takes List\<PoseFrame\> + movement name → List\<DetectedCompensation\>
- [ ] Map pose landmark angles to each Phase 1 `CompensationPattern` enum value
- [ ] Score severity: mild (threshold exceeded < 30% of frames), moderate (30–60%), significant (>60%)
- [ ] Generate `CompensationReport` from video analysis (one report per assessment)
- [ ] Merge AI detection results with questionnaire-based results from Phase 1 (union, AI result takes precedence on severity)
- [ ] Tests: unit tests for each threshold rule with boundary values (red → green TDD)

### Threshold reference (starting values — tune with user testing)

| Compensation | Movement | Angle threshold | Notes |
|---|---|---|---|
| `kneeValgus` | Squat | Knee caves inward > 10° from neutral | Compare knee X vs ankle X at squat bottom |
| `limitedDorsiflexion` | Squat | Ankle dorsiflexion < 15° | Heel rise detected via heel landmark |
| `anteriorPelvicTilt` | Forward bend | Hip–knee–ankle angle deviation | Excessive lumbar curve |
| `weakGluteMed` | Single-leg stance | Pelvis drop > 5° on stance leg | Hip landmark asymmetry |
| `roundedShoulders` | Overhead raise | Shoulder angle < 160° at full elevation | |
| `forwardHeadPosture` | Any | Nose X > shoulder X + 15% of shoulder width | |

---

## Block 3 — AI-Generated Program Recommendations

- [ ] `ProgramRecommendationEngine` service: takes `CompensationReport` + `UserProfile` → `ProgramTemplate`
- [ ] Prioritize compensations by severity (significant first, then moderate, then mild)
- [ ] Auto-select exercises from library using Phase 1 `CompensationPattern → exerciseId` mapping (already exists in `GetSuggestedGoals`)
- [ ] Progressive template: weeks 1–2 corrective focus (high frequency low load), weeks 3–4 integration, weeks 5+ maintenance
- [ ] Filter exercises by user's available equipment (from `UserProfile.availableEquipment`)
- [ ] Presentation: `AIRecommendationReviewPage` — show detected compensations + proposed program, allow per-exercise edits before accepting
- [ ] On accept: call existing `CreateProgram` use case with generated template
- [ ] Tests: unit tests for priority ranking, exercise selection, equipment filtering

---

## Block 4 — Before/After Comparison UI

- [ ] Side-by-side video playback widget (scrubbed together, same timestamp)
- [ ] Pose landmark overlay on video using `CustomPainter` — colored dots per joint, lines between connected joints
- [ ] Color code joints by quality: green = good alignment, amber = borderline, red = compensation detected
- [ ] `MovementScoreChart` widget: radar chart or grouped bar chart (initial vs re-assessment score per movement)
- [ ] Compensation reduction summary card: "Knee valgus improved from significant → mild"
- [ ] `ReAssessmentComparisonPage` — full comparison screen triggered after completing a re-assessment
- [ ] Tests: widget tests for overlay painter and comparison chart

---

## Block 5 — Re-Assessment Scheduling and Notifications

- [ ] `ReAssessmentSchedule` entity (userId, nextAssessmentDate, intervalWeeks, lastCompletedDate)
- [ ] Default interval: 4 weeks after completing an assessment; configurable in settings (4/6/8/12 weeks)
- [ ] Cloud Function trigger: `onAssessmentComplete` — writes next re-assessment date to user doc
- [ ] Push notifications via Firebase Cloud Messaging (FCM): "Time to re-assess — see how far you've come"
- [ ] Notification scheduled 3 days before due date and on due date
- [ ] Re-assessment flow: same video recording screen, but shows "last time you scored X" per movement
- [ ] `AssessmentTimelinePage` — chronological list of past assessments with trend arrows per compensation
- [ ] Tests: unit tests for scheduling logic and interval calculation

---

## Implementation notes

### Architecture additions for Phase 2

```
features/
└── assessment/
    ├── domain/
    │   ├── entities/
    │   │   ├── pose_landmark.dart        # NEW
    │   │   ├── pose_frame.dart           # NEW
    │   │   └── video_analysis.dart       # NEW
    │   ├── services/
    │   │   ├── pose_estimation_service.dart    # NEW abstract interface
    │   │   └── compensation_detector.dart      # NEW pure Dart service
    │   └── usecases/
    │       ├── analyze_movement_video.dart     # NEW
    │       └── generate_ai_program.dart        # NEW
    └── data/
        ├── services/
        │   └── flutter_pose_estimation_service.dart  # NEW — wraps flutter_pose_detection
        └── repositories/
            └── video_analysis_repository_impl.dart   # NEW
```

### Key dependency: existing Phase 1 code

- `CompensationPattern` enum (already defined in `features/assessment/domain/entities/assessment.dart`) — Phase 2 detection maps to the same enum values
- `GetSuggestedGoals` use case already maps `CompensationPattern → exercise IDs` — reuse this mapping in Block 3
- `CreateProgram` use case — Block 3's recommendation engine feeds directly into this

### Android SDK version

`flutter_pose_detection` requires **Android API 31+**. Check current `minSdkVersion` in `android/app/build.gradle` before integration. If it's below 31, update it and verify no existing dependencies break.
