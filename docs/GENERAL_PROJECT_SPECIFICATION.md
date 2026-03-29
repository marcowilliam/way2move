# Way2Move — General Product Specification

> This document is the authoritative product specification.
> All data structures reflect the finalized v1 data model (see `DATA_MODEL.md`).
> Last updated: Day 1 — March 29, 2026

---

## Name

**Way2Move**

---

## Pitch

### Problem

People who train across multiple sports and movement disciplines while holding a normal job face:

- **No single place to organize training** across different sports, movement patterns, and planes of motion
- **Compensations and imbalances accumulate** without structured corrective work
- **Nutrition tracking is tedious** — most people know they should track but the friction is too high
- **Sleep and recovery are ignored** despite being the #1 performance lever
- **No progression system** — people repeat the same workouts without knowing if they're improving or regressing
- **Time is scarce** — building a balanced weekly program across push/pull/squat/hinge/rotation/lateral/plyo/corrective is overwhelming

Today, a "normal life athlete" uses 3-5 apps (notes, spreadsheets, MyFitnessPal, sleep tracker) and still can't answer: "Am I balanced? What should I train next? Am I recovering enough?"

### Solution

Way2Move is a movement-first training platform that rebuilds your body from the ground up. It provides:

- A **camera-based movement assessment** that identifies compensations and imbalances
- **Auto-generated corrective and training programs** based on DNS and PRI methodology
- A **smart exercise library** tagged by sport, movement pattern, plane of motion, and type
- **Flexible weekly programming** with goals (e.g., "8-week posture reset")
- **Photo-based nutrition tracking** — snap a photo, get macros
- **Sleep logging** that adjusts training recommendations based on recovery
- **Calendar integration** — sync with Google/Apple Calendar so training fits your life

### Vision

> The movement operating system for normal life athletes

- Assess where your body is today
- Get a structured path to move better
- Track everything (training, food, sleep) in one place
- Auto-progress when you're ready, auto-deload when you're not

---

## Product principles

- **Simple over comprehensive** — busy people need fast actions, not complex dashboards
- **Corrective first** — fix the foundation before building performance
- **Science-backed** — DNS, PRI, and evidence-based movement methodology
- **Auto-organize** — the app handles categorization so the user doesn't have to
- **Recovery-aware** — sleep and recovery gate progression, not just effort

---

## Target users

- **Recreational athletes** — runners, climbers, martial artists, CrossFitters who want to move better alongside their sport
- **Longevity athletes** — people focused on moving well for life, not competition
- **Desk workers recovering** — sedentary people rebuilding movement capacity from the ground up
- **Multi-sport athletes** — people who train across many disciplines and struggle to organize it all

Common trait: they have a normal job, limited time, and no dedicated coach.

---

## Roadmap

### Phase 1 — Training System (MVP) `mobile`
Goal: Organize training, exercise library, flexible programming, manual assessment

- Profile creation (athlete)
- Exercise library (pre-loaded corrective/functional + user-added)
- Exercise taxonomy (sport, pattern, plane, type, region, equipment tags)
- Manual movement assessment (guided questions + video recording for reference)
- Program creation with weekly templates and goals
- Session builder (assign exercises with sets/reps/duration)
- Calendar view with scheduled sessions
- Session completion tracking (planned vs actual)
- Auto-progression logic (configurable: default 3x completed + good recovery)
- Google Calendar + Apple Calendar sync (one-way push)
- Sleep logging (manual: bed time, wake time, quality)
- Basic progress dashboard (consistency streaks, exercises completed)
- Firebase Auth (email, Google, Apple)

### Phase 2 — AI Movement Assessment `mobile`
Goal: Camera-based analysis that upgrades the manual assessment from Phase 1

- Pose estimation using MediaPipe / ML Kit on recorded movement videos
- Automated movement scoring from video analysis
- Compensation detection (knee valgus, excessive lordosis, shoulder protraction, lateral shift, etc.)
- Before/after comparison (initial assessment vs re-assessment)
- AI-generated corrective program recommendations based on detected imbalances
- Re-assessment scheduling and progress tracking

### Phase 3 — Nutrition `mobile`
Goal: Easy nutrition tracking that doesn't feel like work

- Photo-based food recognition (external AI API → calories/macros)
- Text description input as fallback
- Daily meal tracking (breakfast/lunch/dinner/snacks)
- Macro targets based on user profile (weight, height, activity level, goal)
- Daily/weekly nutrition dashboard
- Meal planning (schedule meals for the week)

