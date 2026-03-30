# Phase 2 — AI Movement Assessment: Implementation Checklist

> **Depends on:** Phase 1 (Assessment System, Exercise Library)
> **Can run parallel with:** Phase 3, Phase 5
> **Blocks:** nothing

---

## Block 0 — ML Model Integration ✅

- [x] Evaluate and select pose estimation framework (MediaPipe vs ML Kit)
- [x] Integrate pose estimation SDK into Flutter project
- [x] Build PoseEstimationService wrapper (abstract interface + implementation)
- [x] Create landmark extraction pipeline (key joint positions per frame)
- [x] Handle on-device inference (no server round-trip for pose detection)
- [x] Tests: unit tests for pose data parsing and landmark extraction

### What was implemented

- `flutter_pose_detection: ^0.4.1` added to `pubspec.yaml`
- Android `minSdk` raised to `31` (required by the SDK) in `android/app/build.gradle.kts`
- `JointLandmark` enum — maps our 17 tracked joints to MediaPipe BlazePose indices
- `PoseLandmark` entity — normalised x/y/z + visibility, pure Dart
- `PoseFrame` entity — timestamp + list of landmarks; provides `angleDegrees()`, `horizontalOffset()`, `verticalOffset()` helpers
- `PoseEstimationService` abstract interface + `PoseAnalysisResult` return type (named to avoid collision with SDK's `VideoAnalysisResult`)
- `PoseDetectorAdapter` thin wrapper interface — keeps SDK types out of domain; enables mock injection in tests
- `FlutterPoseEstimationService` concrete implementation — wraps `NpuPoseDetector`, lazy initialises, maps SDK `Pose` → domain `PoseFrame`
- 32 passing unit tests (18 entity tests + 14 service tests)

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

## Block 1 — Video Analysis Pipeline ✅

- [x] Domain: `PoseLandmark` entity (index, x, y, z, visibility)
- [x] Domain: `PoseFrame` entity (timestamp, landmarks: List\<PoseLandmark\>)
- [x] Domain: `VideoAnalysis` entity (id, assessmentId, movementName, frames: List\<PoseFrame\>, detectedCompensations, analyzedAt)
- [x] Domain: `VideoAnalysisRepository` interface (save, getByAssessment, uploadVideo)
- [x] Domain: `PoseEstimationService` abstract interface (analyzeFrame, analyzeVideo)
- [x] Data: `FlutterPoseEstimationService` — wraps `flutter_pose_detection`, maps landmarks to domain entities
- [x] Data: `FirestoreVideoAnalysisDatasource` + `VideoAnalysisRepositoryImpl`
- [x] Video recording flow: `MovementRecordingPage` — camera screen guides user through all 5 movements, records per clip
- [x] Video analysis pipeline: upload → on-device NPU pose analysis → save to Firestore (via `AnalyzeMovementVideo` use case)
- [x] Extract joint angles from landmark positions via `PoseFrame.angleDegrees()` (available to Block 2)
- [x] Store analysis results in Firestore linked to assessment record (`videoAnalyses` collection)
- [x] Handle video compression before upload: `video_compress` MediumQuality before upload
- [x] Firebase Storage: upload clips to `users/{userId}/assessments/{assessmentId}/{movement}.mp4`
- [x] Tests: unit tests for landmark → joint angle calculation (pure math, no ML) — in `pose_frame_test.dart`, `pose_landmark_test.dart`
- [x] Tests: `AnalyzeMovementVideo` use case — 7 unit tests (upload fail, save fail, pose exception, ordering, etc.)
- [x] Tests: `FlutterPoseEstimationService` — full test coverage (frame/video/dispose lifecycle)

### UI — What to test

Navigate to the movement recording screen via `context.push(Routes.movementRecording, extra: {'assessmentId': '<id>', 'userId': '<uid>'})` or by completing the initial assessment flow (hook not yet wired — use direct push for now).

**What you should see:**

1. **Camera screen launches** — front camera preview fills the screen (black if camera unavailable). Dark gradient overlays at top and bottom.
2. **Top bar** — progress dots (5 total), current movement name ("Overhead Squat"), duration hint, instruction text in a dark rounded card.
3. **Bottom controls** — "Tap to start recording" label above a white circle button.
4. **Tap record button** — 3-second countdown overlay appears (large white number, animated scale switch). After countdown, camera starts recording.
5. **During recording** — button turns red with pulse animation, red "REC" badge appears at top of controls.
6. **Tap stop** — review state appears: green "Clip recorded" checkmark, "Retake" / "Next movement" buttons.
7. **Progress dots animate** — completed dots turn green and shrink, active dot stretches wide.
8. **After last movement → Analyse** — analysis overlay appears: dark background, `auto_awesome` icon, "Analysing your movement" text, animated progress bar + percentage.
9. **After analysis completes** — screen pops (returns `true` to caller).

**Edge cases to check:**
- Tap "Retake" → returns to recording controls for the same movement
- Camera unavailable → placeholder icon shown, tapping record advances without saving a path

---

## Block 2 — Compensation Detection ✅

- [x] Define compensation threshold rules as structured data (angle thresholds per movement per compensation)
- [x] `CompensationDetector` service: takes List\<PoseFrame\> + movement name → List\<DetectedCompensation\>
- [x] Map pose landmark angles to each Phase 1 `CompensationPattern` enum value
- [x] Score severity: mild (threshold exceeded < 30% of frames), moderate (30–60%), significant (>60%)
- [x] Generate `CompensationReport` from video analysis (one report per assessment)
- [x] Merge AI detection results with questionnaire-based results from Phase 1 (union, AI result takes precedence on severity)
- [x] Tests: unit tests for each threshold rule with boundary values (red → green TDD)

### What was implemented

- `CompensationSeverity` enum (`mild` / `moderate` / `significant`) with `fromFrameRatio()` factory
- `DetectedCompensation` entity — pattern + affectedFrameCount / totalFrameCount; `severity` derived from frame ratio; equality by pattern
- `CompensationReport` entity — holds `List<DetectedCompensation>`; provides `detectionFor()`, `sortedByPriority`, and the `merge()` factory constructor
- `VideoCompensationDetector` static service — evaluates each `PoseFrame` against threshold rules for the given `ScreeningMovement`:
  - **kneeValgus** (overheadSquat): knee X caves inward past ankle X by > 0.04 normalised units (≈ 10°)
  - **limitedDorsiflexion** (overheadSquat): heel Y rises above ankle Y by > 0.04 normalised units
  - **weakGluteMed** (singleLegStance): |leftHip.y − rightHip.y| > 0.05 normalised units (Trendelenburg drop)
  - **roundedShoulders** (shoulderRaise): hip→shoulder→elbow angle < 160° on either side
  - **forwardHeadPosture** (all movements): nose horizontal deviation from mid-shoulder > 15 % of shoulder width
- `CompensationReport.merge()` — union of questionnaire patterns and video detections; AI severity takes precedence; questionnaire-only patterns default to mild
- 43 passing unit tests (11 entity + 11 report + 21 detector)

### UI — What to test

Block 2 is a domain-layer feature with no new screens. The compensation detection results will surface in the assessment results UI (Block 3). There is nothing new to tap or see in the UI for Block 2 in isolation.

**To verify the detection logic is wired correctly:**
1. Run the unit tests: `flutter test lib/features/assessments/domain/entities/detected_compensation_test.dart lib/features/assessments/domain/entities/compensation_report_test.dart lib/features/assessments/domain/services/video_compensation_detector_test.dart`
2. All 43 tests should pass (green).

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

## Block 3 — AI-Generated Program Recommendations ✅

> **Approach: Rule-based engine (no external AI API).** Uses the existing `GetSuggestedGoals` mapping (`CompensationPattern → exerciseId`) and severity prioritization to generate programs deterministically. This keeps Block 3 consistent with the on-device architecture of Blocks 0-2 — no Cloud Function, no API keys, works offline. An LLM-enhanced version can be layered on later as an optional upgrade.

- [x] Domain: `ProgramRecommendationEngine` service — takes `CompensationReport` + `UserProfile` → `Program`
- [x] Prioritize compensations by severity (significant first, then moderate, then mild) using `CompensationReport.sortedByPriority`
- [x] Auto-select exercises from library using Phase 1 `CompensationPattern → exerciseId` mapping (already exists in `GetSuggestedGoals`)
- [x] Progressive template: weeks 1–2 corrective focus (high frequency, low load), weeks 3–4 integration (add strength), weeks 5+ maintenance
- [x] Filter exercises by user's available equipment (from `UserProfile.availableEquipment`)
- [x] Respect `UserProfile.trainingDaysPerWeek` when generating the `WeekTemplate`
- [x] Presentation: `AIRecommendationReviewPage` — show detected compensations + proposed program, allow per-exercise edits before accepting
- [x] On accept: call existing `CreateProgram` use case with generated template, link to assessment via `basedOnAssessment`
- [x] Tests: unit tests for priority ranking, exercise selection, equipment filtering, days-per-week distribution

### What was implemented

- `Program` entity and `ProgramModel` — added `basedOnAssessmentId` (nullable String) to link program to source assessment
- `ProgramRecommendationEngine` — pure Dart static service at `features/programs/domain/services/program_recommendation_engine.dart`:
  - Sorts compensations via `report.sortedByPriority` (significant → moderate → mild)
  - Collects exercise IDs in priority order using same pattern→exercise map as `GenerateProgramFromAssessment`
  - Equipment filter: bodyweight exercises always pass; equipment-dependent exercises (`ex_ys_ts`, `ex_face_pull`, `ex_thoracic_extension_bench`) require matching `UserProfile.availableEquipment`
  - Distributes exercises round-robin across training days (2 days: Mon/Thu; 3 days: Mon/Wed/Fri; 4: Mon/Tue/Thu/Fri; 5: Mon–Fri)
  - Sets `sets=3` for significant/moderate patterns, `sets=2` for mild
  - `Program.goal` encodes the 3-phase progression: "Weeks 1–2: corrective focus. Weeks 3–4: integration & strength. Weeks 5–8: maintenance."
  - Falls back to 6 bodyweight exercises when no compensations detected
- `AIRecommendationReviewPage` — at `features/programs/presentation/pages/ai_recommendation_review_page.dart`:
  - Compensation cards colour-coded by severity (red/significant, orange/moderate, green/mild)
  - Weekly schedule with 7-day cards; training days show exercise list
  - Tap exercise `sets×reps` badge → `AlertDialog` to edit sets and reps inline
  - Swipe close button removes exercise from day
  - Accept → `CreateProgramNotifier.submit()` → saves to Firestore with `isActive: true`, then navigates home
- Route `Routes.aiRecommendation = '/assessment/recommendation'` wired in `app_router.dart`
- 17 passing unit tests

### UI — What to test (Block 3)

Navigate via:

```dart
context.push(
  Routes.aiRecommendation,
  extra: {'report': compensationReport, 'profile': userProfile},
);
```

**What you should see:**

1. **AppBar** — "Your AI Program", slide-in transition
2. **Movement Analysis section** — compensation cards sorted by severity; each shows pattern name, severity badge, and % of frames
3. **Weekly Schedule section** — 7 day cards; training days (coloured header) show exercises; rest days show "Rest"
4. **Exercise row** — tap the `3×12` badge to edit sets/reps via dialog; tap × to remove the exercise
5. **Accept & Create Program button** — fills full width at bottom; shows spinner while saving; on success navigates home with snackbar

**Edge cases:**

- Empty report → "No compensations detected" card shown; fallback 6-exercise program generated
- No equipment → equipment-requiring exercises (Ys & Ts, Face Pull, Thoracic Extension Bench) excluded
- trainingDaysPerWeek=2 → only Mon and Thu are training days

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

```text
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
