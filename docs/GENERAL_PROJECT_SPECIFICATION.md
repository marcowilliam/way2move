# Way2Move — General Product Specification

> This document is the authoritative product specification.
> All data structures reflect the finalized v1 data model (see `DATA_MODEL.md`).
> Last updated: March 30, 2026 (Phase 2 Blocks 0-2 complete)

---

## Name

**Way2Move**

---

## Pitch

### Problem

People who train across multiple sports and movement disciplines while holding a normal job face:

- **No single place to organize training** across different sports, movement patterns, and planes of motion
- **Compensations and imbalances accumulate** without structured corrective work rooted in PRI/DNS methodology
- **No body awareness system** — people don't connect how they feel (journal) with what they should train
- **Nutrition tracking is tedious** — most people know they should track but the friction is too high, especially those managing IBS or gut sensitivity
- **Sleep and recovery are ignored** despite being the #1 performance lever
- **No progression system** — people repeat the same workouts without knowing if they're improving or regressing
- **No understanding of gait** — people run and walk without understanding the mechanics, leading to compensations
- **Time is scarce** — building a balanced weekly program across push/pull/squat/hinge/rotation/lateral/plyo/corrective is overwhelming

Today, a "normal life athlete" uses 3-5 apps (notes, spreadsheets, MyFitnessPal, sleep tracker) and still can't answer: "Am I balanced? What should I train next? Am I recovering enough?"

### Solution

Way2Move is a movement-first training platform that rebuilds your body from the ground up. It provides:

- A **voice-first daily logging** system — say what you did, the app creates sessions, meals, and journal entries automatically
- A **journaling system** (wake-up, pre/post-session, bedtime) that builds body awareness and connects how you feel to what you should train
- A **body awareness → compensation profile** that evolves with your journals, assessments, and breakthroughs
- **Goal-driven training** — final goals (2min deep squat, 2min hang, 15sec handstand) linked to which compensations they fix and which exercises build toward them
- A **smart exercise library** tagged by sport, movement pattern, plane of motion, type, and gait cycle phase — heavily rooted in PRI (Postural Restoration Institute) methodology
- **Gait cycle education** — understand walking and running from the ground up, see how exercises map to each phase
- **Recovery sessions** as first-class citizens — foam roller, lacrosse ball, standing meditation, breathwork
- **Flexible weekly programming** with goals (e.g., "8-week posture reset")
- **Nutrition MVP** — log meals, track stomach feelings (IBS awareness), voice-based end-of-day summary
- **Sleep logging** that adjusts training recommendations based on recovery
- **Progress photos and weight tracking** for visual progression
- A **motivating dashboard** — what to do today, how the week has been, monthly overview, and goal reminders when you miss a day
- A **camera-based movement assessment** (Phase 2) that identifies compensations and imbalances

### Vision

> The movement operating system for normal life athletes — from the ground up

- Understand your body through daily journaling and body awareness
- See your compensations and what goals will fix them
- Get a structured path to move better, rooted in PRI/DNS science
- Track everything (training, recovery, food, sleep, how you feel) in one place — voice-first
- Auto-progress when you're ready, auto-deload when you're not
- Learn how your body moves through gait cycle education

---

## Product principles

- **Voice-first** — if it takes more than 10 seconds to log, it should accept voice
- **Body awareness over data** — journals and feelings drive training, not just numbers
- **Corrective first** — fix the foundation before building performance (PRI/DNS methodology)
- **Simple over comprehensive** — busy people need fast actions, not complex dashboards
- **Motivating, not guilty** — missed a day? Here's why your goals matter, not a streak-breaking guilt trip
- **Science-backed** — DNS, PRI, and evidence-based movement methodology
- **Ground up** — teach people to walk before they run, literally (gait cycle education)
- **Recovery-aware** — sleep, recovery sessions, and how you feel gate progression, not just effort

---

## Target users

- **Recreational athletes** — runners, climbers, martial artists, CrossFitters who want to move better alongside their sport
- **Longevity athletes** — people focused on moving well for life, not competition
- **Desk workers recovering** — sedentary people rebuilding movement capacity from the ground up
- **Multi-sport athletes** — people who train across many disciplines and struggle to organize it all
- **IBS/gut-sensitive people** — those who need to track how food affects their body, not just macros

