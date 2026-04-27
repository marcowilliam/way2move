#!/usr/bin/env python3
"""
Parse Marco's Notion export -> src/lib/seeds/notionWorkouts.ts.

Usage:
  python3 scripts/import-notion-workouts.py <notion-export-base-dir> [out.ts]

Where <notion-export-base-dir> is the path to the unzipped Notion export's
"Private & Shared" folder containing:
  - "Workout database <hash>_all.csv"
  - "Workout database/" subfolder with per-workout subfolders + their
    "Untitled <hash>.csv" exercise files

If no output path is given, writes to src/lib/seeds/notionWorkouts.ts
relative to this script.
"""
import csv
import os
import re
import sys
import json
from pathlib import Path

# Load per-exercise educational content (intent / joints / compensations /
# muscles), keyed by slug. Edits made to educational_content.py persist
# across re-runs of this import script.
sys.path.insert(0, str(Path(__file__).resolve().parent))
try:
    from educational_content import EDUCATIONAL_CONTENT
except ImportError:
    EDUCATIONAL_CONTENT = {}

if len(sys.argv) < 2:
    print(__doc__, file=sys.stderr)
    sys.exit(1)

BASE = Path(sys.argv[1])
OUT_FILE = Path(sys.argv[2]) if len(sys.argv) >= 3 else (
    Path(__file__).resolve().parent.parent / "src/lib/seeds/notionWorkouts.ts"
)

WORKOUT_DB = next(BASE.glob("Workout database *_all.csv"), None)
WORKOUT_DIR = BASE / "Workout database"

if not WORKOUT_DB or not WORKOUT_DB.exists():
    sys.exit(f"Could not find 'Workout database *_all.csv' in {BASE}")
if not WORKOUT_DIR.is_dir():
    sys.exit(f"Could not find 'Workout database/' subfolder in {BASE}")


def slug(name):
    s = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")[:60]
    return s or "unnamed"


def strip_link(t):
    return re.sub(r"\s*\(https?://[^)]+\)", "", t).strip()


def strip_workout_ref(t):
    return re.sub(r"\s*\([^)]+\.md\)\s*$", "", t).strip()


def parse_exercises_field(s):
    return [strip_link(p) for p in s.split(", ") if p.strip()] if s else []


PHASE_MAP = {
    "warm-up": "warmUp", "warm up": "warmUp", "warmup": "warmUp",
    "main": "main",
    "cool-down": "coolDown", "cool down": "coolDown", "cooldown": "coolDown",
}
LEVEL_MAP = {
    "access": "foundation", "foundation": "foundation",
    "developmental": "developmental", "development": "developmental",
    "advanced": "advanced", "mastery": "advanced",
}


def map_phase(s):
    return PHASE_MAP.get(s.strip().lower()) if s else None


def map_level(s):
    return LEVEL_MAP.get(s.strip().lower()) if s else None


def parse_cues(s):
    if not s:
        return []
    out = []
    for ln in s.split("\n"):
        ln = re.sub(r"^[•\-\*]\s*", "", ln.strip()).strip()
        if ln:
            out.append(ln)
    return out


def parse_int_or_none(s):
    if not s:
        return None
    try:
        return int(s.strip())
    except Exception:
        return None


def normalize_for_match(s):
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def find_subfolder_csv(workout_name):
    norm_target = normalize_for_match(workout_name)
    for sub in WORKOUT_DIR.iterdir():
        if not sub.is_dir():
            continue
        norm_sub = normalize_for_match(sub.name)
        if norm_sub.startswith(norm_target[:20]) or norm_target.startswith(norm_sub[:20]):
            csvs = sorted(sub.glob("*.csv"), key=lambda p: p.stat().st_size, reverse=True)
            for c in csvs:
                with c.open(encoding="utf-8-sig") as f:
                    head = f.readline()
                    if "Exercise" in head and "Phase" in head:
                        return c
    return None


