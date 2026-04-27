/// Enums shared across Workout, Session, WeekPlan, and Protocol entities.
///
/// Kept in one file because they reference each other and proliferating
/// per-feature enum files makes imports tedious for cross-feature widgets
/// (Workout Library renders by `kind`, Session View renders by `phase`,
/// the Today screen groups by `slot`).
library;

/// What family of training a workout belongs to. Drives library tabs,
/// today-card colour, and what default the planner uses when slotting it.
enum WorkoutKind {
  /// Physio-prescribed daily routine. Pinned every day by a Protocol.
  fromGroundUp,

  /// Gym A/B/C/D/E rotation. One per weekday by default (Mon=A … Fri=E).
  abcde,

  /// Opportunistic 5-15 min micro-session — cranium, pelvic floor, neck,
  /// DNS prone/supine, etc.
  snack,

  /// Bodybuilding / strength-focused gym work — back, legs, chest, etc.
  bodybuilding,

  /// Themed week focus — alignment + awareness, eyes, neck, hamstrings, …
  themed,

  /// Recovery / mobility-only session.
  recovery,

  /// Custom user-created shape that doesn't fit the above.
  custom,
}

/// Where in a workout an exercise lives. Notion's "Phase" column.
enum ExercisePhase {
  warmup,
  main,
  cooldown,
}

/// Notion's "Level" — the progression hierarchy the physio uses.
/// Determines visual hierarchy (Access first, Integration last) and
/// gates auto-progression: a user shouldn't see Strength suggestions
/// until Foundation is owned.
enum ExerciseLevel {
  access,
  foundation,
  strength,
  integration,
  supportSnack,
}

/// Time-of-day bucket for a session. Lets multiple sessions live on the
/// same date without timestamps. `flexible` is "whenever" — used for
/// Protocol-pinned routines that can be done morning OR evening.
enum SessionSlot {
  morning,
  midday,
  afternoon,
  evening,
  flexible,
}

/// Coarse duration bucket. Derived from `plannedDuration` but stored
/// for cheap timeline filtering (find me all snacks this week).
enum DurationCategory {
  /// < 15 min — true snacks (cranium release, neck flow).
  snack,

  /// 15-30 min — short routines (From the Ground Up, light recovery).
  short,

  /// 30-60 min — medium training.
  medium,

  /// 60+ min — full gym sessions.
  long,
}

/// Who prescribed a Protocol.
enum ProtocolKind {
  /// External practitioner (physio, osteopath, chiropractor).
  physio,

  /// Self-prescribed.
  self,

  /// Coach-prescribed (Phase 5+).
  coach,
}

/// Lifecycle of a Protocol.
enum ProtocolStatus {
  active,
  completed,
  abandoned,
}
