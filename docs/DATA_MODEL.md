# Way2Move -- Data Model (Phase 1)

## Decisions Made

| Decision | Choice | Rationale |
|---|---|---|
| Exercise taxonomy | sport, pattern, plane, type, region, equipment tags | Multi-dimensional tagging enables flexible filtering and program generation |
| Training structure | Program -> WeekTemplate -> DayTemplate -> ExerciseBlock | Hierarchical templates allow repeatable weekly structure with day-level customization |
| Assessment model | Initial (guided questions + video), weekly pulse, full re-assessment | Tiered assessment: lightweight weekly check-ins, deep assessments at milestones |
| Sleep logging | Manual (bed time, wake time, quality 1-5) | Simple Phase 1 approach; wearable integration deferred to Phase 4 |
| Auto-progression | Configurable (default: 3x completed + good recovery) | Users can tune sensitivity; system defaults are conservative to avoid overtraining |
| Coach role | Not in Phase 1 | Phase 5 introduces coaching; Phase 1 is self-directed training only |
| Offline writes | Sessions and sleep logs queue offline | Training happens in gyms with poor connectivity; must not lose data |
| Exercise library | Built-in seed data + user-created exercises | Seed library covers common movements; users can add custom exercises |

---

## Firestore Collections

### users/{userId}

User profile and preferences. Created by the `onUserCreate` Cloud Function when
a new Firebase Auth account is created.