def parse_block_csv(csv_path, expected_workout_norm=None):
    blocks = []
    with csv_path.open(encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            ex_name = strip_link(row.get("Exercise", "") or "")
            if not ex_name:
                continue
            if expected_workout_norm:
                wk = strip_workout_ref(row.get("Workout", "") or "")
                if normalize_for_match(wk)[:20] != expected_workout_norm[:20]:
                    continue
            included_raw = (row.get("Current Included", "") or "").strip().lower()
            currently_included = included_raw not in ("no", "false", "0")
            sl = slug(ex_name)
            edu = EDUCATIONAL_CONTENT.get(sl, {})
            blocks.append({
                "exerciseId": sl,
                "exerciseName": ex_name,
                "category": (row.get("Category", "") or "").strip() or None,
                "directions": (row.get("Directions", "") or "").strip() or None,
                "cuesOverride": parse_cues(row.get("Cues", "") or ""),
                "phase": map_phase(row.get("Phase", "") or ""),
                "level": map_level(row.get("Level", "") or ""),
                "order": parse_int_or_none(row.get("Order", "")),
                "currentlyIncluded": currently_included,
                "intent": edu.get("intent"),
                "joints": edu.get("joints", []),
                "compensations": edu.get("compensations", []),
                "muscles": edu.get("muscles", []),
            })
    blocks.sort(key=lambda b: (b.get("order") or 9999))
    return blocks


def main():
    workouts_out = []
    with WORKOUT_DB.open(encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            name = (row.get("Name", "") or "").strip()
            if not name:
                continue
            intent = (row.get("Intent", "") or "").strip() or None
            plane = (row.get("Primary Plane", "") or "").strip() or None
            joints_raw = (row.get("Joints movements", "") or "").strip()
            joints = [j.strip() for j in joints_raw.split(",") if j.strip()] if joints_raw else []
            kind_raw = (row.get("type", "") or "").strip().lower() or None

            csv_path = find_subfolder_csv(name)
            blocks = []
            source_note = ""
            if csv_path:
                expected = normalize_for_match(name)
                blocks = parse_block_csv(csv_path, expected_workout_norm=expected)
                source_note = f"per-folder: {csv_path.name}"

            if not blocks:
                exs = parse_exercises_field(row.get("exercises", "") or "")
                for i, ex_name in enumerate(exs, 1):
                    sl = slug(ex_name)
                    edu = EDUCATIONAL_CONTENT.get(sl, {})
                    blocks.append({
                        "exerciseId": sl,
                        "exerciseName": ex_name,
                        "order": i,
                        "currentlyIncluded": True,
                        "intent": edu.get("intent"),
                        "joints": edu.get("joints", []),
                        "compensations": edu.get("compensations", []),
                        "muscles": edu.get("muscles", []),
                    })
                source_note = (source_note + " + name-only fallback") if source_note else "name-only (no CSV)"

            if not blocks:
                print(f"  SKIP (empty): {name}", file=sys.stderr)
                continue

            emoji_m = re.match(r"^([\U0001F300-\U0001FAFF✀-➿])\s*", name)
            emoji = emoji_m.group(1) if emoji_m else None
            display_name = re.sub(r"^[\U0001F300-\U0001FAFF✀-➿]\s*", "", name).strip()

            workouts_out.append({
                "id": "notion-" + slug(name),
                "name": display_name or name,
                "emoji": emoji,
                "intent": intent,
                "primaryPlane": plane,
                "jointsMovements": joints,
                "kind": kind_raw,
                "source": "notion-export",
                "notionPath": name,
                "blocks": blocks,
            })
            print(f"  {emoji or ' '} {display_name[:50]:50}  {len(blocks):3d} blocks  ({source_note})", file=sys.stderr)

    out = [
        "// AUTO-GENERATED from Marco's Notion export.",
        "// Regenerate with: python3 scripts/import-notion-workouts.py <notion-export-base-dir>",
        "// Do NOT edit by hand — re-run the import script instead.",
        "",
        "import type { WorkoutTemplate } from '../workoutTemplates';",
        "",
        "/* eslint-disable */",
        "export const notionWorkouts: WorkoutTemplate[] = " + json.dumps(workouts_out, indent=2, ensure_ascii=False) + ";",
        "",
    ]
    OUT_FILE.write_text("\n".join(out), encoding="utf-8")
    print(f"\nWrote {len(workouts_out)} workouts -> {OUT_FILE}", file=sys.stderr)


main()
