"""
Per-exercise educational content for Marco's Notion workouts. Keyed by the
slug the import script generates (see slug() in import-notion-workouts.py:
lowercased, non-alphanum -> '-', max 60 chars).

Drafted from Notion cues + exercise name + the workout's overall theme
(anterior/posterior/lateral/rotation chain). PRI/DNS framing.

Edit freely — these are starting points, not gospel. Re-run the import
script after editing this file to refresh src/lib/seeds/notionWorkouts.ts.
"""

# Each entry: {intent, joints, compensations, muscles}
EDUCATIONAL_CONTENT = {
    # ─── DAY A — ANTERIOR CHAIN + FLEXION (sagittal) ────────────────────
    "supine-dns-breathing": {
        "intent": "Reset the rib-pelvis stack and let the diaphragm do the work without the abs gripping. The baseline that every other exercise builds on.",
        "joints": ["rib-pelvis stack", "diaphragm excursion"],
        "compensations": ["anterior rib flare", "ab bracing instead of breathing"],
        "muscles": ["diaphragm", "transverse abdominis (passive)", "intercostals"],
    },
    "supine-arm-reach-dns": {
        "intent": "Reach overhead while the ribs stay down — teach scapular upward rotation without rib flare or lumbar extension.",
        "joints": ["shoulder flexion", "scapular upward rotation", "thoracic anti-extension"],
        "compensations": ["anterior rib flare", "lumbar extension during reach"],
        "muscles": ["serratus anterior", "lower trap", "deep core"],
    },
    "supine-hip-flexion-control": {
        "intent": "Lift the leg from the hip flexors with the pelvis quiet — train hip dissociation from the lumbar spine.",
        "joints": ["hip flexion", "lumbo-pelvic stability"],
        "compensations": ["anterior pelvic tilt during hip flexion", "lumbar extension"],
        "muscles": ["psoas", "iliacus", "transverse abdominis"],
    },
    "hip-flexor-kick-out": {
        "intent": "Train the high-end of hip flexor strength (above 90°) slowly and under control — build endurance where the leg is most demanding to hold.",
        "joints": ["hip flexion (>90°)", "knee extension"],
        "compensations": ["lumbar extension to substitute for psoas"],
        "muscles": ["psoas", "iliacus", "rectus femoris (terminal)"],
    },
    "quadruped-arm-lift": {
        "intent": "Reach an arm forward without the ribs shifting — anti-rotation under load through the trunk.",
        "joints": ["shoulder flexion", "thoracic anti-rotation", "rib-pelvis stack"],
        "compensations": ["rib shift toward unloaded side", "lumbar rotation"],
        "muscles": ["obliques (anti-rotation)", "serratus anterior", "deep core"],
    },
    "dead-bug": {
        "intent": "Move opposite arm and leg while the lumbar spine stays glued to the floor — disconnect limb motion from spine motion.",
        "joints": ["hip flexion + extension", "shoulder flexion + extension", "lumbar anti-extension"],
        "compensations": ["lumbar extension off the floor as limbs lengthen"],
        "muscles": ["transverse abdominis", "obliques", "psoas"],
    },
    "seated-floor-straight-leg-raises": {
        "intent": "Posterior pelvic tilt FIRST, then lift — teach the deep core to tilt the pelvis before the hip flexors fire.",
        "joints": ["hip flexion", "posterior pelvic tilt", "knee extension"],
        "compensations": ["anterior pelvic tilt", "lumbar extension"],
        "muscles": ["transverse abdominis", "psoas", "rectus femoris", "rectus abdominis"],
    },
    "bent-knee-l-sit": {
        "intent": "Hold a tall spine with knees lifted — train hip flexor endurance with active scapular depression.",
        "joints": ["hip flexion", "scapular depression", "thoracic upright"],
        "compensations": ["pelvic shift to one side", "shoulder shrug to lift"],
        "muscles": ["psoas", "lower trap", "lats", "deep core"],
    },
    "reverse-squat": {
        "intent": "Slow eccentric lowering with a tall spine — load the hip flexors and quads through full range with no spine compensation.",
        "joints": ["hip flexion", "knee flexion", "ankle dorsiflexion"],
        "compensations": ["lumbar extension", "knee valgus"],
        "muscles": ["quads (eccentric)", "psoas", "glute max", "deep core"],
    },
    "deep-squat-breath": {
        "intent": "Sit in the bottom of the squat and breathe into the back of the body — restore hip + ankle range while the diaphragm works.",
        "joints": ["hip flexion (deep)", "ankle dorsiflexion", "thoracic upright"],
        "compensations": ["heel lift", "lumbar flexion collapse"],
        "muscles": ["diaphragm", "adductors (length)", "soleus (length)"],
    },
    "standing-overhead-press-isometric-hold": {
        "intent": "Hold a light load overhead with ribs stacked and scaps upwardly rotated — train the standing posture under shoulder load.",
        "joints": ["shoulder flexion (terminal)", "scapular upward rotation", "rib-pelvis stack"],
        "compensations": ["anterior rib flare under load", "lumbar extension"],
        "muscles": ["serratus anterior", "lower trap", "deep core", "deltoid"],
    },
    "loaded-butterfly": {
        "intent": "Lengthen the inner thigh and hip rotators under light load — prep the hips for deep flexion.",
        "joints": ["hip external rotation", "hip abduction", "lumbar anti-extension"],
        "compensations": ["lumbar extension to deepen the stretch"],
        "muscles": ["adductors (length)", "deep hip rotators (length)", "deep core"],
    },
    "hanging-leg-raise": {
        "intent": "Raise the legs from the deep core, not the hip flexors — posterior pelvic tilt first, then the legs follow.",
        "joints": ["hip flexion", "posterior pelvic tilt", "lumbar flexion"],
        "compensations": ["swinging momentum", "anterior pelvic tilt"],
        "muscles": ["rectus abdominis (lower fibers)", "transverse abdominis", "psoas"],
    },
    "l-sit": {
        "intent": "Static hold with legs out straight and scaps depressed — full anterior chain + scapular endurance.",
        "joints": ["hip flexion", "knee extension", "scapular depression"],
        "compensations": ["pelvic asymmetry", "shoulder elevation"],
        "muscles": ["psoas", "rectus femoris", "lower trap", "lats", "transverse abdominis"],
    },
    "push-up-plus": {
        "intent": "After the push-up's top, push further to upwardly rotate the scaps — train serratus anterior, the missing piece of most push-ups.",
        "joints": ["shoulder flexion", "scapular protraction + upward rotation"],
        "compensations": ["winging scapula", "rib flare at the top"],
        "muscles": ["serratus anterior", "pec minor (length)", "deep core"],
    },
    "active-hang": {
        "intent": "Hang with scaps slightly depressed and upwardly rotated, no elbow bend — build a stable shoulder under traction.",
        "joints": ["shoulder flexion (overhead)", "scapular depression + upward rotation"],
        "compensations": ["passive shoulder shrug", "elbow bend"],
        "muscles": ["lower trap", "lats", "rotator cuff", "grip"],
    },

    # ─── DAY B — POSTERIOR CHAIN + EXTENSION ─────────────────────────────
    "foam-roller-bridge-double-leg": {
        "intent": "Hip extension that comes from glutes + hamstrings while the lumbar stays quiet — knees lightly hugging the roller adds adductor engagement.",
        "joints": ["hip extension", "knee adduction (light)", "lumbar anti-extension"],
        "compensations": ["lumbar hyperextension", "knee bowing out"],
        "muscles": ["glute max (lower fibers)", "hamstrings", "adductor magnus"],
    },
    "glute-bridge": {
        "intent": "Drive the hips up through the midfoot, ribs stay down — the cleanest entry to glute-driven hip extension.",
        "joints": ["hip extension", "ankle dorsiflexion (heel pressure)"],
        "compensations": ["lumbar extension", "hamstring cramp from over-shortening"],
        "muscles": ["glute max", "hamstrings", "transverse abdominis"],
    },
    "supine-arm-extension": {
        "intent": "Take the arm overhead in extension without the ribs popping or the neck pulling — teach end-range shoulder extension with anterior chain control.",
        "joints": ["shoulder extension (overhead)", "thoracic anti-extension"],
        "compensations": ["rib flare", "neck protraction"],
        "muscles": ["lats (length)", "pec major (length)", "deep core"],
    },
    "prone-on-elbows-breathing": {
        "intent": "Breathe into the BACK of the ribs with the pubic bone heavy on the floor — open the posterior chest wall.",
        "joints": ["thoracic anti-extension", "cervical neutral", "rib-pelvis anchor"],
        "compensations": ["lumbar extension", "neck cranking"],
        "muscles": ["diaphragm (posterior excursion)", "deep core"],
    },
    "45-back-extension": {
        "intent": "Bend at the hips, not the lumbar — train hip extension under gravity at a controlled angle.",
        "joints": ["hip extension", "lumbar neutral"],
        "compensations": ["lumbar extension to substitute for hip"],
        "muscles": ["glute max", "hamstrings", "erector spinae (isometric)"],
    },
    "quadruped-spine-control": {
        "intent": "Spread extension through the thoracic spine while the lumbar stays quiet — teach segmental control above and below the curve.",
        "joints": ["thoracic extension + flexion", "lumbar neutral", "scapular control"],
        "compensations": ["lumbar extension dominance", "scapular winging"],
        "muscles": ["thoracic erectors", "serratus anterior", "transverse abdominis"],
    },
    "bent-knee-reverse-tabletop": {
        "intent": "Press arms into floor so the ribs support the arms, not the other way around — entry to scap posterior tilt + hip extension under load.",
        "joints": ["shoulder extension", "scapular posterior tilt", "hip extension"],
        "compensations": ["anterior rib flare", "shoulder shrugging"],
        "muscles": ["lower trap", "glute max", "triceps", "lats"],
    },
    "single-leg-midfoot-bridge": {
        "intent": "Same hip extension as the double-leg bridge but on one side — exposes left/right asymmetry in glute timing.",
        "joints": ["hip extension (unilateral)", "ankle plantarflexion", "pelvic stability"],
        "compensations": ["lateral pelvis drop", "foot supination"],
        "muscles": ["glute max", "hamstrings", "tibialis posterior"],
    },
    "hip-hinge": {
        "intent": "Send the hips back with shins vertical, ribs stacked, neck following the spine — the foundation of every deadlift and back-extension pattern.",
        "joints": ["hip flexion (hinge)", "knee slight flexion", "neutral spine"],
        "compensations": ["lumbar flexion", "knee shooting forward", "neck extension"],
        "muscles": ["hamstrings (eccentric)", "glute max", "erector spinae (isometric)"],
    },
    "seated-hinge-with-dumbbells-light-slow": {
        "intent": "Let the weight pull you into the hips, not the spine — teach the hip hinge from the seated start without standing-leg compensation.",
        "joints": ["hip flexion (hinge)", "neutral spine"],
        "compensations": ["lumbar flexion under load"],
        "muscles": ["hamstrings (eccentric)", "glute max", "erector spinae"],
    },
    "posterior-capsule-stretch": {
        "intent": "Lengthen the back of the hip socket without flexing the spine — pelvis slides into the stretching side, torso stays upright.",
        "joints": ["hip extension (end-range)", "pelvic translation"],
        "compensations": ["lumbar extension", "trunk side bend"],
        "muscles": ["posterior hip capsule (passive)", "psoas (length)", "glute max (length)"],
    },
    "reverse-plank": {
        "intent": "Full-body hip extension hold on hands — train shoulder extension and glute max simultaneously.",
        "joints": ["hip extension", "shoulder extension", "scapular posterior tilt"],
        "compensations": ["sagging hips", "scapular winging"],
        "muscles": ["glute max", "lower trap", "triceps", "deep core"],
    },
    "reverse-tabletop": {
        "intent": "Same posterior chain hold as reverse plank, but knees bent — reduces hamstring length demand so glutes can dominate.",
        "joints": ["hip extension", "shoulder extension", "knee flexion"],
        "compensations": ["lumbar extension", "shoulder shrugging"],
        "muscles": ["glute max", "lower trap", "triceps"],
    },
    "unilateral-db-rdl": {
        "intent": "Hinge on one leg with a single dumbbell — teach the standing hip to extend while the trunk resists rotation.",
        "joints": ["hip extension (stance)", "thoracic anti-rotation", "neutral spine"],
        "compensations": ["trunk rotation toward weighted side", "lumbar flexion"],
        "muscles": ["hamstrings (eccentric)", "glute max", "obliques (anti-rotation)"],
    },
    "coiling-core-posterior-capsule": {
        "intent": "Posterior capsule stretch + active core coil — ribs come over the pelvis to deepen the hip extension while staying organized.",
        "joints": ["hip extension", "thoracic flexion (light coil)"],
        "compensations": ["lumbar extension", "rib flare"],
        "muscles": ["transverse abdominis", "obliques", "posterior hip capsule (passive)"],
    },

    # ─── DAY C — LATERAL / FRONTAL PLANE ─────────────────────────────────
    "side-lying-breathing": {
        "intent": "Breathe into the up-side of the ribs — restore lateral rib expansion that gets lost in chronic asymmetry.",
        "joints": ["thoracic lateral expansion", "rib-pelvis stack"],
        "compensations": ["bilateral chest breathing"],
        "muscles": ["diaphragm (asymmetric)", "intercostals (up-side)"],
    },
    "side-lying-scissor-slides": {
        "intent": "Sweep the leg through hip flexion + extension with pelvis stacked — train hip dissociation in the frontal plane.",
        "joints": ["hip flexion + extension", "pelvic stability (frontal)"],
        "compensations": ["spinal rolling", "pelvic shift"],
        "muscles": ["psoas", "hamstrings", "lateral hip stabilizers"],
    },
    "side-bend-seated": {
        "intent": "Active lateral flexion to one side — teach the trunk to bend through the ribs without collapsing the bottom waist.",
        "joints": ["thoracic lateral flexion", "lumbar neutral"],
        "compensations": ["bottom-waist collapse", "rotation"],
        "muscles": ["obliques (concentric/eccentric)", "QL"],
    },
    "single-leg-balance": {
        "intent": "Stand on one foot barefoot — let the foot tripod and the hip stabilizers find the line of gravity.",
        "joints": ["ankle stability", "subtalar pronation/supination control", "hip abduction"],
        "compensations": ["foot supination", "pelvic drop", "knee valgus"],
        "muscles": ["intrinsic foot", "tib post", "peroneus longus", "glute med"],
    },
    "side-plank-short-lever": {
        "intent": "Bottom shoulder supports the ribs, pelvis stacked — frontal plane anti-collapse with reduced length demand.",
        "joints": ["shoulder stability", "lateral trunk anti-flexion"],
        "compensations": ["pelvic rotation", "rib flare"],
        "muscles": ["obliques", "QL", "glute med", "serratus anterior"],
    },
    "step-down": {
        "intent": "Lower one leg to the floor with control — teach the standing leg's hip + knee + foot to absorb the drop.",
        "joints": ["hip flexion (stance)", "knee flexion", "ankle dorsiflexion"],
        "compensations": ["knee valgus", "pelvic drop", "trunk lean"],
        "muscles": ["quads (eccentric)", "glute med", "tib post"],
    },
    "split-squat": {
        "intent": "Front foot tripod, pelvis drops straight down, knee tracks second toe — learn the split position before loading it.",
        "joints": ["hip flexion (front)", "hip extension (back)", "knee flexion (front)"],
        "compensations": ["knee valgus", "pelvic shift", "lumbar extension"],
        "muscles": ["quads", "glute max (back)", "adductor magnus", "glute med (front)"],
    },
    "outer-hip-circuit": {
        "intent": "Multi-position hit on the lateral hip stabilizers — wake up glute med so the pelvis doesn't drop in single-leg work.",
        "joints": ["hip abduction", "hip external rotation", "pelvic frontal-plane stability"],
        "compensations": ["TFL substitution for glute med", "lumbar side-bend"],
        "muscles": ["glute med", "glute min", "deep hip rotators"],
    },
    "seated-er": {
        "intent": "Rotate the shoulder externally with ribs stacked — train the rotator cuff in a position the trunk can't help from.",
        "joints": ["shoulder external rotation", "scapular stability"],
        "compensations": ["elbow drift", "trunk lean"],
        "muscles": ["infraspinatus", "teres minor", "lower trap"],
    },
    "pallof-hold": {
        "intent": "Resist rotational pull with ribs facing forward — anti-rotation endurance through the trunk and hips.",
        "joints": ["thoracic anti-rotation", "hip stability"],
        "compensations": ["hip gripping", "rib rotation"],
        "muscles": ["obliques (anti-rotation)", "transverse abdominis", "glute med"],
    },
    "supine-shin-lift": {
        "intent": "Lift the foot toward the shin slowly — wake up the tibialis anterior, the muscle that controls foot landing in gait.",
        "joints": ["ankle dorsiflexion"],
        "compensations": ["toe extension to substitute for tib ant"],
        "muscles": ["tibialis anterior"],
    },
    "side-lying-leg-lift": {
        "intent": "Lift the top leg with heel slightly back, no hip hike — isolate glute med without TFL substitution.",
        "joints": ["hip abduction", "slight hip extension"],
        "compensations": ["hip hike", "TFL substitution (leg drifts forward)"],
        "muscles": ["glute med", "glute min"],
    },
    "half-kneeling-adductor-pullback": {
        "intent": "Pelvis shifts back, inner thigh lengthens under control, ribcage stays stacked — open the groin without losing the trunk.",
        "joints": ["hip abduction (groin opening)", "lumbar neutral"],
        "compensations": ["lumbar extension", "rib flare"],
        "muscles": ["adductor magnus (length)", "deep core", "glute med"],
    },
    "long-lever-side-plank": {
        "intent": "Full-length side plank — the high-end of frontal-plane anti-collapse.",
        "joints": ["lateral trunk anti-flexion", "shoulder stability", "hip abduction"],
        "compensations": ["sagging pelvis", "rotation"],
        "muscles": ["obliques", "QL", "glute med", "serratus anterior"],
    },
    "full-range-split-squat": {
        "intent": "Deeper split squat at full range — STOP if pelvis shifts, foot collapses, or low back tightens. Quality over depth.",
        "joints": ["hip flexion (deep)", "knee flexion (deep)", "ankle dorsiflexion"],
        "compensations": ["pelvic shift", "foot collapse", "lumbar tightening"],
        "muscles": ["quads (deep)", "glute max", "adductors", "soleus"],
    },
    "seated-tibialis-raise": {
        "intent": "Lift the toes toward the shin with a heavy heel — wake up the tibialis anterior in a strict seated position.",
        "joints": ["ankle dorsiflexion"],
        "compensations": ["foot rolling outward"],
        "muscles": ["tibialis anterior"],
    },
    "reverse-step-up": {
        "intent": "Step DOWN slowly with heel staying down, knee tracking forward — train the standing leg's controlled lengthening.",
        "joints": ["hip flexion (stance)", "knee flexion (stance)", "ankle dorsiflexion"],
        "compensations": ["knee valgus", "pelvic drop", "heel lift"],
        "muscles": ["quads (eccentric)", "glute med", "soleus"],
    },
    "foot-flattener-back-foot-off-floor": {
        "intent": "Heavy heel, relaxed toes — load the heel and arch so the foot spreads flat under the body's weight.",
        "joints": ["ankle dorsiflexion", "subtalar pronation", "hip flexion (stance)"],
        "compensations": ["ankle inversion", "toe gripping"],
        "muscles": ["tib post", "peroneus longus", "intrinsic foot"],
    },
    "pigeon-stretch": {
        "intent": "Lengthen the deep external rotators of the hip — open the back of the hip socket in flexion.",
        "joints": ["hip external rotation (length)", "hip flexion"],
        "compensations": ["pelvic rotation off-square"],
        "muscles": ["piriformis (length)", "deep hip rotators", "glute max (length)"],
    },

    # ─── DAY E — LOCOMOTION / INTEGRATION ────────────────────────────────
    "rope-flow": {
        "intent": "Continuous low-amplitude rope flow — let the arms float from the ribs and the pelvis respond, not lead. Easy breathing throughout.",
        "joints": ["thoracic rotation", "shoulder reciprocal motion", "pelvic counter-rotation"],
        "compensations": ["shoulder tension", "pelvis leading the motion"],
        "muscles": ["serratus anterior", "obliques (reciprocal)", "deep core"],
    },
    "marching-drills": {
        "intent": "Heel rolls to midfoot, pelvis alternates smoothly, arm swing stays reciprocal — train the contralateral pattern at walking speed.",
        "joints": ["hip flexion + extension (alternating)", "ankle plantarflexion → dorsiflexion roll", "thoracic counter-rotation"],
        "compensations": ["heel slap (no roll)", "pelvic stiffness", "ipsilateral arm swing"],
        "muscles": ["psoas", "tib ant", "glute med", "obliques"],
    },
}
