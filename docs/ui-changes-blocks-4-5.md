# UI Changes — Blocks 4 & 5

Use this to manually verify the new screens on device/emulator.

---

## Block 4 — Assessment System

### Routes
- `/assessment` — Initial Assessment Flow (full-screen, outside the shell/bottom nav)
- `/assessment/history` — Assessment History Page

### InitialAssessmentFlow (`/assessment`)

Multi-step questionnaire that detects movement compensations.

**Steps to verify:**
1. Open by navigating to `/assessment` (or trigger from anywhere in the app that calls `context.go(Routes.assessment)`)
2. **Step 0 — Intro:** See title "Movement Assessment", subtitle "Let's understand your movement", a "Start" button, and a brief description
3. **Step 1 — Occupation:** Linear progress bar at top (14%), three choice chips: "Desk Job", "Physically Active", "Mixed"
4. **Step 2 — Sitting Hours:** Four chips: "< 2 hours", "2–4 hours", "4–6 hours", "> 6 hours"
5. **Step 3 — Pain Areas:** Toggle chips for pain areas (neck, lower back, knees, ankles, shoulders, hips) — can select multiple
6. **Step 4 — Running:** "Yes" / "No" chips
7. **Step 5 — Processing:** Full-screen rotating animation (auto-advances after ~1.8s)
8. **Step 6 — Results:** Shows overall score (ring/percentage), detected compensation pattern tiles, two CTAs:
   - "Build My Program" → navigates to `/programs/new?fromAssessment=<id>`
   - "View My Program Later" → pops back

Each step has a "Back" button (except Intro). Progress bar animates forward/backward.

### AssessmentHistoryPage (`/assessment/history`)

- Pull to refresh supported
- Empty state when no assessments
- Shows assessment cards with: date, "Latest" badge on most recent, score colored green (>7)/orange (>4)/red (≤4), pattern chips

### WeeklyPulseDialog

Triggered by calling `showWeeklyPulseDialog(context)` from anywhere.

- Modal dialog with 4 sliders (1–5): Energy, Soreness, Motivation, Sleep Quality
- Each slider has emoji labels at the ends
- "Save" button calls the provider, shows a checkmark on success, auto-dismisses after 0.8s

---

## Block 5 — Programs

### Routes
- `/programs` — Program Detail Page (inside the shell — accessible via bottom nav or direct nav)
- `/programs/new` — Program Builder Page (full-screen, outside shell)
- `/programs/new?fromAssessment=<id>` — Program Builder pre-filled from assessment

### ProgramDetailPage (`/programs`)

**No active program state:**
- Shows a centered icon (fitness_center), "No active program" title, and a description suggesting to take the assessment

**With active program:**
- Gradient header card showing: program name (bold), goal text, "X weeks" badge, "X days/week" badge
- "Weekly Schedule" section with `WeekTemplateEditor`:
  - Row of 7 animated circle chips (M T W T F S S) — filled color = training day, muted = rest day
  - Cards below for each training day showing: day letter, focus name, exercise count
- "Deactivate Program" outlined button at bottom (red, with stop icon)
- Tapping Deactivate shows a confirmation dialog

### ProgramBuilderPage (`/programs/new`)

- AppBar with "Build Program" title
- Form fields:
  - "Program Name" text field (key: `program_name_field`)
  - "Goal" multi-line text field (key: `program_goal_field`)
  - "Duration" chip row: 4w, 6w, **8w** (default), 12w, 16w
- "Weekly Schedule" section with `WeekTemplateEditor` in edit mode (tap day circles to toggle rest/training)
- "Save Program" filled button (key: `save_program_button`) — shows loading spinner while saving

**When opened from assessment (`?fromAssessment=<id>`):**
- Auto-fills name, goal, duration, and week template from `GenerateProgramFromAssessment`
- Generated program: Mon/Wed/Fri training days, exercises split across the 3 days from detected compensations
- Default: 8-week program, 3 sets × 10 reps per exercise

---

## Navigation wiring still needed (placeholder pages)

The bottom nav currently has Home/Calendar/Exercises/Progress/Profile tabs.
`/programs` is accessible via direct navigation (`context.go(Routes.programs)`) from:
- The assessment flow "Build My Program" CTA (goes to `/programs/new`)
- Any future home screen widget

To test program pages manually, navigate to:
```dart
context.go(Routes.programs);          // detail page
context.go(Routes.programBuilder);    // builder page
context.go('${Routes.programBuilder}?fromAssessment=test'); // with mock param
```
