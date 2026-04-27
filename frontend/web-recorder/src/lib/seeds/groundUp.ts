// "From the Ground Up" — Marco's physio-prescribed daily routine.
// Translated 1:1 from way2move's Flutter seed at:
//   frontend/mobile/lib/features/protocols/domain/usecases/seed_ground_up_for_user.dart
// All exercises every day, 1 set each, 6 weeks. Sage-tinted "daily routine".
//
// Educational metadata (intent / joints / compensations / muscles) drafted
// from physio cues (2026-04-26). PRI/DNS framing. Edit freely — these are
// starting points, not gospel.

import type { ExerciseBlock, Session } from "../types";
import { newId } from "../sessionStore";

export const GROUND_UP_WORKOUT_ID = "ground-up";
export const GROUND_UP_USER_ID = "marco";

// actualSets stays empty until the user logs each set — the completion
// chips/progress bar count `actualSets.length >= plannedSets` as "done",
// so pre-filling here would open the session 100%-complete on Start.

interface BlockSpec {
  exerciseId: string;
  category: string;
  directions: string;
  cues: string[];
  order: number;
  plannedSeconds?: number;
  plannedSets?: number;
  intent?: string;
  joints?: string[];
  compensations?: string[];
  muscles?: string[];
}

const block = (b: BlockSpec): ExerciseBlock => ({
  id: newId(),
  exerciseId: b.exerciseId,
  exerciseName: b.category,
  plannedSets: b.plannedSets ?? 1,
  plannedReps: 0, // unused — directions string carries the prescription
  plannedSeconds: b.plannedSeconds,
  defaultEffortKind: b.plannedSeconds ? "time" : "reps",
  restSeconds: 30,
  actualSets: [],
  phase: "main",
  level: "foundation",
  category: b.category,
  directions: b.directions,
  cuesOverride: b.cues,
  currentlyIncluded: true,
  order: b.order,
  intent: b.intent,
  joints: b.joints,
  compensations: b.compensations,
  muscles: b.muscles,
});