Common trait: they have a normal job, limited time, and no dedicated coach.

---

## Roadmap

### Phase 1 — Training System + Body Awareness (MVP) `mobile`
Goal: Organize training, build body awareness through journaling, track compensations, set movement goals, log nutrition simply, and see motivating progress — all voice-first.

**Core Training:**
- Profile creation (athlete) with onboarding assessment
- Exercise library (pre-loaded corrective/functional + user-added) with PRI/DNS focus
- Exercise taxonomy (sport, pattern, plane, type, region, equipment, gait phase tags)
- Gait cycle educational content integrated into exercise library
- Program creation with weekly templates and goals
- Session builder (assign exercises with sets/reps/duration)
- Recovery sessions as first-class (foam roller, lacrosse ball, standing meditation, breathwork)
- Session completion tracking (planned vs actual)
- Auto-progression logic (configurable: default 3x completed + good recovery)

**Body Awareness & Goals:**
- Journaling system (wake-up, pre-session, post-session, bedtime) — voice-first
- Body awareness → compensation profile (journals + assessments populate imbalances)
- Goal system — final movement goals linked to compensations, exercises, and sport
- Manual movement assessment (guided questions + video recording for reference)
- Breakthroughs linked to compensations they resolve

**Daily Logging:**
- Voice daily summary → auto-create sessions and meals from transcription
- Option for text input and manual entry per session/meal

**Nutrition MVP:**
- Meal logging (what you ate + stomach feeling for IBS body awareness)
- Voice message end of day → auto-create meal entries
- Per-meal manual entry option
- Daily meal overview

**Tracking:**
- Sleep logging (manual: bed time, wake time, quality)
- Progress photos (front/side/back timeline)
- Weight logging
- Calendar view with scheduled sessions
- Google Calendar + Apple Calendar sync (one-way push)

**Dashboard:**
- Motivating home screen: today's tasks, weekly overview, monthly glance
- Goal progress visualization
- Missed day? Remind of goals, not guilt
- Consistency tracking

**Infrastructure:**
- Firebase Auth (email, Google, Apple)
- Device speech-to-text (free, offline) for voice features

### Phase 2 — AI Movement Assessment `mobile`
Goal: On-device video-based analysis that upgrades the manual assessment from Phase 1

- **On-device pose estimation** via `flutter_pose_detection` (MediaPipe BlazePose, 33 landmarks) — no external API, works offline
- Video recording flow: 5 screening movements (overhead squat, single-leg stance, forward bend, shoulder raise, walking gait)
- Threshold-based compensation detection from pose landmarks (knee valgus, limited dorsiflexion, weak glute med, rounded shoulders, forward head posture)
- Severity scoring by frame ratio (mild < 30%, moderate 30-60%, significant > 60%)
- Merge video-based + questionnaire-based compensation results (video severity takes precedence)
- Rule-based program recommendations from detected compensations
- Before/after comparison (pose overlay, side-by-side video, improvement charts)
- Re-assessment scheduling and progress tracking
- Auto-update compensation profile from analysis

### Phase 3 — Advanced Nutrition `mobile`
Goal: Upgrade nutrition MVP with AI-powered tracking and meal planning

- Photo-based food recognition (external AI API → calories/macros)
- Text description input as fallback
- Full macro tracking (protein/carbs/fat targets based on user profile)
- Daily/weekly nutrition dashboard with macro ring charts
- Meal planning (schedule meals for the week)
- Grocery list generation
- Cloud speech-to-text API upgrade for better voice accuracy

### Phase 4 — Smart Recovery `mobile`
Goal: Close the recovery loop with data

- **Phase 4a (after Phase 1):** Recovery score v1 using sleep quality, training load, weekly pulse, and stomach feeling — enough for useful recommendations without Phase 3
- **Phase 4b (after Phase 3):** Enhanced score adds caloric deficit/surplus, macro adherence, and hydration data
- Training adjustment recommendations based on recovery score (green/yellow/red zones)
- Wearable integration (Apple Watch, Garmin) — read sleep data automatically
- Weekly/monthly recovery trends
- Auto-deload suggestions when recovery is poor

