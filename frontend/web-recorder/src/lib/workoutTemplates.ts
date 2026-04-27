// Workout template library — shape mirrors what the parser emits, with the
// runtime fields (id, recordings, status, etc.) deliberately absent. Use
// instantiateSession() to produce a ready-to-run Session from a template.

import type {
  ExerciseBlock,
  ExerciseLevel,
  ExercisePhase,
  Session,
  SessionStatus,
  Source,
  WorkoutKind,
} from "./types";
import { newId } from "./sessionStore";

// Subset of ExerciseBlock the parser populates — runtime fields (id,
// actualSets, plannedSets/Reps numerical, etc.) get filled in at instantiation.
export interface TemplateBlock {
  exerciseId: string;
  exerciseName: string;
  category?: string | null;
  directions?: string | null;
  cuesOverride?: string[];
  phase?: ExercisePhase | null;
  level?: ExerciseLevel | null;
  order?: number | null;
  currentlyIncluded?: boolean;
}

export interface WorkoutTemplate {
  id: string;
  name: string;
  emoji?: string | null;
  intent?: string | null;
  primaryPlane?: string | null;
  jointsMovements?: string[];
  kind?: string | null; // free-form from Notion's "type" column
  source: "notion-export" | "user-paste" | "seed";
  notionPath?: string | null;
  blocks: TemplateBlock[];
}

const USER_TEMPLATES_KEY = "way2train.workoutTemplates.user.v1";

// User-pasted templates live in localStorage; baked-in seeds (Notion + Ground
// Up) get merged in at read time.
export const loadUserTemplates = (): WorkoutTemplate[] => {
  try {
    const raw = localStorage.getItem(USER_TEMPLATES_KEY);
    return raw ? (JSON.parse(raw) as WorkoutTemplate[]) : [];
  } catch {
    return [];
  }
};

export const saveUserTemplate = (t: WorkoutTemplate): void => {
  const all = loadUserTemplates();
  const idx = all.findIndex((x) => x.id === t.id);
  if (idx >= 0) all[idx] = t;
  else all.push(t);
  localStorage.setItem(USER_TEMPLATES_KEY, JSON.stringify(all));
};

export const deleteUserTemplate = (id: string): void => {
  const all = loadUserTemplates().filter((t) => t.id !== id);
  localStorage.setItem(USER_TEMPLATES_KEY, JSON.stringify(all));
};

// Best-effort "is this a movement workout I should color sage" tag — the
// recorder uses sage = body-listening, terracotta = strength action.
export const isPhysioStyle = (t: WorkoutTemplate): boolean => {
  const hay = `${t.name} ${t.intent ?? ""} ${t.kind ?? ""}`.toLowerCase();
  return /physio|mobility|movement|posterior|anterior|flexion|extension|rotation|locomotion|frontal|sagit|stab|relaxation|capsule|breath/i.test(
    hay,
  );
};

// Default planned set/rep guesses when the directions string is too freeform
// to parse cleanly. These can be edited per-block in the UI.
const DEFAULT_PLANNED_SETS = 1;
const DEFAULT_REST_SECONDS = 30;

// Try to peel a "N sets" hint out of the directions string; otherwise fall back.
const guessSetCount = (directions: string | null | undefined): number => {
  if (!directions) return DEFAULT_PLANNED_SETS;
  // "2 sets", "1-2 sets", "2 x", "3×", "2 x 10" — grab the bigger of the range
  const m = directions.match(/(\d+)\s*[-–]\s*(\d+)\s*(?:sets?|x|×)/i);
  if (m) return Math.max(parseInt(m[1], 10), parseInt(m[2], 10));
  const single = directions.match(/(\d+)\s*(?:sets?|x|×)/i);
  if (single) return Math.max(1, parseInt(single[1], 10));
  return DEFAULT_PLANNED_SETS;
};

// Templates → Session. We DON'T pre-fill actualSets (mirrors the Ground Up
// fix from earlier) so the session opens 0% complete.
export const instantiateSession = (
  template: WorkoutTemplate,
  todayISO: string,
  userId: string = "marco",
): Session => {
  const blocks: ExerciseBlock[] = template.blocks.map((tb, i) => ({
    id: newId(),
    exerciseId: tb.exerciseId,
    exerciseName: tb.exerciseName,
    plannedSets: guessSetCount(tb.directions ?? undefined),
    plannedReps: 0,
    restSeconds: DEFAULT_REST_SECONDS,
    actualSets: [],
    phase: tb.phase ?? undefined,
    level: tb.level ?? undefined,
    category: tb.category ?? undefined,
    directions: tb.directions ?? undefined,
    cuesOverride: tb.cuesOverride && tb.cuesOverride.length > 0 ? tb.cuesOverride : undefined,
    currentlyIncluded: tb.currentlyIncluded !== false,
    order: tb.order ?? i + 1,
  }));

  const status: SessionStatus = "planned";
  const source: Source = "in-app-recorder";

  // Map Notion `kind` strings to our enum, default to themed.
  let kind: WorkoutKind = "themed";
  const k = (template.kind ?? "").toLowerCase();
  if (template.id.includes("ground-up")) kind = "fromGroundUp";
  else if (k.includes("snack") || /snack/i.test(template.name)) kind = "snack";
  else if (/bodybuilding/i.test(template.name)) kind = "bodybuilding";
  else if (/day [a-e]/i.test(template.name)) kind = "abcde";

  return {
    id: newId(),
    userId,
    type: "training",
    focus: template.name,
    date: todayISO,
    status,
    exerciseBlocks: blocks,
    recordings: [],
    source,
    idempotencyKey: `${template.id}:${userId}:${todayISO}`,
    workoutId: template.id,
    kind,
    slot: "flexible",
  };
};
