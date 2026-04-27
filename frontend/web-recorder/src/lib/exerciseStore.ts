// localStorage-backed exercise library. Seed set ships in-code; "user-created"
// exercises are the EVALUATE BUCKET — they stay separate from canonical
// until an AI pass (future) promotes or merges them.
// See memory: evaluate_exercises_pattern.md

import type { Exercise } from "./types";
import { newId } from "./sessionStore";

const STORE_KEY = "way2train.exercises.v1";
const SEED_VERSION_KEY = "way2train.exercises.seedVersion";
const CURRENT_SEED_VERSION = 1;

// Canonical seed library. Kept small on purpose — the user will build up the
// real library through evaluation + AI promotion. These are just enough for
// someone to start a session without typing everything from scratch.
const SEED_EXERCISES: Omit<Exercise, "id" | "createdAt">[] = [
  { name: "Back Squat",       defaultEffortKind: "reps", defaultReps: 8,  defaultSets: 5, defaultRestSeconds: 90, source: "seed" },
  { name: "Front Squat",      defaultEffortKind: "reps", defaultReps: 6,  defaultSets: 4, defaultRestSeconds: 90, source: "seed" },
  { name: "Romanian Deadlift",defaultEffortKind: "reps", defaultReps: 10, defaultSets: 4, defaultRestSeconds: 90, source: "seed" },
  { name: "Conventional Deadlift", defaultEffortKind: "reps", defaultReps: 5, defaultSets: 5, defaultRestSeconds: 120, source: "seed" },
  { name: "Walking Lunge",    defaultEffortKind: "reps", defaultReps: 12, defaultSets: 3, defaultRestSeconds: 60, source: "seed" },
  { name: "Bulgarian Split Squat", defaultEffortKind: "reps", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 60, source: "seed" },
  { name: "Hip Thrust",       defaultEffortKind: "reps", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 75, source: "seed" },
  { name: "Bench Press",      defaultEffortKind: "reps", defaultReps: 8,  defaultSets: 4, defaultRestSeconds: 90, source: "seed" },
  { name: "Overhead Press",   defaultEffortKind: "reps", defaultReps: 6,  defaultSets: 4, defaultRestSeconds: 90, source: "seed" },
  { name: "Pull-up",          defaultEffortKind: "reps", defaultReps: 6,  defaultSets: 4, defaultRestSeconds: 90, source: "seed" },
  { name: "Bent-over Row",    defaultEffortKind: "reps", defaultReps: 8,  defaultSets: 4, defaultRestSeconds: 75, source: "seed" },
  { name: "Front Plank",      defaultEffortKind: "time", defaultSeconds: 30, defaultSets: 3, defaultRestSeconds: 60, source: "seed" },
  { name: "Side Plank",       defaultEffortKind: "time", defaultSeconds: 30, defaultSets: 2, defaultRestSeconds: 45, source: "seed" },
  { name: "Dead Bug",         defaultEffortKind: "reps", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 45, source: "seed" },
  { name: "Bird Dog",         defaultEffortKind: "reps", defaultReps: 10, defaultSets: 3, defaultRestSeconds: 45, source: "seed" },
  { name: "Pallof Press",     defaultEffortKind: "reps", defaultReps: 12, defaultSets: 3, defaultRestSeconds: 45, source: "seed" },
  { name: "Wall Sit",         defaultEffortKind: "time", defaultSeconds: 45, defaultSets: 3, defaultRestSeconds: 60, source: "seed" },
  { name: "Hollow Hold",      defaultEffortKind: "time", defaultSeconds: 30, defaultSets: 3, defaultRestSeconds: 45, source: "seed" },
];

export const loadExercises = (): Exercise[] => {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    if (raw) return JSON.parse(raw) as Exercise[];
  } catch {}
  return [];
};

export const saveExercises = (list: Exercise[]): void => {
  localStorage.setItem(STORE_KEY, JSON.stringify(list));
};

// Idempotent: ensures the seed library is present on first boot (or after
// bumping CURRENT_SEED_VERSION). Never deletes user-created entries.
export const ensureSeeded = (): Exercise[] => {
  const stored = loadExercises();
  const seedVersion = Number(localStorage.getItem(SEED_VERSION_KEY) ?? "0");
  if (seedVersion >= CURRENT_SEED_VERSION && stored.length > 0) return stored;

  const existingSeedNames = new Set(
    stored.filter((e) => e.source === "seed").map((e) => e.name.toLowerCase()),
  );
  const now = new Date().toISOString();
  const additions: Exercise[] = SEED_EXERCISES
    .filter((e) => !existingSeedNames.has(e.name.toLowerCase()))
    .map((e) => ({ ...e, id: newId(), createdAt: now }));

  const merged = [...stored, ...additions];
  saveExercises(merged);
  localStorage.setItem(SEED_VERSION_KEY, String(CURRENT_SEED_VERSION));
  return merged;
};

export const upsertExercise = (exercise: Exercise): Exercise => {
  const list = loadExercises();
  const idx = list.findIndex((e) => e.id === exercise.id);
  if (idx >= 0) list[idx] = exercise;
  else list.push(exercise);
  saveExercises(list);
  return exercise;
};

// Create a new user-entered exercise. Lands in the evaluate bucket with
// evaluationStatus: "pending".
export const createEvaluatedExercise = (
  partial: Omit<Exercise, "id" | "source" | "createdAt" | "evaluationStatus">,
): Exercise => {
  const ex: Exercise = {
    ...partial,
    id: newId(),
    source: "user-created",
    evaluationStatus: "pending",
    createdAt: new Date().toISOString(),
  };
  return upsertExercise(ex);
};

export const canonicalExercises = (list: Exercise[]): Exercise[] =>
  list.filter((e) => e.source === "seed" || e.source === "promoted");

export const evaluateBucket = (list: Exercise[]): Exercise[] =>
  list.filter((e) => e.source === "user-created");

export const deleteExercise = (id: string): void => {
  const list = loadExercises();
  saveExercises(list.filter((e) => e.id !== id));
};