### Phase 5 — Social & Coaching `mobile`
Goal: Community and expert guidance

- Coach role introduction
- Coach can create programs for athletes
- Share workouts and programs
- Community exercise library contributions
- Progress sharing

### Phase 6 — Deployment & Distribution `mobile`
Goal: Ship to real users

- App Store + Google Play setup
- Branding, icons, splash screen
- Privacy policy, Terms of Service
- Production Firebase environment
- Freemium model implementation

> Note: Phase 6 can start partially in parallel with late Phase 1 (accounts and branding don't require feature-complete code).

---

## Phase 1 — Full Specification

### Objective

Build a training and body awareness system that helps normal life athletes organize their movement practice, understand their compensations, set movement goals, and track everything — training, recovery, nutrition, sleep, and how they feel — with voice as the primary input method.

---

### User roles

Phase 1: **Single role — Athlete** (self-guided, no coach)

| Role | Can do |
|---|---|
| Athlete | Create profile, take assessment, journal (voice), build programs, track sessions, log meals, log sleep, track compensations, set goals, view progress |

Future phases add Coach role.

---

### Core concepts

#### Voice-first logging

The app's primary input method is voice. Users can:

1. **End-of-day bedtime voice summary**: "Today I did 30 minutes of foam roller work on my IT bands, then 20 minutes of PRI breathing. For lunch I had chicken and rice, stomach felt fine. Dinner was pasta, felt a bit bloated after."
   - System parses and auto-creates: recovery session, meals with stomach ratings
2. **Per-moment voice**: record a journal entry or log a session as it happens
3. **Text fallback**: everything that accepts voice also accepts typed text
4. **Manual entry**: traditional form-based input for users who prefer it

**Phase 1 implementation**: Device speech-to-text (free, offline). Phase 3 upgrades to cloud API for better accuracy.

#### Journaling system

Four journal types, all voice-first:

| Type | When | Purpose | Auto-actions |
|---|---|---|---|
| **Wake-up** | Morning | How you feel, energy level, any pain, intentions | Updates body awareness, flags recovery issues |
| **Pre-session** | Before training | Current state, what you'll focus on, any limitations | Links to upcoming session |
| **Post-session** | After training | How it went, what you noticed, breakthroughs | Links to completed session, updates compensation profile |
| **Bedtime** | End of day | Summarize the day: training, meals, feelings, reflections | Auto-creates sessions, meals, updates body awareness |

The bedtime journal is the catch-all: if you didn't log anything during the day, describe it all here and the system creates the records. If you already logged everything, just say how you're feeling.

#### Body awareness and compensation profile

The user's **compensation profile** is built from multiple sources:

1. **Initial assessment** — guided questions identify starting compensations
2. **Journal entries** — "my left hip feels tight", "knee caved in during squats" → system updates compensation profile
3. **Weekly pulse check-ins** — body map pain points feed into profile
4. **Session notes** — RPE, pain, difficulty observations
5. **Breakthroughs** — when a user achieves a goal or masters an exercise, related compensations are marked as improving/resolved

Compensations are categorized:
- **Type**: mobility deficit, stability deficit, motor control issue, strength imbalance, postural pattern
- **Region**: specific body area (left hip, right shoulder, thoracic spine, etc.)
- **Severity**: mild / moderate / severe
- **Status**: active / improving / resolved
- **Related goals**: which movement goals will address this compensation

#### Goal system

Users have **movement goals** — concrete, measurable targets:

| Example Goal | Target | Related Compensations | Key Exercises |
|---|---|---|---|
| Deep squat (active) | 2 minutes | Ankle dorsiflexion deficit, hip mobility, thoracic extension | Goblet squat holds, ankle mobilizations, thoracic CARs |
| Active hang | 2 minutes | Shoulder protraction, thoracic kyphosis, grip weakness | Dead hangs, scapular pull-ups, thoracic extensions |
| Handstand hold | 15 seconds | Shoulder stability, core control, wrist mobility | Wall walks, hollow body holds, wrist CARs |
| Pain-free running | 30 min continuous | Gait cycle deficiencies, hip stability, foot mechanics | Gait drills, single-leg RDL, calf raises |

Goals can be:
- **Suggested**: auto-generated from the user's compensation profile and sport
- **Custom**: user-defined with their own targets
- **Linked**: each goal maps to compensations it addresses, exercises that build toward it, and categories

Progress toward goals is tracked and visualized on the dashboard.

#### Exercise taxonomy

Every exercise is tagged across multiple dimensions. The user sees simple filters; the app uses the full taxonomy to power smart suggestions, balance checking, and gait cycle education.

| Dimension | Examples | User-facing? |
|---|---|---|
| **Sport/Purpose** | running, flying, strength, cardio, mobility, longevity, corrective | Yes — primary filter |
| **Movement pattern** | push, pull, squat, hinge, carry, rotation, anti-rotation, gait | Behind the scenes |
| **Plane of motion** | sagittal (flexion/extension), frontal (lateral), transverse (rotation) | Behind the scenes |
| **Type** | corrective, strength, cardio, plyometric, mobility, DNS, PRI, breathing, recovery | Yes — secondary filter |
| **Body region** | upper, lower, core, full-body | Yes — filter |
| **Equipment** | bodyweight, band, dumbbell, barbell, kettlebell, foam roller, lacrosse ball, none | Yes — filter |
| **Gait phase** | stance (loading response, midstance, terminal stance), swing (pre-swing, initial swing, mid-swing, terminal swing) | Educational — shown in gait view |

The user filters by Sport, Type, Body region, and Equipment. The app uses Pattern, Plane, and Gait Phase internally for balanced programming, gait education, and smart suggestions.

#### Gait cycle education

Way2Move teaches users to move from the ground up. The gait cycle is broken down into phases, and exercises are mapped to which phase they help with:

**Gait Cycle Phases:**
1. **Stance Phase** (~60% of cycle)
   - Initial Contact (heel strike)
   - Loading Response (weight acceptance)
   - Midstance (single-leg support)
   - Terminal Stance (heel off)
   - Pre-Swing (toe off)
2. **Swing Phase** (~40% of cycle)
   - Initial Swing (acceleration)
   - Mid-Swing (limb advancement)
   - Terminal Swing (deceleration)

**In the app:**
- Exercises have `gaitPhaseTags` showing which phases they strengthen
- Educational content explains each phase with visuals
- Users with running/walking goals see which gait phases need work based on their compensations
- "Gait view" in exercise library groups exercises by gait phase

#### Exercise library

**Pre-loaded exercises (~80-100 for MVP):**

Curated corrective and functional movements based on DNS, PRI, and physiotherapy best practices:

| Category | Examples |
|---|---|
| **Breathing** | Diaphragmatic breathing, 90/90 breathing, balloon breathing, crocodile breathing |
| **DNS developmental** | Dead bug, bear position, rolling patterns, quadruped rocking, baby get-up, crawling variations |
| **PRI patterns** | Left AIC pattern reset, right BC pattern reset, 90/90 hip shift, hamstring activation with balloon, left sidelying respiratory adductor pullback |
| **Mobility** | Hip CARs, shoulder CARs, thoracic rotation, ankle dorsiflexion, wrist CARs |
| **Stability** | Pallof press, bird dog, single-leg stance progressions, Turkish get-up progressions |
| **Strength fundamentals** | Squat, deadlift/hinge, push-up, row, overhead press, lunge — with regressions |
| **Plyometric** | Box jump, broad jump, skipping, lateral bounds |
| **Recovery** | Foam roller thoracic extension, lacrosse ball plantar release, standing meditation, body scan |
| **Gait-specific** | A-skip, B-skip, marching, bounding, carioca, grapevine, heel walks, toe walks |
| **Hypermobility management** | End-range isometrics, controlled articular rotations with load, joint packing drills |

Each exercise has a **progression chain** (easier → harder variations):
```
Dead bug (basic) → Dead bug + band → Dead bug + weight → Dead bug + ball between knees + alternating reach
```

**User-added exercises:**
- Name, description, tags
- Video link from YouTube or Instagram as demo
- Custom progression/regression links to other exercises

#### Assessment system

**Initial assessment (onboarding — Phase 1):**
1. User records themselves performing 5-7 key screening movements:
   - Overhead squat
   - Single-leg balance (both sides)
   - Toe touch / forward fold
   - Shoulder mobility (reach behind back)
   - Deep squat hold
   - Inline lunge
   - Push-up position hold
2. App asks guided questions for each movement:
   - "Did you feel tightness? Where?" (body map tap)
   - "Did your knees cave inward?" (yes/no/not sure)
   - "Could you maintain balance?" (stable/wobbled/fell)
3. Videos are saved for future AI analysis (Phase 2) and before/after comparison
4. Results: identified compensations → populate compensation profile → suggest goals → recommend starter program

**Weekly pulse (quick check-in, ~2 min):**
- How do you feel overall? (1-5 scale)
- Any pain or discomfort? (body map tap)
- Sleep quality this week? (auto-filled from sleep logs)
- Energy level? (1-5)
- Stomach/gut feeling? (1-5, for IBS awareness)

**Full re-assessment:** every 4-8 weeks (configurable), repeats the initial screening.

#### Training structure

```
Program ("8-week posture reset")
  └── Week Template (repeats for program duration)
       └── Day (Mon: Upper corrective, Wed: Lower strength, Fri: Full body mobility)
            └── Exercise Block (Dead bug: 3 sets × 10 reps, 30s rest)
```

- **Programs** have a name, goal description, duration in weeks, and a weekly template that repeats
- **Week templates** define which days the user trains and what focus each day has
- **Sessions** are a specific day's workout — generated from the template but fully editable
- **Exercise blocks** within a session: exercise + sets + reps (or duration) + rest + load + notes
- **Standalone sessions** (no program) for quick workouts
- **Recovery sessions** are a specific session type: foam roller, lacrosse ball, standing meditation, breathwork, stretching

#### Recovery sessions

Recovery sessions are first-class citizens, not afterthoughts. They:
- Appear in the calendar like training sessions
- Count toward daily activity and streak
- Have their own session type: `recovery`
- Include: foam rolling, lacrosse ball work, standing meditation, breathwork, gentle stretching, body scan
- Can be logged via voice ("I did 20 minutes of foam roller on my quads and IT bands")
- Contribute to the recovery picture (doing recovery work = better recovery score in Phase 4)

#### Auto-progression

The app auto-progresses exercises when conditions are met. **Configurable by user:**

| Parameter | Default | Range |
|---|---|---|
| Completions required | 3 | 2-5 |
| Sleep quality threshold | 3/5 | 1-5 |
| Weekly pulse threshold | 3/5 | 1-5 |

**Progression actions:**
- Increase reps (e.g., 8 → 10 → 12)
- Increase load (if applicable)
- Advance to harder variation (follow progression chain)
- Unlock new exercises in the program

**Deload triggers:**
- Sleep quality below threshold for 3+ days
- Weekly pulse below threshold
- User reports pain/discomfort on body map
- Stomach/gut issues reported consistently (IBS awareness)
- App suggests lighter corrective work or rest day

#### Nutrition MVP

Phase 1 nutrition is about **awareness, not optimization**. The focus is:

1. **What did I eat?** — simple meal logging
2. **How does my stomach feel?** — IBS body awareness (1-5 scale + descriptors: bloated, cramping, fine, great)
3. **Patterns over time** — "every time I eat X, my stomach feels Y"

**Input methods (priority order):**
1. Voice (bedtime summary or per-meal): "For lunch I had a big salad with chicken, stomach felt fine"
2. Text: quick typed description
3. Manual form: structured entry with meal type, foods, stomach rating

**Not in Phase 1:** macro tracking, calorie counting, photo recognition, meal planning. Those are Phase 3.

#### Sleep logging (manual — Phase 1)

| Field | Type |
|---|---|
| Bed time | DateTime |
| Wake time | DateTime |
| Quality rating | 1-5 scale |
| Notes | Free text (optional) |

Calculated: total hours, sleep efficiency estimate.
Used by: auto-progression logic, deload triggers, weekly pulse auto-fill.

#### Progress photos and weight

- **Progress photos**: front, side, back — taken at regular intervals (weekly/monthly)
- **Weight logging**: simple weight entry, trend chart over time
- **Visual timeline**: swipe through photos chronologically, compare side-by-side
- Photos stored in Firebase Storage, references in Firestore

---

### Data model summary

Full schema in `DATA_MODEL.md`. Summary:

| Collection | Contents |
|---|---|
| `users` | Profile, goals, sports, equipment, activity level |
| `exercises` | Exercise catalog — built-in + user-created, with full taxonomy tags including gait phase |
| `programs` | Training programs with weekly templates |
| `sessions` | Individual workout sessions — training + recovery types |
| `assessments` | Movement assessments (initial, weekly pulse, full re-assessment) |
| `videoAnalyses` | Phase 2: per-movement video analysis results (pose frames, detected compensations, severity) |
| `journals` | Voice/text journal entries (wake-up, pre-session, post-session, bedtime) |
| `compensations` | User's compensation profile — active imbalances, improvements, resolutions |
| `goals` | Movement goals linked to compensations, exercises, and sport |
| `meals` | Meal entries with stomach feeling (nutrition MVP) |
| `sleepLogs` | Manual sleep entries |
| `progressPhotos` | Progress photo entries with Firebase Storage URLs |
| `weightLogs` | Weight tracking entries |
| `progressionRules` | User's auto-progression configuration |

---

### Phase 1 screens

1. **Onboarding** — profile setup (name, age, goals, sports, equipment, injuries)
2. **Initial Assessment** — guided movement screening with video recording + questions → compensation profile
3. **Goal Setup** — suggested goals from assessment + custom goals, linked to compensations
4. **Home/Dashboard** — today's tasks, current program progress, streak, weekly overview, monthly glance, goal reminders
5. **Calendar** — month/week view, tap to see/create sessions (training + recovery), synced to Google/Apple Calendar
6. **Exercise Library** — browse/search/filter, view demos, gait phase view, add custom exercises
7. **Gait Cycle View** — educational breakdown of gait phases, exercises mapped to each phase
8. **Program Builder** — create program, set goal + duration, build weekly template, assign exercises
9. **Session View** — today's workout, mark exercises complete, adjust reps/weight, log notes
10. **Recovery Session** — foam roller, lacrosse ball, meditation, breathwork — track duration and body areas worked
11. **Session Summary** — post-workout: planned vs actual, auto-progression suggestions, prompt for post-session journal
12. **Journal** — voice-first entry, four types (wake/pre/post/bed), history view
13. **Compensation Profile** — body map showing active compensations, improvement history, linked goals
14. **Goals** — movement goal cards with progress bars, linked exercises and compensations
15. **Nutrition Log** — daily meals, stomach feeling tracker, voice or manual entry
16. **Progress Photos** — capture front/side/back, timeline view, compare
17. **Weight Log** — simple entry, trend chart
18. **Sleep Log** — quick entry for last night's sleep
19. **Progress** — consistency charts, assessment history, compensation improvements, goal progress
20. **Profile/Settings** — edit profile, manage equipment, injuries, progression rules

---

### Profile

| Field | Type | Notes |
|---|---|---|
| Display name | string | |
| Avatar | string | Photo upload, Firebase Storage |
| Email | string | From auth |
| Age | int | Used for program calibration |
| Height | double | cm — used for nutrition (Phase 3) |
| Weight | double | kg — used for nutrition (Phase 3) |
| Activity level | enum | sedentary / lightly_active / active / very_active |
| Training goal | enum | move_better / rehab / sport_performance / longevity |
| Sports practiced | string[] | Multi-select tags |
| Training days per week | int | Used to build weekly template |
| Available equipment | string[] | Multi-select — filters exercise suggestions |
| Injuries / limitations | string | Free text + body region tags |

---

### Exercise entity

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| name | string | e.g., "Dead Bug with Balloon" |
| description | string | How to perform the exercise |
| videoUrl | string? | Built-in demo URL or YouTube/Instagram link |
| sportTags | string[] | running, flying, strength, cardio, etc. |
| patternTags | string[] | push, pull, squat, hinge, carry, rotation, gait |
| planeTags | string[] | sagittal, frontal, transverse |
| typeTags | string[] | corrective, strength, cardio, plyo, mobility, DNS, PRI, breathing, recovery |
| regionTags | string[] | upper, lower, core, full-body |
| equipmentTags | string[] | bodyweight, band, dumbbell, barbell, foam_roller, lacrosse_ball, etc. |
| gaitPhaseTags | string[] | loading_response, midstance, terminal_stance, pre_swing, initial_swing, mid_swing, terminal_swing |
| difficulty | enum | beginner / intermediate / advanced |
| isBuiltIn | bool | true = pre-loaded seed data, false = user-created |
| createdBy | string? | userId for user-created exercises |
| progressionIds | string[] | Harder variations (exercise refs) |
| regressionIds | string[] | Easier variations (exercise refs) |
| cues | string[] | Coaching cues ("Press low back into floor", "Exhale fully") |
| compensationsTargeted | string[] | Which compensations this exercise helps address |

---

### Session entity

| Field | Type | Description |
|---|---|---|
| id | string | |
| userId | string | |
| programId | string? | null for standalone sessions |
| date | DateTime | Scheduled date |
| status | enum | planned / completed / skipped |
| type | enum | training / recovery / mobility / breathing |
| focus | string | e.g., "Upper body push + corrective" or "Foam roller — lower body" |
| exerciseBlocks | ExerciseBlock[] | Ordered exercise list |
| plannedDuration | int? | Estimated minutes |
| actualDuration | int? | Logged after completion |
| notes | string? | |
| source | enum | manual / program / voice | How this session was created |
| createdAt | Timestamp | |

### ExerciseBlock

| Field | Type | Description |
|---|---|---|
| exerciseId | string | Reference to exercise |
| order | int | Position in session |
| sets | int | Planned sets |
| reps | int? | Planned reps (null if duration-based) |
| duration | int? | Seconds (null if rep-based) |
| restSeconds | int | Rest between sets |
| weight | double? | Load in kg (if applicable) |
| completedSets | int? | Actual sets done |
| completedReps | int? | Actual reps per set |
| notes | string? | |

---

### Journal entity

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| userId | string | |
| date | DateTime | |
| type | enum | wake_up / pre_session / post_session / bedtime |
| content | string | Transcribed text from voice or typed text |
| audioUrl | string? | Firebase Storage URL for voice recording (optional, kept for reference) |
| mood | int? | 1-5 scale (optional) |
| energyLevel | int? | 1-5 scale (optional) |
| painPoints | string[] | Body regions mentioned (parsed from content) |
| linkedSessionId | string? | For pre/post session journals |
| autoCreatedEntities | Map? | References to sessions/meals auto-created from this journal |
| createdAt | Timestamp | |

---

### Compensation entity

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| userId | string | |
| name | string | e.g., "Anterior pelvic tilt", "Left hip mobility deficit" |
| type | enum | mobility_deficit / stability_deficit / motor_control / strength_imbalance / postural_pattern |
| region | string | Body region (e.g., "left_hip", "thoracic_spine") |
| severity | enum | mild / moderate / severe |
| status | enum | active / improving / resolved |
| source | enum | assessment / journal / manual |
| relatedGoalIds | string[] | Goals that address this compensation |
| relatedExerciseIds | string[] | Exercises that help fix this |
| history | CompensationUpdate[] | Severity changes over time |
| detectedAt | DateTime | When first identified |
| resolvedAt | DateTime? | When marked as resolved |
| createdAt | Timestamp | |

---

### Goal entity

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| userId | string | |
| name | string | e.g., "Deep Squat — 2 minutes active" |
| description | string | What this goal means and why it matters |
| category | enum | mobility / strength / balance / endurance / sport_specific |
| targetMetric | string | e.g., "duration", "hold_time", "distance" |
| targetValue | double | e.g., 120 (seconds), 15 (seconds) |
| currentValue | double? | Current best |
| unit | string | seconds, reps, meters, etc. |
| sport | string? | Related sport (if sport-specific) |
| compensationIds | string[] | Which compensations this goal addresses |
| exerciseIds | string[] | Exercises that build toward this goal |
| source | enum | suggested / custom |
| status | enum | not_started / in_progress / achieved |
| achievedAt | DateTime? | |
| createdAt | Timestamp | |

---

### Meal entity (Nutrition MVP)

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| userId | string | |
| date | DateTime | |
| mealType | enum | breakfast / lunch / dinner / snack |
| description | string | What was eaten (free text) |
| stomachFeeling | int | 1-5 scale (1=terrible, 5=great) |
| stomachNotes | string? | Descriptors: bloated, cramping, fine, energized, etc. |
| source | enum | voice / text / manual |
| linkedJournalId | string? | If auto-created from a bedtime journal |
| createdAt | Timestamp | |

---

### Assessment entity

| Field | Type | Description |
|---|---|---|
| id | string | |
| userId | string | |
| date | DateTime | |
| type | enum | initial / weekly_pulse / full_reassessment |
| responses | Map<string, dynamic> | Question key → answer |
| compensationsFound | string[] | CompensationPattern enum names from questionnaire |
| movementScores | MovementScore[] | Per-movement name + score (0-10) + notes |
| overallScore | int? | 0-10 movement quality score |
| recommendedProgramId | string? | Auto-generated program reference |
| createdAt | Timestamp | |

> **Phase 2 addition:** Video analysis results are stored in a separate `videoAnalyses` collection (one doc per screening movement per assessment), linked by `assessmentId`. See `DATA_MODEL.md` for the full `videoAnalyses` schema. Questionnaire and video results are merged at read time via `CompensationReport.merge()`.

---

### SleepLog entity

| Field | Type | Description |
|---|---|---|
| id | string | |
| userId | string | |
| date | DateTime | The night of (e.g., March 28 for sleeping 28→29) |
| bedTime | DateTime | |
| wakeTime | DateTime | |
| qualityRating | int | 1-5 |
| totalHours | double | Calculated |
| notes | string? | |
| createdAt | Timestamp | |

---

### ProgressPhoto entity

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| userId | string | |
| date | DateTime | |
| photoUrl | string | Firebase Storage URL |
| angle | enum | front / side_left / side_right / back |
| notes | string? | |
| createdAt | Timestamp | |

---

### WeightLog entity

| Field | Type | Description |
|---|---|---|
| id | string | Auto-generated |
| userId | string | |
| date | DateTime | |
| weight | double | kg |
| notes | string? | |
| createdAt | Timestamp | |

---

### Calendar integration

- Sessions (training + recovery) and programs push to Google Calendar / Apple Calendar (one-way sync)
- Uses respective calendar APIs
- Each session becomes a calendar event with title, time, and exercise summary
- Recovery sessions show as distinct event type
- Changes in Way2Move update the calendar event
- Calendar deletions do NOT delete sessions in the app

---

### MVP scope

#### Included in Phase 1
- Exercise library with taxonomy including gait phase tags (pre-loaded + user-added)
- Gait cycle educational content
- Manual assessment (guided questions + video recording)
- Body awareness → compensation profile
- Goal system (suggested + custom, linked to compensations)
- Program creation with weekly templates and goals
- Session tracking — training + recovery types (planned vs completed)
- Recovery sessions as first-class citizens
- Journaling system (4 types, voice-first with device speech-to-text)
- Voice daily summary → auto-create sessions and meals
- Nutrition MVP (meals + stomach feeling + voice)
- Auto-progression logic (configurable)
- Calendar view + Google/Apple Calendar sync
- Manual sleep logging
- Progress photos + weight tracking
- Recovery-aware progression (sleep gates auto-progression)
- Motivating dashboard with goal reminders
- Firebase Auth (email, Google, Apple)

#### Excluded from Phase 1
- On-device pose estimation + video-based compensation detection → Phase 2
- Full macro/calorie tracking → Phase 3
- Photo food recognition → Phase 3
- Meal planning → Phase 3
- Cloud speech-to-text API → Phase 3
- Wearable integration → Phase 4
- Coach role → Phase 5

---

## Tech stack summary

Full details in `CLAUDE.md` and `.claude/rules/`.

| Layer | Technology |
|---|---|
| Mobile | Flutter (iOS + Android) |
| Backend | Firebase: Auth, Firestore, Cloud Functions, Storage |
| Language | Dart (Flutter), TypeScript (Functions) |
| State management | Riverpod |
| Architecture | Clean Architecture (Domain ← Data, Presentation → Domain) |
| Navigation | GoRouter |
| Error handling | Either (fpdart) |
| Voice input | Device speech-to-text (speech_to_text package) — Phase 1 |
| Testing | flutter_test + mocktail + Firebase emulator |
