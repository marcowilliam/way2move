// AUTO-GENERATED from Marco's Notion export.
// Regenerate with: python3 scripts/import-notion-workouts.py <notion-export-base-dir>
// Do NOT edit by hand — re-run the import script instead.

import type { WorkoutTemplate } from '../workoutTemplates';

/* eslint-disable */
export const notionWorkouts: WorkoutTemplate[] = [
  {
    "id": "notion-day-a-anterior-chain-flexion",
    "name": "DAY A — ANTERIOR CHAIN + FLEXION",
    "emoji": "🔵",
    "intent": null,
    "primaryPlane": "Sagital",
    "jointsMovements": [
      "Anti-extension",
      "Hip flexion",
      "Shoulder flexion"
    ],
    "kind": null,
    "source": "notion-export",
    "notionPath": "🔵 DAY A — ANTERIOR CHAIN + FLEXION",
    "blocks": [
      {
        "exerciseId": "supine-dns-breathing",
        "exerciseName": "Supine DNS breathing",
        "category": "Spine anti-extension",
        "directions": "• 2–3 sets × 5–6 slow breaths",
        "cuesOverride": [
          "ribs melt down, pelvis heavy, no ab bracing"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": 1,
        "currentlyIncluded": true,
        "intent": "Reset the rib-pelvis stack and let the diaphragm do the work without the abs gripping. The baseline that every other exercise builds on.",
        "joints": [
          "rib-pelvis stack",
          "diaphragm excursion"
        ],
        "compensations": [
          "anterior rib flare",
          "ab bracing instead of breathing"
        ],
        "muscles": [
          "diaphragm",
          "transverse abdominis (passive)",
          "intercostals"
        ]
      },
      {
        "exerciseId": "supine-arm-reach-dns",
        "exerciseName": "Supine arm reach (DNS)",
        "category": "Shoulder Flexion / Overhead",
        "directions": "• 2 sets × 6–8 slow reps\n• 3s reach / 3s return",
        "cuesOverride": [
          "Stop before ribs lift"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": 2,
        "currentlyIncluded": true,
        "intent": "Reach overhead while the ribs stay down — teach scapular upward rotation without rib flare or lumbar extension.",
        "joints": [
          "shoulder flexion",
          "scapular upward rotation",
          "thoracic anti-extension"
        ],
        "compensations": [
          "anterior rib flare",
          "lumbar extension during reach"
        ],
        "muscles": [
          "serratus anterior",
          "lower trap",
          "deep core"
        ]
      },
      {
        "exerciseId": "supine-hip-flexion-control",
        "exerciseName": "Supine hip flexion control",
        "category": "Hip flexion",
        "directions": "• 2 sets × 5–6 reps / side\n• 3s lift / 3s lower",
        "cuesOverride": [
          "Pelvis stays neutral"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": 3,
        "currentlyIncluded": true,
        "intent": "Lift the leg from the hip flexors with the pelvis quiet — train hip dissociation from the lumbar spine.",
        "joints": [
          "hip flexion",
          "lumbo-pelvic stability"
        ],
        "compensations": [
          "anterior pelvic tilt during hip flexion",
          "lumbar extension"
        ],
        "muscles": [
          "psoas",
          "iliacus",
          "transverse abdominis"
        ]
      },
      {
        "exerciseId": "hip-flexor-kick-out",
        "exerciseName": "Hip flexor kick-out",
        "category": "Hip flexion",
        "directions": "1–2 sets × 6–8 reps / side",
        "cuesOverride": [
          "Slow and controlled"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": 4,
        "currentlyIncluded": true,
        "intent": "Train the high-end of hip flexor strength (above 90°) slowly and under control — build endurance where the leg is most demanding to hold.",
        "joints": [
          "hip flexion (>90°)",
          "knee extension"
        ],
        "compensations": [
          "lumbar extension to substitute for psoas"
        ],
        "muscles": [
          "psoas",
          "iliacus",
          "rectus femoris (terminal)"
        ]
      },
      {
        "exerciseId": "quadruped-arm-lift",
        "exerciseName": "Quadruped arm lift",
        "category": "Shoulder Flexion / Overhead",
        "directions": "• 3 sets × 6 reps / side\n• 3s lift, 3s lower\n• Rest ~45–60s",
        "cuesOverride": [
          "Stop set if ribs shift"
        ],
        "phase": null,
        "level": "foundation",
        "order": 5,
        "currentlyIncluded": true,
        "intent": "Reach an arm forward without the ribs shifting — anti-rotation under load through the trunk.",
        "joints": [
          "shoulder flexion",
          "thoracic anti-rotation",
          "rib-pelvis stack"
        ],
        "compensations": [
          "rib shift toward unloaded side",
          "lumbar rotation"
        ],
        "muscles": [
          "obliques (anti-rotation)",
          "serratus anterior",
          "deep core"
        ]
      },
      {
        "exerciseId": "dead-bug",
        "exerciseName": "Dead bug",
        "category": "Spine anti-extension",
        "directions": "• 3 sets × 6–8 reps / side\n• 3s extend, 3s return\n• Rest ~45s",
        "cuesOverride": [],
        "phase": null,
        "level": "foundation",
        "order": 6,
        "currentlyIncluded": true,
        "intent": "Move opposite arm and leg while the lumbar spine stays glued to the floor — disconnect limb motion from spine motion.",
        "joints": [
          "hip flexion + extension",
          "shoulder flexion + extension",
          "lumbar anti-extension"
        ],
        "compensations": [
          "lumbar extension off the floor as limbs lengthen"
        ],
        "muscles": [
          "transverse abdominis",
          "obliques",
          "psoas"
        ]
      },
      {
        "exerciseId": "seated-floor-straight-leg-raises",
        "exerciseName": "Seated Floor Straight-Leg Raises",
        "category": null,
        "directions": "3–4 sets × 4–8 reps1–2 sec lift / 3–4 sec slow lower",
        "cuesOverride": [
          "Posterior pelvic tilt first (non-negotiable)Ribs down, spine longHands press into floor beside hipsLegs straight, toes pulled backExhale → lift both legs a few cmSlow controlled lower without losing tiltReset pelvis between reps if needed"
        ],
        "phase": null,
        "level": null,
        "order": 7,
        "currentlyIncluded": true,
        "intent": "Posterior pelvic tilt FIRST, then lift — teach the deep core to tilt the pelvis before the hip flexors fire.",
        "joints": [
          "hip flexion",
          "posterior pelvic tilt",
          "knee extension"
        ],
        "compensations": [
          "anterior pelvic tilt",
          "lumbar extension"
        ],
        "muscles": [
          "transverse abdominis",
          "psoas",
          "rectus femoris",
          "rectus abdominis"
        ]
      },
      {
        "exerciseId": "bent-knee-l-sit",
        "exerciseName": "Bent-knee L-sit",
        "category": "Hip flexion",
        "directions": "• 4–5 sets × 10–20s\n• Rest ~60s",
        "cuesOverride": [
          "Spine tall, no hip shift"
        ],
        "phase": null,
        "level": "foundation",
        "order": 8,
        "currentlyIncluded": true,
        "intent": "Hold a tall spine with knees lifted — train hip flexor endurance with active scapular depression.",
        "joints": [
          "hip flexion",
          "scapular depression",
          "thoracic upright"
        ],
        "compensations": [
          "pelvic shift to one side",
          "shoulder shrug to lift"
        ],
        "muscles": [
          "psoas",
          "lower trap",
          "lats",
          "deep core"
        ]
      },
      {
        "exerciseId": "reverse-squat",
        "exerciseName": "Reverse squat",
        "category": "Spine anti-extension",
        "directions": "3–4 sets × 6–10 reps",
        "cuesOverride": [
          "Slow eccentric",
          "Spine stays tall"
        ],
        "phase": null,
        "level": null,
        "order": 9,
        "currentlyIncluded": true,
        "intent": "Slow eccentric lowering with a tall spine — load the hip flexors and quads through full range with no spine compensation.",
        "joints": [
          "hip flexion",
          "knee flexion",
          "ankle dorsiflexion"
        ],
        "compensations": [
          "lumbar extension",
          "knee valgus"
        ],
        "muscles": [
          "quads (eccentric)",
          "psoas",
          "glute max",
          "deep core"
        ]
      },
      {
        "exerciseId": "deep-squat-breath",
        "exerciseName": "Deep squat breath",
        "category": null,
        "directions": "2–3 sets × 5–8 breaths",
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": 10,
        "currentlyIncluded": true,
        "intent": "Sit in the bottom of the squat and breathe into the back of the body — restore hip + ankle range while the diaphragm works.",
        "joints": [
          "hip flexion (deep)",
          "ankle dorsiflexion",
          "thoracic upright"
        ],
        "compensations": [
          "heel lift",
          "lumbar flexion collapse"
        ],
        "muscles": [
          "diaphragm",
          "adductors (length)",
          "soleus (length)"
        ]
      },
      {
        "exerciseId": "standing-overhead-press-isometric-hold",
        "exerciseName": "Standing overhead press isometric hold",
        "category": "Shoulder Flexion / Overhead",
        "directions": "2–3 sets × 20–30s",
        "cuesOverride": [
          "Light load",
          "Ribs stacked, scap upward rotation"
        ],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Hold a light load overhead with ribs stacked and scaps upwardly rotated — train the standing posture under shoulder load.",
        "joints": [
          "shoulder flexion (terminal)",
          "scapular upward rotation",
          "rib-pelvis stack"
        ],
        "compensations": [
          "anterior rib flare under load",
          "lumbar extension"
        ],
        "muscles": [
          "serratus anterior",
          "lower trap",
          "deep core",
          "deltoid"
        ]
      },
      {
        "exerciseId": "loaded-butterfly",
        "exerciseName": "Loaded butterfly",
        "category": null,
        "directions": null,
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Lengthen the inner thigh and hip rotators under light load — prep the hips for deep flexion.",
        "joints": [
          "hip external rotation",
          "hip abduction",
          "lumbar anti-extension"
        ],
        "compensations": [
          "lumbar extension to deepen the stretch"
        ],
        "muscles": [
          "adductors (length)",
          "deep hip rotators (length)",
          "deep core"
        ]
      },
      {
        "exerciseId": "hanging-leg-raise",
        "exerciseName": "Hanging leg raise",
        "category": "Hip flexion",
        "directions": "3–4 sets × 4–8 reps",
        "cuesOverride": [
          "Posterior pelvic tilt first",
          "Slow lower"
        ],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Raise the legs from the deep core, not the hip flexors — posterior pelvic tilt first, then the legs follow.",
        "joints": [
          "hip flexion",
          "posterior pelvic tilt",
          "lumbar flexion"
        ],
        "compensations": [
          "swinging momentum",
          "anterior pelvic tilt"
        ],
        "muscles": [
          "rectus abdominis (lower fibers)",
          "transverse abdominis",
          "psoas"
        ]
      },
      {
        "exerciseId": "l-sit",
        "exerciseName": "L-sit",
        "category": "Hip flexion",
        "directions": "• 4–6 sets × 5–15s\n• Rest ~90s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Static hold with legs out straight and scaps depressed — full anterior chain + scapular endurance.",
        "joints": [
          "hip flexion",
          "knee extension",
          "scapular depression"
        ],
        "compensations": [
          "pelvic asymmetry",
          "shoulder elevation"
        ],
        "muscles": [
          "psoas",
          "rectus femoris",
          "lower trap",
          "lats",
          "transverse abdominis"
        ]
      },
      {
        "exerciseId": "push-up-plus",
        "exerciseName": "Push-up plus",
        "category": "Shoulder Flexion / Overhead",
        "directions": "• 3 sets × 6–10 reps\n• 2s protraction hold at top\n• Rest ~60s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "After the push-up's top, push further to upwardly rotate the scaps — train serratus anterior, the missing piece of most push-ups.",
        "joints": [
          "shoulder flexion",
          "scapular protraction + upward rotation"
        ],
        "compensations": [
          "winging scapula",
          "rib flare at the top"
        ],
        "muscles": [
          "serratus anterior",
          "pec minor (length)",
          "deep core"
        ]
      },
      {
        "exerciseId": "active-hang",
        "exerciseName": "Active hang",
        "category": "Shoulder Flexion / Overhead",
        "directions": "• 4–6 sets × 15–30s\n• Rest ~60–90s",
        "cuesOverride": [
          "Scapula slightly depressed + upward rotation",
          "No elbow bend"
        ],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Hang with scaps slightly depressed and upwardly rotated, no elbow bend — build a stable shoulder under traction.",
        "joints": [
          "shoulder flexion (overhead)",
          "scapular depression + upward rotation"
        ],
        "compensations": [
          "passive shoulder shrug",
          "elbow bend"
        ],
        "muscles": [
          "lower trap",
          "lats",
          "rotator cuff",
          "grip"
        ]
      }
    ]
  },
  {
    "id": "notion-day-b-posterior-chain-extension",
    "name": "DAY B — POSTERIOR CHAIN + EXTENSION",
    "emoji": "🟢",
    "intent": null,
    "primaryPlane": null,
    "jointsMovements": [],
    "kind": null,
    "source": "notion-export",
    "notionPath": "🟢 DAY B — POSTERIOR CHAIN + EXTENSION",
    "blocks": [
      {
        "exerciseId": "foam-roller-bridge-double-leg",
        "exerciseName": "Foam roller bridge (double-leg)",
        "category": null,
        "directions": "1–2 sets × 20–30s holds",
        "cuesOverride": [
          "Knees lightly hugging roller"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Hip extension that comes from glutes + hamstrings while the lumbar stays quiet — knees lightly hugging the roller adds adductor engagement.",
        "joints": [
          "hip extension",
          "knee adduction (light)",
          "lumbar anti-extension"
        ],
        "compensations": [
          "lumbar hyperextension",
          "knee bowing out"
        ],
        "muscles": [
          "glute max (lower fibers)",
          "hamstrings",
          "adductor magnus"
        ]
      },
      {
        "exerciseId": "glute-bridge",
        "exerciseName": "Glute bridge",
        "category": null,
        "directions": "• 2 sets × 6–8 reps\n• 3s up / 3s down",
        "cuesOverride": [
          "Push through midfoot",
          "Ribs stay down",
          "No hamstring cramp"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Drive the hips up through the midfoot, ribs stay down — the cleanest entry to glute-driven hip extension.",
        "joints": [
          "hip extension",
          "ankle dorsiflexion (heel pressure)"
        ],
        "compensations": [
          "lumbar extension",
          "hamstring cramp from over-shortening"
        ],
        "muscles": [
          "glute max",
          "hamstrings",
          "transverse abdominis"
        ]
      },
      {
        "exerciseId": "supine-arm-extension",
        "exerciseName": "Supine arm extension",
        "category": null,
        "directions": "• 2 sets × 6–8 slow reps\n• 3s reach back / 3s return",
        "cuesOverride": [
          "Stop before ribs pop or neck pulls"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Take the arm overhead in extension without the ribs popping or the neck pulling — teach end-range shoulder extension with anterior chain control.",
        "joints": [
          "shoulder extension (overhead)",
          "thoracic anti-extension"
        ],
        "compensations": [
          "rib flare",
          "neck protraction"
        ],
        "muscles": [
          "lats (length)",
          "pec major (length)",
          "deep core"
        ]
      },
      {
        "exerciseId": "prone-on-elbows-breathing",
        "exerciseName": "Prone on elbows breathing",
        "category": null,
        "directions": "2–3 sets × 5–6 slow breaths",
        "cuesOverride": [
          "Pubic bone heavy",
          "Low ribs expand backward",
          "Neck long, eyes soft"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Breathe into the BACK of the ribs with the pubic bone heavy on the floor — open the posterior chest wall.",
        "joints": [
          "thoracic anti-extension",
          "cervical neutral",
          "rib-pelvis anchor"
        ],
        "compensations": [
          "lumbar extension",
          "neck cranking"
        ],
        "muscles": [
          "diaphragm (posterior excursion)",
          "deep core"
        ]
      },
      {
        "exerciseId": "45-back-extension",
        "exerciseName": "45° back extension",
        "category": null,
        "directions": "• 3–4 sets × 6–10 reps\n• Slow eccentric\n• Rest ~75–90s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Bend at the hips, not the lumbar — train hip extension under gravity at a controlled angle.",
        "joints": [
          "hip extension",
          "lumbar neutral"
        ],
        "compensations": [
          "lumbar extension to substitute for hip"
        ],
        "muscles": [
          "glute max",
          "hamstrings",
          "erector spinae (isometric)"
        ]
      },
      {
        "exerciseId": "quadruped-spine-control",
        "exerciseName": "Quadruped spine control",
        "category": null,
        "directions": "• 3 sets × 6–8 slow reps\n• Move from neutral → slight extension → back\n• Rest ~45s",
        "cuesOverride": [
          "Cue",
          "Extension spreads through thoracic spine",
          "Lumbar stays quiet"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Spread extension through the thoracic spine while the lumbar stays quiet — teach segmental control above and below the curve.",
        "joints": [
          "thoracic extension + flexion",
          "lumbar neutral",
          "scapular control"
        ],
        "compensations": [
          "lumbar extension dominance",
          "scapular winging"
        ],
        "muscles": [
          "thoracic erectors",
          "serratus anterior",
          "transverse abdominis"
        ]
      },
      {
        "exerciseId": "bent-knee-reverse-tabletop",
        "exerciseName": "Bent-knee reverse tabletop",
        "category": null,
        "directions": "• 3 sets × 15–30s\n• Rest ~45–60s",
        "cuesOverride": [
          "Arms press into floor → ribs support arms",
          "Scapulae lightly depressed + posterior tilt",
          "Neck stays passive"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Press arms into floor so the ribs support the arms, not the other way around — entry to scap posterior tilt + hip extension under load.",
        "joints": [
          "shoulder extension",
          "scapular posterior tilt",
          "hip extension"
        ],
        "compensations": [
          "anterior rib flare",
          "shoulder shrugging"
        ],
        "muscles": [
          "lower trap",
          "glute max",
          "triceps",
          "lats"
        ]
      },
      {
        "exerciseId": "single-leg-midfoot-bridge",
        "exerciseName": "Single-leg midfoot bridge",
        "category": null,
        "directions": "• 3–4 sets × 6–8 reps / side\n• 2s hold at top\n• Rest ~60–75s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Same hip extension as the double-leg bridge but on one side — exposes left/right asymmetry in glute timing.",
        "joints": [
          "hip extension (unilateral)",
          "ankle plantarflexion",
          "pelvic stability"
        ],
        "compensations": [
          "lateral pelvis drop",
          "foot supination"
        ],
        "muscles": [
          "glute max",
          "hamstrings",
          "tibialis posterior"
        ]
      },
      {
        "exerciseId": "hip-hinge",
        "exerciseName": "Hip hinge",
        "category": null,
        "directions": "• 3 sets × 6–8 reps\n• 3s hinge / 3s stand",
        "cuesOverride": [
          "Shins vertical",
          "Hips move back, ribs stay stacked",
          "Neck follows spine (no craning)"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Send the hips back with shins vertical, ribs stacked, neck following the spine — the foundation of every deadlift and back-extension pattern.",
        "joints": [
          "hip flexion (hinge)",
          "knee slight flexion",
          "neutral spine"
        ],
        "compensations": [
          "lumbar flexion",
          "knee shooting forward",
          "neck extension"
        ],
        "muscles": [
          "hamstrings (eccentric)",
          "glute max",
          "erector spinae (isometric)"
        ]
      },
      {
        "exerciseId": "seated-hinge-with-dumbbells-light-slow",
        "exerciseName": "Seated hinge with dumbbells (light, slow)",
        "category": null,
        "directions": "• 2–3 sets × 6–8 reps\n• Very slow\n• ⏱ ~3–5 min",
        "cuesOverride": [
          "Let weight pull you into hips, not spine"
        ],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Let the weight pull you into the hips, not the spine — teach the hip hinge from the seated start without standing-leg compensation.",
        "joints": [
          "hip flexion (hinge)",
          "neutral spine"
        ],
        "compensations": [
          "lumbar flexion under load"
        ],
        "muscles": [
          "hamstrings (eccentric)",
          "glute max",
          "erector spinae"
        ]
      },
      {
        "exerciseId": "posterior-capsule-stretch",
        "exerciseName": "Posterior capsule stretch",
        "category": null,
        "directions": "2–3 sets × 30–45s / side",
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Lengthen the back of the hip socket without flexing the spine — pelvis slides into the stretching side, torso stays upright.",
        "joints": [
          "hip extension (end-range)",
          "pelvic translation"
        ],
        "compensations": [
          "lumbar extension",
          "trunk side bend"
        ],
        "muscles": [
          "posterior hip capsule (passive)",
          "psoas (length)",
          "glute max (length)"
        ]
      },
      {
        "exerciseId": "reverse-plank",
        "exerciseName": "Reverse plank",
        "category": null,
        "directions": "3–4 sets × 10–25s\nRest ~90s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Full-body hip extension hold on hands — train shoulder extension and glute max simultaneously.",
        "joints": [
          "hip extension",
          "shoulder extension",
          "scapular posterior tilt"
        ],
        "compensations": [
          "sagging hips",
          "scapular winging"
        ],
        "muscles": [
          "glute max",
          "lower trap",
          "triceps",
          "deep core"
        ]
      },
      {
        "exerciseId": "reverse-tabletop",
        "exerciseName": "Reverse tabletop",
        "category": null,
        "directions": "• 4–6 sets × 15–40s\n• Rest ~60–90s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Same posterior chain hold as reverse plank, but knees bent — reduces hamstring length demand so glutes can dominate.",
        "joints": [
          "hip extension",
          "shoulder extension",
          "knee flexion"
        ],
        "compensations": [
          "lumbar extension",
          "shoulder shrugging"
        ],
        "muscles": [
          "glute max",
          "lower trap",
          "triceps"
        ]
      },
      {
        "exerciseId": "unilateral-db-rdl",
        "exerciseName": "Unilateral DB RDL",
        "category": null,
        "directions": "4–5 sets × 5–8 reps / side",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Hinge on one leg with a single dumbbell — teach the standing hip to extend while the trunk resists rotation.",
        "joints": [
          "hip extension (stance)",
          "thoracic anti-rotation",
          "neutral spine"
        ],
        "compensations": [
          "trunk rotation toward weighted side",
          "lumbar flexion"
        ],
        "muscles": [
          "hamstrings (eccentric)",
          "glute max",
          "obliques (anti-rotation)"
        ]
      },
      {
        "exerciseId": "coiling-core-posterior-capsule",
        "exerciseName": "Coiling core posterior capsule",
        "category": null,
        "directions": "• 2–3 sets × 5–6 slow breaths\n• Emphasis on back-body expansion",
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Posterior capsule stretch + active core coil — ribs come over the pelvis to deepen the hip extension while staying organized.",
        "joints": [
          "hip extension",
          "thoracic flexion (light coil)"
        ],
        "compensations": [
          "lumbar extension",
          "rib flare"
        ],
        "muscles": [
          "transverse abdominis",
          "obliques",
          "posterior hip capsule (passive)"
        ]
      }
    ]
  },
  {
    "id": "notion-day-c-lateral-frontal-plane",
    "name": "DAY C — LATERAL / FRONTAL PLANE",
    "emoji": "🟡",
    "intent": null,
    "primaryPlane": null,
    "jointsMovements": [],
    "kind": null,
    "source": "notion-export",
    "notionPath": "🟡 DAY C — LATERAL / FRONTAL PLANE",
    "blocks": [
      {
        "exerciseId": "side-lying-breathing",
        "exerciseName": "Side-lying breathing",
        "category": null,
        "directions": "2–3 sets × 5–6 slow breaths / side",
        "cuesOverride": [],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Breathe into the up-side of the ribs — restore lateral rib expansion that gets lost in chronic asymmetry.",
        "joints": [
          "thoracic lateral expansion",
          "rib-pelvis stack"
        ],
        "compensations": [
          "bilateral chest breathing"
        ],
        "muscles": [
          "diaphragm (asymmetric)",
          "intercostals (up-side)"
        ]
      },
      {
        "exerciseId": "side-lying-scissor-slides",
        "exerciseName": "Side-lying scissor slides",
        "category": null,
        "directions": "2 sets × 6–8 slow reps / side",
        "cuesOverride": [
          "Pelvis stacked",
          "Movement stays long and quiet",
          "No spinal rolling"
        ],
        "phase": "warmUp",
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Sweep the leg through hip flexion + extension with pelvis stacked — train hip dissociation in the frontal plane.",
        "joints": [
          "hip flexion + extension",
          "pelvic stability (frontal)"
        ],
        "compensations": [
          "spinal rolling",
          "pelvic shift"
        ],
        "muscles": [
          "psoas",
          "hamstrings",
          "lateral hip stabilizers"
        ]
      },
      {
        "exerciseId": "side-bend-seated",
        "exerciseName": "Side bend (seated)",
        "category": null,
        "directions": null,
        "cuesOverride": [],
        "phase": "warmUp",
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Active lateral flexion to one side — teach the trunk to bend through the ribs without collapsing the bottom waist.",
        "joints": [
          "thoracic lateral flexion",
          "lumbar neutral"
        ],
        "compensations": [
          "bottom-waist collapse",
          "rotation"
        ],
        "muscles": [
          "obliques (concentric/eccentric)",
          "QL"
        ]
      },
      {
        "exerciseId": "single-leg-balance",
        "exerciseName": "Single-leg balance",
        "category": null,
        "directions": "• 2 sets × 30–45s / side",
        "cuesOverride": [
          "(barefoot if possible)"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Stand on one foot barefoot — let the foot tripod and the hip stabilizers find the line of gravity.",
        "joints": [
          "ankle stability",
          "subtalar pronation/supination control",
          "hip abduction"
        ],
        "compensations": [
          "foot supination",
          "pelvic drop",
          "knee valgus"
        ],
        "muscles": [
          "intrinsic foot",
          "tib post",
          "peroneus longus",
          "glute med"
        ]
      },
      {
        "exerciseId": "side-plank-short-lever",
        "exerciseName": "Side plank short lever",
        "category": null,
        "directions": "• 3 sets × 20–30s / side\n• Rest ~45–60s",
        "cuesOverride": [
          "Bottom shoulder supports ribs",
          "Pelvis stacked, not rotated",
          "Neck long"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Bottom shoulder supports the ribs, pelvis stacked — frontal plane anti-collapse with reduced length demand.",
        "joints": [
          "shoulder stability",
          "lateral trunk anti-flexion"
        ],
        "compensations": [
          "pelvic rotation",
          "rib flare"
        ],
        "muscles": [
          "obliques",
          "QL",
          "glute med",
          "serratus anterior"
        ]
      },
      {
        "exerciseId": "step-down",
        "exerciseName": "Step-down",
        "category": null,
        "directions": "• 3–4 sets × 5–8 reps / side\n• Rest ~75–90s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Lower one leg to the floor with control — teach the standing leg's hip + knee + foot to absorb the drop.",
        "joints": [
          "hip flexion (stance)",
          "knee flexion",
          "ankle dorsiflexion"
        ],
        "compensations": [
          "knee valgus",
          "pelvic drop",
          "trunk lean"
        ],
        "muscles": [
          "quads (eccentric)",
          "glute med",
          "tib post"
        ]
      },
      {
        "exerciseId": "split-squat",
        "exerciseName": "Split squat",
        "category": "HIP ABDUCTION / ADDUCTION",
        "directions": "• 4–5 sets × 6–8 reps / side\n• Rest ~75–90s",
        "cuesOverride": [
          "Front foot tripod",
          "Pelvis drops straight down",
          "Knee tracks second toe"
        ],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Front foot tripod, pelvis drops straight down, knee tracks second toe — learn the split position before loading it.",
        "joints": [
          "hip flexion (front)",
          "hip extension (back)",
          "knee flexion (front)"
        ],
        "compensations": [
          "knee valgus",
          "pelvic shift",
          "lumbar extension"
        ],
        "muscles": [
          "quads",
          "glute max (back)",
          "adductor magnus",
          "glute med (front)"
        ]
      },
      {
        "exerciseId": "outer-hip-circuit",
        "exerciseName": "Outer hip circuit",
        "category": null,
        "directions": "• 1–2 rounds\n• Low intensity, continuous flow",
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": true,
        "intent": "Multi-position hit on the lateral hip stabilizers — wake up glute med so the pelvis doesn't drop in single-leg work.",
        "joints": [
          "hip abduction",
          "hip external rotation",
          "pelvic frontal-plane stability"
        ],
        "compensations": [
          "TFL substitution for glute med",
          "lumbar side-bend"
        ],
        "muscles": [
          "glute med",
          "glute min",
          "deep hip rotators"
        ]
      },
      {
        "exerciseId": "seated-er",
        "exerciseName": "Seated ER",
        "category": null,
        "directions": "• 3–4 sets × 8–10 reps / side\n• Slow out / slower back\n• Rest ~45–60s",
        "cuesOverride": [
          "Ribs stacked",
          "Shoulder rotates in the socket",
          "No elbow drift"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Rotate the shoulder externally with ribs stacked — train the rotator cuff in a position the trunk can't help from.",
        "joints": [
          "shoulder external rotation",
          "scapular stability"
        ],
        "compensations": [
          "elbow drift",
          "trunk lean"
        ],
        "muscles": [
          "infraspinatus",
          "teres minor",
          "lower trap"
        ]
      },
      {
        "exerciseId": "pallof-hold",
        "exerciseName": "Pallof hold",
        "category": null,
        "directions": "• 3–4 sets × 20–30s / side\n• Rest ~45–60s",
        "cuesOverride": [
          "Pelvis faces forward",
          "Ribs rotate just enough to resist",
          "No gripping in hips"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": "Resist rotational pull with ribs facing forward — anti-rotation endurance through the trunk and hips.",
        "joints": [
          "thoracic anti-rotation",
          "hip stability"
        ],
        "compensations": [
          "hip gripping",
          "rib rotation"
        ],
        "muscles": [
          "obliques (anti-rotation)",
          "transverse abdominis",
          "glute med"
        ]
      },
      {
        "exerciseId": "supine-shin-lift",
        "exerciseName": "Supine shin lift",
        "category": null,
        "directions": "2–3 sets × 6–8 reps / side",
        "cuesOverride": [
          "2s lift / 3s lower"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": null,
        "currentlyIncluded": false,
        "intent": "Lift the foot toward the shin slowly — wake up the tibialis anterior, the muscle that controls foot landing in gait.",
        "joints": [
          "ankle dorsiflexion"
        ],
        "compensations": [
          "toe extension to substitute for tib ant"
        ],
        "muscles": [
          "tibialis anterior"
        ]
      },
      {
        "exerciseId": "side-lying-leg-lift",
        "exerciseName": "Side-lying leg lift",
        "category": null,
        "directions": "• 2–3 sets × 8–10 reps / side\n• Slow up / slower down\n• Rest ~30–45s",
        "cuesOverride": [
          "Heel slightly back",
          "Waist stays long",
          "No hip hike"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": false,
        "intent": "Lift the top leg with heel slightly back, no hip hike — isolate glute med without TFL substitution.",
        "joints": [
          "hip abduction",
          "slight hip extension"
        ],
        "compensations": [
          "hip hike",
          "TFL substitution (leg drifts forward)"
        ],
        "muscles": [
          "glute med",
          "glute min"
        ]
      },
      {
        "exerciseId": "half-kneeling-adductor-pullback",
        "exerciseName": "Half-kneeling adductor pullback",
        "category": "HIP ABDUCTION / ADDUCTION",
        "directions": "• 3–4 sets × 5–6 slow reps / side\n• Rest ~45–60s",
        "cuesOverride": [
          "Pelvis gently shifts back",
          "Inner thigh lengthens under control",
          "Ribcage stays stacked over pelvis"
        ],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": false,
        "intent": "Pelvis shifts back, inner thigh lengthens under control, ribcage stays stacked — open the groin without losing the trunk.",
        "joints": [
          "hip abduction (groin opening)",
          "lumbar neutral"
        ],
        "compensations": [
          "lumbar extension",
          "rib flare"
        ],
        "muscles": [
          "adductor magnus (length)",
          "deep core",
          "glute med"
        ]
      },
      {
        "exerciseId": "long-lever-side-plank",
        "exerciseName": "Long-lever side plank",
        "category": "LATERAL CORE",
        "directions": "• 4–5 sets × 15–30s / side\n• Rest ~60–90s",
        "cuesOverride": [],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Full-length side plank — the high-end of frontal-plane anti-collapse.",
        "joints": [
          "lateral trunk anti-flexion",
          "shoulder stability",
          "hip abduction"
        ],
        "compensations": [
          "sagging pelvis",
          "rotation"
        ],
        "muscles": [
          "obliques",
          "QL",
          "glute med",
          "serratus anterior"
        ]
      },
      {
        "exerciseId": "full-range-split-squat",
        "exerciseName": "Full-range split squat",
        "category": null,
        "directions": "• 3–4 sets × 5–6 reps / side\n• Slow descent, controlled ascent\n• Rest ~90s",
        "cuesOverride": [
          "Stop if",
          "Pelvis shifts sideways",
          "Foot collapses",
          "Low back tightens"
        ],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Deeper split squat at full range — STOP if pelvis shifts, foot collapses, or low back tightens. Quality over depth.",
        "joints": [
          "hip flexion (deep)",
          "knee flexion (deep)",
          "ankle dorsiflexion"
        ],
        "compensations": [
          "pelvic shift",
          "foot collapse",
          "lumbar tightening"
        ],
        "muscles": [
          "quads (deep)",
          "glute max",
          "adductors",
          "soleus"
        ]
      },
      {
        "exerciseId": "seated-tibialis-raise",
        "exerciseName": "Seated tibialis raise",
        "category": null,
        "directions": "• 3–4 sets × 10–15 reps\n• 2s up / 3s down\n• Rest ~45s",
        "cuesOverride": [],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": false,
        "intent": "Lift the toes toward the shin with a heavy heel — wake up the tibialis anterior in a strict seated position.",
        "joints": [
          "ankle dorsiflexion"
        ],
        "compensations": [
          "foot rolling outward"
        ],
        "muscles": [
          "tibialis anterior"
        ]
      },
      {
        "exerciseId": "reverse-step-up",
        "exerciseName": "Reverse step-up",
        "category": null,
        "directions": "• 3–4 sets × 6–8 reps / side\n• Rest ~60s",
        "cuesOverride": [
          "Heel stays down",
          "Knee tracks forward",
          "Pelvis stays level"
        ],
        "phase": null,
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Step DOWN slowly with heel staying down, knee tracking forward — train the standing leg's controlled lengthening.",
        "joints": [
          "hip flexion (stance)",
          "knee flexion (stance)",
          "ankle dorsiflexion"
        ],
        "compensations": [
          "knee valgus",
          "pelvic drop",
          "heel lift"
        ],
        "muscles": [
          "quads (eccentric)",
          "glute med",
          "soleus"
        ]
      },
      {
        "exerciseId": "foot-flattener-back-foot-off-floor",
        "exerciseName": "Foot flattener (back foot off floor)",
        "category": null,
        "directions": "2–3 sets × 5–6 slow breaths / side",
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Heavy heel, relaxed toes — load the heel and arch so the foot spreads flat under the body's weight.",
        "joints": [
          "ankle dorsiflexion",
          "subtalar pronation",
          "hip flexion (stance)"
        ],
        "compensations": [
          "ankle inversion",
          "toe gripping"
        ],
        "muscles": [
          "tib post",
          "peroneus longus",
          "intrinsic foot"
        ]
      },
      {
        "exerciseId": "pigeon-stretch",
        "exerciseName": "Pigeon stretch",
        "category": null,
        "directions": "• 2–3 sets × 30–45s / side\n• Only go as deep as you can breathe",
        "cuesOverride": [],
        "phase": "coolDown",
        "level": null,
        "order": null,
        "currentlyIncluded": false,
        "intent": "Lengthen the deep external rotators of the hip — open the back of the hip socket in flexion.",
        "joints": [
          "hip external rotation (length)",
          "hip flexion"
        ],
        "compensations": [
          "pelvic rotation off-square"
        ],
        "muscles": [
          "piriformis (length)",
          "deep hip rotators",
          "glute max (length)"
        ]
      }
    ]
  },
  {
    "id": "notion-day-d-rotation-cross-body",
    "name": "DAY D — ROTATION + CROSS-BODY",
    "emoji": "🟠",
    "intent": null,
    "primaryPlane": null,
    "jointsMovements": [],
    "kind": null,
    "source": "notion-export",
    "notionPath": "🟠 DAY D — ROTATION + CROSS-BODY",
    "blocks": [
      {
        "exerciseId": "supine-cross-body-reach",
        "exerciseName": "Supine cross-body reach",
        "order": 1,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "pallof-hold",
        "exerciseName": "Pallof hold",
        "order": 2,
        "currentlyIncluded": true,
        "intent": "Resist rotational pull with ribs facing forward — anti-rotation endurance through the trunk and hips.",
        "joints": [
          "thoracic anti-rotation",
          "hip stability"
        ],
        "compensations": [
          "hip gripping",
          "rib rotation"
        ],
        "muscles": [
          "obliques (anti-rotation)",
          "transverse abdominis",
          "glute med"
        ]
      },
      {
        "exerciseId": "kickstand-chop",
        "exerciseName": "Kickstand chop",
        "order": 3,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "standing-anti-rotation",
        "exerciseName": "Standing anti-rotation",
        "order": 4,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "split-squat-rotation",
        "exerciseName": "Split squat rotation",
        "order": 5,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "split-stance-cable-rotation",
        "exerciseName": "Split-stance cable rotation",
        "order": 6,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "side-lying-er-ribs-stacked",
        "exerciseName": "Side-lying ER (ribs stacked)",
        "order": 7,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "seated-er",
        "exerciseName": "Seated ER",
        "order": 8,
        "currentlyIncluded": true,
        "intent": "Rotate the shoulder externally with ribs stacked — train the rotator cuff in a position the trunk can't help from.",
        "joints": [
          "shoulder external rotation",
          "scapular stability"
        ],
        "compensations": [
          "elbow drift",
          "trunk lean"
        ],
        "muscles": [
          "infraspinatus",
          "teres minor",
          "lower trap"
        ]
      },
      {
        "exerciseId": "standing-single-arm-er",
        "exerciseName": "Standing single-arm ER",
        "order": 9,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "split-stance-er",
        "exerciseName": "Split-stance ER",
        "order": 10,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      },
      {
        "exerciseId": "side-bend-seated",
        "exerciseName": "Side bend (seated)",
        "order": 11,
        "currentlyIncluded": true,
        "intent": "Active lateral flexion to one side — teach the trunk to bend through the ribs without collapsing the bottom waist.",
        "joints": [
          "thoracic lateral flexion",
          "lumbar neutral"
        ],
        "compensations": [
          "bottom-waist collapse",
          "rotation"
        ],
        "muscles": [
          "obliques (concentric/eccentric)",
          "QL"
        ]
      },
      {
        "exerciseId": "stand-mid-back-isometric-hold",
        "exerciseName": "Stand mid-back isometric hold",
        "order": 12,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      }
    ]
  },
  {
    "id": "notion-day-e-locomotion-integration",
    "name": "DAY E — LOCOMOTION / INTEGRATION",
    "emoji": "🔴",
    "intent": null,
    "primaryPlane": null,
    "jointsMovements": [
      "Elastic Prep",
      "Gait",
      "Whole-system coordination"
    ],
    "kind": null,
    "source": "notion-export",
    "notionPath": "🔴 DAY E — LOCOMOTION / INTEGRATION",
    "blocks": [
      {
        "exerciseId": "rope-flow",
        "exerciseName": "Rope flow",
        "category": "Locomotion",
        "directions": "3-5 min continuos\nLow amplitude\nEasy breathing",
        "cuesOverride": [
          "Arms float from ribs",
          "Pelvis responds, doesn’t lead",
          "No shoulder tension"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": 1,
        "currentlyIncluded": false,
        "intent": "Continuous low-amplitude rope flow — let the arms float from the ribs and the pelvis respond, not lead. Easy breathing throughout.",
        "joints": [
          "thoracic rotation",
          "shoulder reciprocal motion",
          "pelvic counter-rotation"
        ],
        "compensations": [
          "shoulder tension",
          "pelvis leading the motion"
        ],
        "muscles": [
          "serratus anterior",
          "obliques (reciprocal)",
          "deep core"
        ]
      },
      {
        "exerciseId": "marching-drills",
        "exerciseName": "Marching drills",
        "category": "Locomotion",
        "directions": "• 2–3 sets × 30–45s\n• Slow → moderate tempo",
        "cuesOverride": [
          "Heel rolls to midfoot",
          "Pelvis alternates smoothly",
          "Arm swing stays reciprocal"
        ],
        "phase": "warmUp",
        "level": "foundation",
        "order": 2,
        "currentlyIncluded": false,
        "intent": "Heel rolls to midfoot, pelvis alternates smoothly, arm swing stays reciprocal — train the contralateral pattern at walking speed.",
        "joints": [
          "hip flexion + extension (alternating)",
          "ankle plantarflexion → dorsiflexion roll",
          "thoracic counter-rotation"
        ],
        "compensations": [
          "heel slap (no roll)",
          "pelvic stiffness",
          "ipsilateral arm swing"
        ],
        "muscles": [
          "psoas",
          "tib ant",
          "glute med",
          "obliques"
        ]
      }
    ]
  },
  {
    "id": "notion-snacks-during-the-day",
    "name": "Snacks during the day",
    "emoji": null,
    "intent": null,
    "primaryPlane": null,
    "jointsMovements": [],
    "kind": null,
    "source": "notion-export",
    "notionPath": "Snacks during the day",
    "blocks": [
      {
        "exerciseId": "supine-band-head-stabilization-with-leg-lifts-and-bridge",
        "exerciseName": "Supine Band Head Stabilization with Leg Lifts and Bridge",
        "category": "Cranio-cervical stability",
        "directions": null,
        "cuesOverride": [],
        "phase": null,
        "level": "foundation",
        "order": null,
        "currentlyIncluded": true,
        "intent": null,
        "joints": [],
        "compensations": [],
        "muscles": []
      }
    ]
  }
];