const blocks = (): ExerciseBlock[] => [
  block({
    exerciseId: "gu-foam-roller-bridge",
    category: "Foam Roller Bridge — Double Legged",
    directions: "1-2 sets of 15-30s",
    cues: [
      "Jelly belly — roll pelvis backward to flatten lower back without using abs",
      "Squash an orange under your arch as you lift the foot",
      "Lift hips just enough to slide a credit card under your bum",
      "Push through inside edge of foot — knee tracks toward midline",
    ],
    order: 1,
    plannedSeconds: 30,
    intent:
      "Train hip extension that comes from the glutes and hamstrings while keeping the lumbar spine quiet. Teach the foot to load through the inside edge so the knee tracks toward midline.",
    joints: ["hip extension", "ankle plantarflexion", "lumbar anti-extension"],
    compensations: [
      "lumbar hyperextension during hip extension",
      "anterior pelvic tilt",
      "foot supination",
    ],
    muscles: [
      "hamstrings (lower fibers)",
      "glute max (lower fibers)",
      "tibialis posterior",
      "intrinsic foot",
    ],
  }),

  block({
    exerciseId: "gu-single-leg-midfoot-bridge",
    category: "Single-Leg Midfoot Bridge (opposite knee to chest)",
    directions: "1-2 sets of 30-45s per side",
    cues: [
      "Sock under arch — keep contact with inner edge of foot",
      "Foot away from bum — heel barely lifting off the floor",
    ],
    order: 2,
    plannedSeconds: 45,
    intent:
      "Isolate one-side hip extension while loading the midfoot. Build the same arch + glute pattern as the double-leg version, one side at a time, exposing left-right asymmetry.",
    joints: ["hip extension (unilateral)", "opposite hip flexion", "ankle plantarflexion"],
    compensations: ["lateral pelvis drop", "lumbar rotation", "foot supination"],
    muscles: [
      "glute max",
      "hamstrings",
      "tibialis posterior",
      "contralateral psoas (active)",
    ],
  }),

  block({
    exerciseId: "gu-calf-bridge",
    category: "Calf Bridge",
    directions: "1-2 sets x 15-30s per leg",
    cues: ["Push through ball of big toe"],
    order: 3,
    plannedSeconds: 30,
    intent:
      "Train end-range plantarflexion through the big toe knuckle so the calf and foot finish the extension chain together.",
    joints: ["ankle plantarflexion", "hip extension", "big toe extension (terminal)"],
    compensations: ["ankle inversion", "weight shift to outer foot"],
    muscles: [
      "gastrocnemius",
      "soleus",
      "flexor hallucis longus",
      "glute max",
    ],
  }),

  block({
    exerciseId: "gu-side-lying-scissor-slides",
    category: "Side-lying Scissor Slides — both directions",
    directions: "1 set of 10 reps per side, last rep 3-5 breaths",
    cues: ["Pull back with top heel, no bum activation"],
    order: 4,
    intent:
      "Move through hip flexion and extension passively in side-lying without bracing — teach hip dissociation from the spine.",
    joints: ["hip flexion + extension (sagittal sweep)", "pelvic stability"],
    compensations: ["lumbar rotation", "rib flare", "gluteal substitution"],
    muscles: [
      "psoas (eccentric/concentric)",
      "hamstrings",
      "deep core",
      "lateral hip stabilizers",
    ],
  }),

  block({
    exerciseId: "gu-half-kneeling-adductor-pullback",
    category: "Half-Kneeling Adductor Pullback",
    directions: "5 breaths at end range, then 5 reps",
    cues: ["Knee in front of ankle", "Pull lead heel back"],
    order: 5,
    intent:
      "Open the inner thigh and load the adductors at end range. The lead heel pulls back so the hip travels under the ribs, not the back arching.",
    joints: ["hip abduction (groin opening)", "hip extension on front leg", "knee stability"],
    compensations: [
      "lumbar extension to fake hip extension",
      "foot eversion on the lead foot",
    ],
    muscles: [
      "adductor magnus",
      "glute med",
      "glute max",
      "deep core",
    ],
  }),

  block({
    exerciseId: "gu-posterior-capsule-stretch",
    category: "Posterior Capsule Stretch — stay upright",
    directions: "2 sets of 5-10 breaths per side",
    cues: ["Slide pelvis toward stretching butt"],
    order: 6,
    plannedSets: 2,
    intent:
      "Lengthen the back of the hip socket without flexing the spine. Pelvis slides into the stretching side; torso stays upright.",
    joints: ["hip extension (end-range)", "pelvic translation", "thoracic upright"],
    compensations: ["lumbar extension", "anterior pelvic tilt"],
    muscles: [
      "posterior hip capsule (passive)",
      "psoas (lengthened)",
      "glute max (eccentric)",
    ],
  }),

  block({
    exerciseId: "gu-coiling-posterior-capsule-stretch",
    category: "Coiling Core POSTERIOR Capsule Stretch",
    directions: "2 sets of 5-10 breaths per side",
    cues: ["Same setup + coiling cue through the core"],
    order: 7,
    plannedSets: 2,
    intent:
      "Add active core engagement to the posterior capsule stretch — coil the ribs over the pelvis to deepen the stretch while staying organized.",
    joints: ["hip extension", "thoracic flexion (light coil)", "rib-pelvis stack"],
    compensations: ["lumbar extension", "anterior rib flare"],
    muscles: [
      "transverse abdominis",
      "obliques",
      "posterior hip capsule (passive)",
    ],
  }),

  block({
    exerciseId: "gu-coiling-posterior-lateral-hip-stretch",
    category: "Coiling Core Posterior LATERAL Hip Capsule Stretch",
    directions: "2 sets of 5-10 breaths per side",
    cues: [],
    order: 8,
    plannedSets: 2,
    intent:
      "Same coiling core engagement, but rotate the stretch to the lateral capsule of the hip — teach the side of the hip to release while ribs stay coiled.",
    joints: ["hip adduction + extension (frontal/sagittal blend)", "thoracic rotation"],
    compensations: ["lumbar side-bend", "lateral pelvic tilt"],
    muscles: [
      "glute med (posterior fibers)",
      "TFL",
      "lateral hip capsule (passive)",
      "obliques",
    ],
  }),

  block({
    exerciseId: "gu-kickstand-chop",
    category: "Kickstand Chop (with wedges)",
    directions: "Quality over count",
    cues: ["Big toe knuckle heavy", "Lean opposite shoulder forward"],
    order: 9,
    intent:
      "Train the closed-chain stance leg to load the inside of the foot while the opposite shoulder reaches across the body — integrate stance + reach in a rotational pattern.",
    joints: ["hip flexion (stance)", "thoracic rotation", "shoulder flexion + adduction"],
    compensations: [
      "foot supination",
      "lumbar rotation",
      "contralateral pelvic drop",
    ],
    muscles: [
      "hip adductors",
      "glute med (stance)",
      "serratus anterior",
      "obliques (anti-rotation)",
    ],
  }),

  block({
    exerciseId: "gu-foot-flattener",
    category: "Foot Flattener (back foot off floor)",
    directions: "1-2 sets of 6 slow reps per side",
    cues: ["HEAVY heel", "Relaxed toes"],
    order: 10,
    intent:
      "Load the heel and ground reaction force through the calcaneus and arch — teach the foot to spread flat under load, not curl into supination.",
    joints: ["ankle dorsiflexion", "subtalar pronation", "hip flexion (stance)"],
    compensations: ["ankle inversion", "toe gripping", "knee valgus"],
    muscles: [
      "tibialis posterior",
      "peroneus longus",
      "intrinsic foot",
      "glute med",
    ],
  }),

  block({
    exerciseId: "gu-split-stance-contralateral-reach",
    category: "Split Stance Contralateral Reach",
    directions: "1-2 sets of 4-8 per side",
    cues: ["Hip outside foot", "Inside edge glued"],
    order: 11,
    intent:
      "Train hip-over-foot stance under reach load — back hip extends while the front foot holds its arch and the inside edge stays grounded.",
    joints: ["hip extension (back)", "hip flexion (front)", "thoracic rotation"],
    compensations: ["lateral pelvis drop", "foot supination", "lumbar extension"],
    muscles: [
      "glute max (back)",
      "adductor magnus",
      "glute med",
      "obliques",
    ],
  }),
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
