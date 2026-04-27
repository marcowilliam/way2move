// Mirrors way2move's session domain so the recorder can swap localStorage
// for Firestore later without changing screens.
// Reference: way2move/main/frontend/mobile/lib/features/sessions/domain/entities/session.dart

export type SessionStatus = "planned" | "in_progress" | "completed" | "skipped";
export type SessionType = "training" | "recovery" | "mobility" | "breathing";
export type Source =
  | "in-app-typed"
  | "in-app-voice"
  | "in-app-recorder"   // <- new value for v1 web recorder
  | "assistant-ingest"
  | "assistant-edit";

export type EffortKind = "reps" | "time";

// Training-week organizer extensions. Mirror way2move's domain enums.
export type ExercisePhase = "warmUp" | "main" | "coolDown";
export type ExerciseLevel = "foundation" | "developmental" | "advanced";
export type WorkoutKind =
  | "fromGroundUp"
  | "abcde"
  | "snack"
  | "bodybuilding"
  | "themed";
export type SessionSlot =
  | "morning"
  | "midday"
  | "afternoon"
  | "evening"
  | "flexible";
export type SessionPlace = "home" | "gym" | "outdoor" | "other";
export type DurationCategory = "snack" | "short" | "medium" | "long";

// Sensation capture — body-listening, not effort. Mirrors Flutter
// SensationFeedback shape (good/struggling chips, 1-5, notes).
export interface SensationFeedback {
  goodAreas: string[];
  strugglingAreas: string[];
  score: number; // 1-5
  notes?: string;
  capturedAt?: string;
}

// One row of effort inside a set. A set is reps-OR-time-based per row,
// so a single set can log multiple rows — e.g. "15s @ 5kg" then "15s @ 2kg"
// when the athlete drops the weight mid-set.
export interface EffortRow {
  id: string;
  kind: EffortKind;
  reps?: number;      // set when kind === "reps"
  seconds?: number;   // set when kind === "time"
  weight?: number;    // optional
}

export interface SetEntry {
  setNumber: number;
  rows: EffortRow[];
  completed: boolean;
  // Legacy top-level fields — kept optional for forwards-readability of
  // old localStorage blobs; new writes never populate them.
  reps?: number;
  weight?: number;
}

export interface ExerciseBlock {
  id: string;
  exerciseId: string;
  exerciseName: string;
  plannedSets: number;
  plannedReps: number;
  plannedSeconds?: number;         // for time-based (isometric) exercises
  defaultEffortKind?: EffortKind;  // "reps" (default) or "time"
  plannedWeight?: number;          // optional hint for the first log row
  restSeconds: number;
  actualSets: SetEntry[];
  rpe?: number;
  notes?: string;

  // Training-week organizer extensions (all optional, forward-compat).
  // When `category` is set, the hero card prefers it over `exerciseName`.
  // `cuesOverride` replaces the exercise's default cues for THIS block.
  phase?: ExercisePhase;
  level?: ExerciseLevel;
  category?: string;
  directions?: string;
  cuesOverride?: string[];
  currentlyIncluded?: boolean;
  order?: number;

  // Educational metadata — the "why" of this exercise. Written by Marco /
  // drafted by AI from cues + name. Renders in a Sage card above the cues.
  // Marco's training framing: PRI/DNS, body-listening, compensation patterns.
  intent?: string;          // 1-2 sentences: what am I teaching my body
  joints?: string[];        // joint actions worked, e.g. "hip extension"
  compensations?: string[]; // patterns being trained AGAINST, e.g. "lumbar hyperextension"
  muscles?: string[];       // primary + stabilizers, e.g. "glute max (lower fibers)"
}

export interface Recording {
  id: string;
  exerciseBlockId: string;
  setNumber: number;     // which set this recording belongs to
  takeNumber: number;    // 1, 2, 3 if redone
  localPath: string;     // absolute path on disk where the file lives
  fileName: string;
  mimeType: string;
  durationSec: number;
  recordedAt: string;    // ISO timestamp
}

// Body check-in vocabulary matches the brand's "your body is listening"
// frame — words, not emoji faces.
export type BodyFeeling = "calm" | "neutral" | "fatigued" | "depleted";

export interface Session {
  id: string;
  userId: string;        // in v1 just "marco"
  programId?: string;
  type: SessionType;
  focus?: string;
  date: string;          // YYYY-MM-DD
  status: SessionStatus;
  exerciseBlocks: ExerciseBlock[];
  recordings: Recording[];
  notes?: string;
  durationMinutes?: number;
  // Session-level finalization fields (set in the review screen).
  rpe?: number;                 // 1-10 Rate of Perceived Exertion
  bodyFeeling?: BodyFeeling;    // post-session body check-in
  source: Source;
  idempotencyKey: string;
  startedAt?: string;
  completedAt?: string;

  // Training-week organizer extensions (all optional).
  workoutId?: string;
  kind?: WorkoutKind;
  slot?: SessionSlot;
  place?: SessionPlace;
  durationCategory?: DurationCategory;
  sensationFeedback?: SensationFeedback;
}

// Canonical library entry. Seed exercises ship with the app; "user-created"
// ones go to the evaluate bucket until an AI promotes them. See memory:
// evaluate_exercises_pattern.md for the full architectural context.
export type ExerciseSource = "seed" | "user-created" | "promoted";
export type ExerciseEvaluationStatus = "pending" | "promoted" | "rejected" | "merged";

export interface Exercise {
  id: string;
  name: string;
  defaultEffortKind: EffortKind;
  defaultReps?: number;
  defaultSeconds?: number;
  defaultWeight?: number;
  defaultSets?: number;
  defaultRestSeconds?: number;
  source: ExerciseSource;
  evaluationStatus?: ExerciseEvaluationStatus;
  canonicalExerciseId?: string;
  createdAt: string;
}

export interface CameraAssignment {
  slot: 0 | 1 | 2;
  deviceId: string;
  label: string;
}

export interface RecorderSettings {
  cameras: CameraAssignment[];
  rootFolderName?: string;   // display only — the actual handle is in IndexedDB
}
