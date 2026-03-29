# Phase 2 — AI Movement Assessment: Implementation Checklist

> **Depends on:** Phase 1 (Assessment System, Exercise Library)
> **Can run parallel with:** Phase 3, Phase 5
> **Blocks:** nothing

---

## Block 0 — ML Model Integration

- [ ] Evaluate and select pose estimation framework (MediaPipe vs ML Kit)
- [ ] Integrate pose estimation SDK into Flutter project
- [ ] Build PoseEstimationService wrapper (abstract interface + implementation)
- [ ] Create landmark extraction pipeline (key joint positions per frame)
- [ ] Handle on-device inference (no server round-trip for pose detection)
- [ ] Tests: unit tests for pose data parsing and landmark extraction

---

## Block 1 — Video Analysis Pipeline

- [ ] Domain: VideoAnalysis entity (id, assessmentId, exerciseName, frames, landmarks, compensations)
- [ ] Process recorded screening videos frame-by-frame through pose estimator
- [ ] Extract joint angles and positions at key movement checkpoints
- [ ] Store analysis results linked to assessment record
- [ ] Handle video compression and storage (Firebase Storage)
- [ ] Tests: integration tests with sample video data

---

## Block 2 — Compensation Detection

- [ ] Define compensation pattern rules as structured data (e.g., knee valgus = knee angle < threshold during squat)
- [ ] Map pose landmark data to compensation patterns for each screening movement
- [ ] Score severity of each detected compensation (mild/moderate/significant)
- [ ] Generate compensation report from video analysis results
- [ ] Compare AI detection results with questionnaire-based detection (Phase 1)
- [ ] Tests: unit tests for each compensation detection rule

---

## Block 3 — AI-Generated Program Recommendations

- [ ] Build recommendation engine: map detected compensations to corrective exercise priorities
- [ ] Auto-select exercises from library based on compensation severity and user equipment
- [ ] Generate progressive program template (weeks 1-4 corrective focus, weeks 5+ integration)
- [ ] Allow user to review and modify AI-generated program before accepting
- [ ] Tests: unit tests for recommendation logic

---

## Block 4 — Before/After Comparison UI

- [ ] Side-by-side video playback (initial assessment vs re-assessment)
- [ ] Overlay pose landmarks on video with color-coded joint quality
- [ ] Score comparison chart (initial vs current for each movement pattern)
- [ ] Compensation reduction summary (what improved, what needs more work)
- [ ] Tests: widget tests for comparison UI components

---

## Block 5 — Re-Assessment Scheduling and Notifications

- [ ] Schedule periodic re-assessments (default every 4 weeks, configurable)
- [ ] Push notifications for upcoming re-assessment
- [ ] Re-assessment flow reuses video recording + adds AI analysis
- [ ] Track assessment history timeline with trend indicators
- [ ] Tests: unit tests for scheduling logic
