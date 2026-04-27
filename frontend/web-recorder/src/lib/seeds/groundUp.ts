// "From the Ground Up" — Marco's physio-prescribed daily routine.
// Translated 1:1 from way2move's Flutter seed at:
//   frontend/mobile/lib/features/protocols/domain/usecases/seed_ground_up_for_user.dart
// All exercises every day, 1 set each, 6 weeks. Sage-tinted "daily routine".

import type { ExerciseBlock, Session } from "../types";
import { newId } from "../sessionStore";

export const GROUND_UP_WORKOUT_ID = "ground-up";
export const GROUND_UP_USER_ID = "marco";

// actualSets stays empty until the user logs each set — the completion
// chips/progress bar count `actualSets.length >= plannedSets` as "done",
// so pre-filling here would open the session 100%-complete on Start.

// All 11 exercise blocks, prescribed by physio (2026-04-26).
// Order matters — the routine is meant to be done top-to-bottom.
const block = (
  exerciseId: string,
  category: string,
  plannedReps: string,
  directions: string,
  cues: string[],
  order: number,
  plannedSeconds?: number,
): ExerciseBlock => ({
  id: newId(),
  exerciseId,
  // exerciseName falls back to category for the recorder's existing labels.
  // ActiveSession will prefer block.category over exerciseName when present.
  exerciseName: category,
  plannedSets: 1,
  plannedReps: 0, // unused — directions string carries the prescription
  plannedSeconds,
  defaultEffortKind: plannedSeconds ? "time" : "reps",
  restSeconds: 30,
  actualSets: [],
  phase: "main",
  level: "foundation",
  category,
  directions,
  cuesOverride: cues,
  currentlyIncluded: true,
  order,
});

// Slug here is for human readability; ActiveSession uses the override fields.
// `plannedReps` field is kept (even if 0) to satisfy the schema and let any
// existing UI that reads it still render something.
const blocks = (): ExerciseBlock[] => [
  block(
    "gu-foam-roller-bridge",
    "Foam Roller Bridge — Double Legged",
    "1-2 sets of 15-30s",
    "1-2 sets of 15-30s",
    [
      "Jelly belly — roll pelvis backward to flatten lower back without using abs",
      "Squash an orange under your arch as you lift the foot",
      "Lift hips just enough to slide a credit card under your bum",
      "Push through inside edge of foot — knee tracks toward midline",
    ],
    1,
    30,
  ),
  block(
    "gu-single-leg-midfoot-bridge",
    "Single-Leg Midfoot Bridge (opposite knee to chest)",
    "1-2 sets of 30-45s per side",
    "1-2 sets of 30-45s per side",
    [
      "Sock under arch — keep contact with inner edge of foot",
      "Foot away from bum — heel barely lifting off the floor",
    ],
    2,
    45,
  ),
  block(
    "gu-calf-bridge",
    "Calf Bridge",
    "1-2 sets x 15-30s per leg",
    "1-2 sets x 15-30s per leg",
    ["Push through ball of big toe"],
    3,
    30,
  ),
  block(
    "gu-side-lying-scissor-slides",
    "Side-lying Scissor Slides — both directions",
    "1 set of 10 reps per side, last rep 3-5 breaths",
    "1 set of 10 reps per side, last rep 3-5 breaths",
    ["Pull back with top heel, no bum activation"],
    4,
  ),
  block(
    "gu-half-kneeling-adductor-pullback",
    "Half-Kneeling Adductor Pullback",
    "5 breaths at end range, then 5 reps",
    "5 breaths at end range, then 5 reps",
    ["Knee in front of ankle", "Pull lead heel back"],
    5,
  ),
  {
    ...block(
      "gu-posterior-capsule-stretch",
      "Posterior Capsule Stretch — stay upright",
      "2 sets of 5-10 breaths per side",
      "2 sets of 5-10 breaths per side",
      ["Slide pelvis toward stretching butt"],
      6,
    ),
    plannedSets: 2,
  },
  {
    ...block(
      "gu-coiling-posterior-capsule-stretch",
      "Coiling Core POSTERIOR Capsule Stretch",
      "2 sets of 5-10 breaths per side",
      "2 sets of 5-10 breaths per side",
      ["Same setup + coiling cue through the core"],
      7,
    ),
    plannedSets: 2,
  },
  {
    ...block(
      "gu-coiling-posterior-lateral-hip-stretch",
      "Coiling Core Posterior LATERAL Hip Capsule Stretch",
      "2 sets of 5-10 breaths per side",
      "2 sets of 5-10 breaths per side",
      [],
      8,
    ),
    plannedSets: 2,
  },
  block(
    "gu-kickstand-chop",
    "Kickstand Chop (with wedges)",
    "Quality over count",
    "Quality over count",
    ["Big toe knuckle heavy", "Lean opposite shoulder forward"],
    9,
  ),
  block(
    "gu-foot-flattener",
    "Foot Flattener (back foot off floor)",
    "1-2 sets of 6 slow reps per side",
    "1-2 sets of 6 slow reps per side",
    ["HEAVY heel", "Relaxed toes"],
    10,
  ),
  block(
    "gu-split-stance-contralateral-reach",
    "Split Stance Contralateral Reach",
    "1-2 sets of 4-8 per side",
    "1-2 sets of 4-8 per side",
    ["Hip outside foot", "Inside edge glued"],
    11,
  ),
];

/**
 * Build a fresh Ground Up session for today. Caller is responsible for
 * upserting it into localStorage. Returns a complete Session ready to open
 * in ActiveSession.
 */
export const buildGroundUpSession = (
  todayISO: string,
  userId: string = GROUND_UP_USER_ID,
): Session => ({
  id: newId(),
  userId,
  type: "training",
  focus: "From the Ground Up",
  date: todayISO,
  status: "planned",
  exerciseBlocks: blocks(),
  recordings: [],
  source: "in-app-recorder",
  idempotencyKey: `ground-up:${userId}:${todayISO}`,
  workoutId: GROUND_UP_WORKOUT_ID,
  kind: "fromGroundUp",
  slot: "flexible",
});