### Phase 4 — Smart Recovery `mobile`
Goal: Close the recovery loop with data

- Recovery score calculation (sleep quality + subjective feel + training load)
- Training adjustment recommendations based on recovery score
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

Build a training system that helps normal life athletes organize their movement practice. An athlete can assess their movement, get a program, track sessions, and see progress — all in one place.

---

### User roles

Phase 1: **Single role — Athlete** (self-guided, no coach)

| Role | Can do |
|---|---|
| Athlete | Create profile, take assessment, build programs, track sessions, log sleep, view progress |

Future phases add Coach role.

---

### Core concepts

#### Exercise taxonomy

Every exercise is tagged across multiple dimensions. The user sees simple filters; the app uses the full taxonomy to power smart suggestions and balance checking.

| Dimension | Examples | User-facing? |
|---|---|---|
| **Sport/Purpose** | running, flying, strength, cardio, mobility, longevity, corrective | Yes — primary filter |
| **Movement pattern** | push, pull, squat, hinge, carry, rotation, anti-rotation | Behind the scenes |
| **Plane of motion** | sagittal (flexion/extension), frontal (lateral), transverse (rotation) | Behind the scenes |
| **Type** | corrective, strength, cardio, plyometric, mobility, DNS, PRI, breathing | Yes — secondary filter |
| **Body region** | upper, lower, core, full-body | Yes — filter |
| **Equipment** | bodyweight, band, dumbbell, barbell, kettlebell, foam roller, none | Yes — filter |

The user filters by Sport, Type, Body region, and Equipment. The app uses Pattern and Plane internally to ensure balanced programming and smart suggestions.

#### Exercise library

**Pre-loaded exercises (~60-80 for MVP):**

Curated corrective and functional movements based on DNS, PRI, and physiotherapy best practices:

| Category | Examples |
|---|---|
| **Breathing** | Diaphragmatic breathing, 90/90 breathing, balloon breathing, crocodile breathing |
| **DNS developmental** | Dead bug, bear position, rolling patterns, quadruped rocking, baby get-up, crawling variations |
| **PRI patterns** | Left AIC pattern reset, right BC pattern reset, 90/90 hip shift, hamstring activation with balloon |
| **Mobility** | Hip CARs, shoulder CARs, thoracic rotation, ankle dorsiflexion, wrist CARs |
| **Stability** | Pallof press, bird dog, single-leg stance progressions, Turkish get-up progressions |
| **Strength fundamentals** | Squat, deadlift/hinge, push-up, row, overhead press, lunge — with regressions |
| **Plyometric** | Box jump, broad jump, skipping, lateral bounds |
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
4. Results: identified compensations + recommended starter program

**Weekly pulse (quick check-in, ~2 min):**
- How do you feel overall? (1-5 scale)
- Any pain or discomfort? (body map tap)
- Sleep quality this week? (auto-filled from sleep logs)
- Energy level? (1-5)

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
- App suggests lighter corrective work or rest day

#### Sleep logging (manual — Phase 1)

| Field | Type |
|---|---|
| Bed time | DateTime |
| Wake time | DateTime |
| Quality rating | 1-5 scale |
| Notes | Free text (optional) |

Calculated: total hours, sleep efficiency estimate.
Used by: auto-progression logic, deload triggers, weekly pulse auto-fill.

---

### Data model summary

Full schema in `DATA_MODEL.md`. Summary:

| Collection | Contents |
|---|---|
| `users` | Profile, goals, sports, equipment, activity level |
| `exercises` | Exercise catalog — built-in + user-created, with full taxonomy tags |
| `programs` | Training programs with weekly templates |
| `sessions` | Individual workout sessions (planned/completed/skipped) |
| `assessments` | Movement assessments (initial, weekly pulse, full re-assessment) |
| `sleepLogs` | Manual sleep entries |
| `progressionRules` | User's auto-progression configuration |

---

### Phase 1 screens