```json
{
  "id": "string (Firebase UID)",
  "name": "string",
  "email": "string",
  "avatarUrl": "string (Storage URL, nullable)",
  "age": "number (nullable)",
  "height": "number (cm, nullable)",
  "weight": "number (kg, nullable)",
  "activityLevel": "string (enum: sedentary | lightly_active | moderately_active | very_active | extremely_active)",
  "trainingGoal": "string (enum: general_fitness | strength | mobility | longevity | sport_specific | rehab)",
  "sportsTags": ["string (e.g. 'running', 'climbing', 'swimming')"],
  "trainingDaysPerWeek": "number (1-7)",
  "availableEquipment": ["string (enum: bodyweight | dumbbells | barbell | kettlebell | bands | cable_machine | pull_up_bar | bench | foam_roller | yoga_mat)"],
  "injuries": [
    {
      "bodyRegion": "string (e.g. 'left_shoulder', 'lower_back')",
      "description": "string",
      "severity": "string (enum: minor | moderate | severe)",
      "isActive": "boolean"
    }
  ],
  "meta": {
    "createdAt": "Timestamp (server)",
    "updatedAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Security rules:** Owner read/write only. `id`, `email`, `meta.createdAt` are immutable
after creation. Document created by Cloud Function only (no client create).

---

### exercises/{exerciseId}

Exercise definitions. Seed data is built-in (written by Cloud Functions). Users can
create custom exercises (marked `isBuiltIn: false`).

```json
{
  "id": "string (auto-generated or slug for seed data)",
  "name": "string",
  "description": "string",
  "videoUrl": "string (Storage URL, nullable -- Phase 2+)",
  "sportTags": ["string (e.g. 'running', 'climbing', 'general')"],
  "patternTags": ["string (enum: squat | hinge | push | pull | carry | rotate | lunge | gait | brace)"],
  "planeTags": ["string (enum: sagittal | frontal | transverse)"],
  "typeTags": ["string (enum: strength | mobility | stability | power | endurance | flexibility)"],
  "regionTags": ["string (enum: upper_body | lower_body | core | full_body)"],
  "equipmentTags": ["string (matches availableEquipment enum values)"],
  "difficulty": "number (1-5, where 1=beginner, 5=advanced)",
  "isBuiltIn": "boolean",
  "createdBy": "string (userId for custom exercises, 'system' for seed data)",
  "progressionIds": ["string (exerciseId -- harder variations)"],
  "regressionIds": ["string (exerciseId -- easier variations)"],
  "cues": ["string (coaching cues, e.g. 'Drive through heels', 'Brace your core')"],
  "meta": {
    "createdAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Security rules:** All authenticated users can read. Only Cloud Functions can write
built-in exercises. Users can create/update/delete their own custom exercises
(`isBuiltIn == false && createdBy == request.auth.uid`).

**Indexes:**
- `patternTags ARRAY, difficulty ASC` -- filter by movement pattern and sort by difficulty
- `sportTags ARRAY, typeTags ARRAY` -- filter by sport and exercise type
- `createdBy ASC, meta.createdAt DESC` -- list user's custom exercises

---

### programs/{programId}

Training programs with weekly structure. A program contains a week template that
repeats for `durationWeeks`. Each day in the template defines focus and exercise blocks.

```json
{
  "id": "string (auto-generated)",
  "userId": "string (owner)",
  "name": "string (e.g. 'General Fitness - 4 Week')",
  "goal": "string (matches trainingGoal enum)",
  "durationWeeks": "number",
  "weekTemplate": {
    "1": {
      "focus": "string (e.g. 'Upper Body Strength')",
      "exerciseBlocks": [
        {
          "exerciseId": "string",
          "order": "number (display order within the day)",
          "sets": "number",
          "reps": "number (nullable -- null for timed exercises)",
          "duration": "number (seconds, nullable -- null for rep-based)",
          "restSeconds": "number",
          "weight": "number (kg, nullable)",
          "notes": "string (nullable)"
        }
      ],
      "estimatedMinutes": "number"
    },
    "3": {
      "focus": "Lower Body + Mobility",
      "exerciseBlocks": [],
      "estimatedMinutes": 45
    }
  },
  "isActive": "boolean (only one program active per user at a time)",
  "basedOnAssessment": "string (assessmentId, nullable)",
  "startDate": "Timestamp",
  "meta": {
    "createdAt": "Timestamp (server)",
    "updatedAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Notes on weekTemplate:**
- Keys are day numbers (1 = Monday, 7 = Sunday). Only training days have entries.
- A user with `trainingDaysPerWeek: 3` might have keys "1", "3", "5".
- The template repeats each week for `durationWeeks`.

**Security rules:** Owner read/write only (`userId == request.auth.uid`).

**Indexes:**
- `userId ASC, isActive ASC` -- find user's active program
- `userId ASC, meta.createdAt DESC` -- list user's programs chronologically

---

### sessions/{sessionId}

Individual training sessions. Planned sessions are generated from the program template.
Users complete them by filling in actual performance data.

```json
{
  "id": "string (auto-generated)",
  "userId": "string",
  "programId": "string (nullable -- standalone sessions have no program)",
  "date": "Timestamp",
  "status": "string (enum: planned | completed | skipped)",
  "focus": "string (e.g. 'Upper Body Strength')",
  "exerciseBlocks": [
    {
      "exerciseId": "string",
      "order": "number",
      "sets": "number (planned)",
      "reps": "number (planned, nullable)",
      "duration": "number (planned seconds, nullable)",
      "restSeconds": "number (planned)",
      "weight": "number (planned kg, nullable)",
      "completedSets": "number (actual, nullable until completed)",
      "completedReps": "number (actual, nullable until completed)",
      "actualWeight": "number (actual kg, nullable)",
      "actualDuration": "number (actual seconds, nullable)",
      "rpe": "number (1-10, rate of perceived exertion, nullable)",
      "notes": "string (nullable)"
    }
  ],
  "plannedDuration": "number (minutes)",
  "actualDuration": "number (minutes, nullable until completed)",
  "notes": "string (nullable)",
  "meta": {
    "createdAt": "Timestamp (server)",
    "updatedAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Security rules:** Owner read/write only (`userId == request.auth.uid`).

**Indexes:**
- `userId ASC, date DESC` -- list user's sessions chronologically (main query)
- `userId ASC, status ASC, date DESC` -- filter by status
- `userId ASC, programId ASC, date DESC` -- sessions within a program

---

### assessments/{assessmentId}

Movement assessments. Three types:
- **initial**: Guided questionnaire + optional video upload. Done once at onboarding.
- **weekly_pulse**: Quick 5-question check-in (energy, soreness, sleep, motivation, pain).
- **full_reassessment**: Complete re-evaluation, done every 4-8 weeks.

```json
{
  "id": "string (auto-generated)",
  "userId": "string",
  "date": "Timestamp",
  "type": "string (enum: initial | weekly_pulse | full_reassessment)",
  "responses": {
    "question_id_1": "string or number (answer value)",
    "question_id_2": "string or number",
    "energy_level": "number (1-5, weekly pulse)",
    "soreness_level": "number (1-5, weekly pulse)",
    "sleep_quality": "number (1-5, weekly pulse)",
    "motivation": "number (1-5, weekly pulse)",
    "pain_areas": ["string (body region, weekly pulse)"]
  },
  "videoUrls": ["string (Storage URLs, nullable -- initial + full only)"],
  "compensationsFound": ["string (e.g. 'knee_valgus_squat', 'hip_shift_hinge')"],
  "bodyMapPainPoints": [
    {
      "region": "string (e.g. 'left_knee', 'lower_back')",
      "severity": "number (1-5)",
      "type": "string (enum: sharp | dull | ache | tingling)"
    }
  ],
  "overallScore": "number (0-100, nullable -- calculated by AI in Phase 2)",
  "recommendedProgramId": "string (nullable -- set after program generation)",
  "meta": {
    "createdAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Security rules:** Owner read/write only. `overallScore` and `recommendedProgramId`
may be written by Cloud Functions (Admin SDK bypasses rules).

**Indexes:**
- `userId ASC, date DESC` -- list user's assessments
- `userId ASC, type ASC, date DESC` -- filter by assessment type

---

### sleepLogs/{sleepLogId}

Manual sleep tracking. One entry per night.

```json
{
  "id": "string (auto-generated)",
  "userId": "string",
  "date": "Timestamp (the date this sleep log is for, normalized to midnight)",
  "bedTime": "Timestamp (when user went to bed)",
  "wakeTime": "Timestamp (when user woke up)",
  "qualityRating": "number (1-5, where 1=terrible, 5=excellent)",
  "totalHours": "number (calculated: wakeTime - bedTime in hours, rounded to 1 decimal)",
  "notes": "string (nullable, e.g. 'Woke up twice', 'Took melatonin')",
  "meta": {
    "createdAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Security rules:** Owner read/write only.

**Indexes:**
- `userId ASC, date DESC` -- list user's sleep logs chronologically (main query)

---

### progressionRules/{userId}

Per-user configuration for auto-progression logic. One document per user.
Document ID equals the user's Firebase UID.

```json
{
  "userId": "string (same as document ID)",
  "completionsRequired": "number (default: 3 -- how many times an exercise must be completed at current level before progressing)",
  "sleepQualityThreshold": "number (default: 3 -- minimum average sleep quality over last 7 days to allow progression)",
  "weeklyPulseThreshold": "number (default: 3 -- minimum weekly pulse score to allow progression)",
  "autoProgressionEnabled": "boolean (default: true)",
  "meta": {
    "updatedAt": "Timestamp (server)"
  },
  "_schemaVersion": 1
}
```

**Auto-progression logic (Cloud Function):**
1. After a session is completed, check each exercise block
2. For each exercise, count consecutive completions at the current weight/reps
3. If `completionsRequired` is met AND average sleep quality >= `sleepQualityThreshold`
   AND latest weekly pulse >= `weeklyPulseThreshold`:
   - Suggest progression (increase weight, reps, or move to harder variation)
4. If weekly pulse < threshold: suggest regression or deload week

**Security rules:** Owner read/write only.

---

## Collection Relationship Diagram

```
users/{userId}
  │
  ├── programs/{programId}              1:N  user has many programs
  │       │
  │       └── sessions/{sessionId}      1:N  program has many sessions
  │               (also linked to user directly)
  │
  ├── assessments/{assessmentId}        1:N  user has many assessments
  │
  ├── sleepLogs/{sleepLogId}            1:N  user has many sleep logs
  │
  └── progressionRules/{userId}         1:1  one config per user

exercises/{exerciseId}                  standalone collection
  │
  ├── progressionIds ──────► exercises  self-referential (harder variations)
  └── regressionIds ───────► exercises  self-referential (easier variations)

sessions.exerciseBlocks[].exerciseId ──► exercises/{exerciseId}
programs.weekTemplate.*.exerciseBlocks[].exerciseId ──► exercises/{exerciseId}
assessments.recommendedProgramId ──────► programs/{programId}
```

---

## Offline Strategy

| Collection | Offline Write | Offline Read | Notes |
|---|---|---|---|
| users | Yes (profile updates) | Cached on first load | Profile edits sync when online |
| exercises | No (seed data read-only) | Permanently cached after first load | Built-in exercises never change mid-session |
| programs | Yes (create/edit) | Cached | Program creation queues offline |
| sessions | Yes (complete/skip) | Cached on first load | Critical: gym connectivity is poor |
| assessments | Yes (weekly pulse) | Cached | Initial + full assessments need connectivity (video upload) |
| sleepLogs | Yes | Cached | Users log sleep at home (usually online) but queue if not |
| progressionRules | Yes | Cached | Rarely changes |

Firestore offline persistence is enabled by default in the Flutter SDK:
- Writes are queued locally and synced when connectivity returns
- Reads serve from cache when offline, from server when online
- Use `source: Source.cache` to force cache read for seed data after first load

---

## Pagination

Use cursor-based pagination for collections that grow unbounded:

```dart
// Sessions list -- paginated
Query query = _db.collection('sessions')
    .where('userId', isEqualTo: userId)
    .orderBy('date', descending: true)
    .limit(20);

// Next page
query = query.startAfterDocument(lastDocument);
```

**Pagination applies to:**
- sessions (grows with every training day)
- sleepLogs (grows daily)
- assessments (grows weekly at minimum)

**No pagination needed for:**
- exercises (seed data, bounded size ~200-500)
- programs (user creates few, typically 1-5 active history)
- progressionRules (one document per user)

---

## Schema Versioning

All documents include a `_schemaVersion` field. When the schema evolves:

1. Increment `_schemaVersion` in new documents
2. Write a migration script in `backend/functions/scripts/`
3. Run migration against production before deploying code that expects the new schema
4. Keep old field names readable during transition (read both, write new only)

---

## Seed Data

Seed data includes the built-in exercise library. Seeded by Cloud Functions (idempotent):

```bash
# Seed against emulator
cd backend/functions && npm run seed

# Seed against production (first deploy only)
cd backend/functions && npm run seed:prod
```

Seed data files:
```
backend/functions/seeds/
├── exercises.json          # built-in exercise library
└── exercise_progressions.json  # progression/regression relationships
```

The seed script checks for existing documents before writing (idempotent).