1. **Onboarding** — profile setup (name, age, goals, sports, equipment, injuries)
2. **Initial Assessment** — guided movement screening with video recording + questions
3. **Home/Dashboard** — today's session, current program progress, streak, weekly overview
4. **Calendar** — month/week view, tap to see/create sessions, synced to Google/Apple Calendar
5. **Exercise Library** — browse/search/filter, view demos, add custom exercises
6. **Program Builder** — create program, set goal + duration, build weekly template, assign exercises
7. **Session View** — today's workout, mark exercises complete, adjust reps/weight, log notes
8. **Session Summary** — post-workout: planned vs actual, auto-progression suggestions
9. **Progress** — consistency charts, assessment history, compensation improvements
10. **Sleep Log** — quick entry for last night's sleep
11. **Profile/Settings** — edit profile, manage equipment, injuries, progression rules

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
| patternTags | string[] | push, pull, squat, hinge, carry, rotation |
| planeTags | string[] | sagittal, frontal, transverse |
| typeTags | string[] | corrective, strength, cardio, plyo, mobility, DNS, PRI, breathing |
| regionTags | string[] | upper, lower, core, full-body |
| equipmentTags | string[] | bodyweight, band, dumbbell, barbell, etc. |
| difficulty | enum | beginner / intermediate / advanced |
| isBuiltIn | bool | true = pre-loaded seed data, false = user-created |
| createdBy | string? | userId for user-created exercises |
| progressionIds | string[] | Harder variations (exercise refs) |
| regressionIds | string[] | Easier variations (exercise refs) |
| cues | string[] | Coaching cues ("Press low back into floor", "Exhale fully") |

---

### Program entity

| Field | Type | Description |
|---|---|---|
| id | string | |
| userId | string | Owner |
| name | string | e.g., "8-Week Posture Reset" |
| goal | string | What this program achieves |
| durationWeeks | int | How many weeks the template repeats |
| weekTemplate | WeekTemplate | Days → focus + exercise list |
| isActive | bool | Only one active program at a time |
| basedOnAssessment | bool | Auto-generated from assessment results? |
| createdAt | Timestamp | |

### WeekTemplate

| Field | Type | Description |
|---|---|---|
| days | Map<int, DayTemplate> | Day of week (1=Mon..7=Sun) → template |

### DayTemplate

| Field | Type | Description |
|---|---|---|
| focus | string | e.g., "Upper corrective + breathing" |
| exerciseBlocks | ExerciseBlock[] | Ordered exercises for this day |
| estimatedMinutes | int | Estimated session duration |

---

### Session entity

| Field | Type | Description |
|---|---|---|
| id | string | |
| userId | string | |
| programId | string? | null for standalone sessions |
| date | DateTime | Scheduled date |
| status | enum | planned / completed / skipped |
| focus | string | e.g., "Upper body push + corrective" |
| exerciseBlocks | ExerciseBlock[] | Ordered exercise list |
| plannedDuration | int? | Estimated minutes |
| actualDuration | int? | Logged after completion |
| notes | string? | |
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

### Assessment entity

| Field | Type | Description |
|---|---|---|
| id | string | |
| userId | string | |
| date | DateTime | |
| type | enum | initial / weekly_pulse / full_reassessment |
| responses | Map<string, dynamic> | Question key → answer |
| videoUrls | string[] | Recorded movement videos (Firebase Storage) |
| compensationsFound | string[] | Identified issues (e.g., "anterior_pelvic_tilt") |
| bodyMapPainPoints | string[] | Body regions with reported discomfort |
| overallScore | int? | 1-100 movement quality score |
| recommendedProgramId | string? | Auto-generated program reference |
| createdAt | Timestamp | |

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

### Calendar integration

- Sessions and programs push to Google Calendar / Apple Calendar (one-way sync)
- Uses respective calendar APIs
- Each session becomes a calendar event with title, time, and exercise summary
- Changes in Way2Move update the calendar event
- Calendar deletions do NOT delete sessions in the app

---

### MVP scope

#### Included in Phase 1
- Exercise library with taxonomy (pre-loaded + user-added)
- Manual assessment (guided questions + video recording)
- Program creation with weekly templates and goals
- Session tracking (planned vs completed)
- Auto-progression logic (configurable)
- Calendar view + Google/Apple Calendar sync
- Manual sleep logging
- Recovery-aware progression (sleep gates auto-progression)
- Basic progress dashboard
- Firebase Auth (email, Google, Apple)

#### Excluded from Phase 1
- AI pose estimation → Phase 2
- Nutrition tracking → Phase 3
- Wearable integration → Phase 4
- Coach role → Phase 5
- Photo food recognition → Phase 3
- Community features → Phase 5

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
| Testing | flutter_test + mocktail + Firebase emulator |
