# Handoff — Web-recorder Training-Week Wiring (2026-04-27, evening)

**Branch:** `feature/web-recorder-training-week`
**Worktree:** `/projects/my-projects/personal/way2move/feature/web-recorder-training-week`
**Status:** Tonight-runnable. Marco can do the Ground Up routine on the web-recorder voice-coached. No Firestore, no cameras required.

This complements the mobile MVP handoff at `handoff-mvp-2026-04-27.md`. Read that first for context on the training-week organizer feature itself.

---

## How to run it

```bash
cd /projects/my-projects/personal/way2move/feature/web-recorder-training-week/frontend/web-recorder
npm run dev
```

Open Chrome at `http://localhost:5193`.

1. Home shows a Sage **"Daily routine — From the Ground Up"** card above the today hero.
2. Tap **"Start routine"** → lands in ActiveSession with the 11 physio exercises.
3. Each block shows: phase pill (Main) + level chip (Foundation) + the real exercise name (e.g. "Foam Roller Bridge — Double Legged") + the directions string + a Sage **Cues** card with the bullet list.
4. At end-of-session (or via Finish in the topbar), the finalize panel includes a new Sage **Sensation** card: chip inputs for good/struggling areas, 1–5 pips, notes textarea.
5. Save → returns to home. Re-tapping "Daily routine" the same day re-opens the session (idempotent via `idempotencyKey: ground-up:marco:<date>`).

The Daily routine card is idempotent: only one ground-up session per day, no matter how many times you tap.

---

## What was built (this commit)

| File | What |
|---|---|
| `src/lib/types.ts` | Optional `phase`, `level`, `category`, `directions`, `cuesOverride`, `currentlyIncluded`, `order` on `ExerciseBlock`; `workoutId`, `kind`, `slot`, `place`, `durationCategory`, `sensationFeedback` on `Session`; new `SensationFeedback` interface; supporting enums (`ExercisePhase`, `ExerciseLevel`, `WorkoutKind`, `SessionSlot`, `SessionPlace`, `DurationCategory`). All optional → forward-compat with old localStorage blobs. |
| `src/lib/seeds/groundUp.ts` | `buildGroundUpSession(todayISO, userId)` returns a fresh Session with all 11 ground-up blocks. Translated 1:1 from the Flutter seed at `frontend/mobile/lib/features/protocols/domain/usecases/seed_ground_up_for_user.dart`. |
| `src/routes/SessionsList.svelte` | Sage "Daily routine" card with idempotent start/continue/done states, derived from `todaySessions`. |
| `src/routes/ActiveSession.svelte` | Hero strip now renders phase pill, level chip, category title, directions subtitle. New Sage **Cues** card between progress strip and hero (only when `block.cuesOverride` is non-empty). New Sage **Sensation** section in the finalize panel with chip inputs (good/struggling), 1–5 score pips, notes textarea. State hooks: `sensationGood`, `sensationStruggling`, `sensationScore`, `sensationNotes`. Pre-fills from `session.sensationFeedback` on re-open. Saves into `session.sensationFeedback` on `saveFinalize()`. |

Per-exercise summary in finalize and TTS prompts also now prefer `category` over `exerciseName`.

`npm run build` succeeds. `npm run check` reports only pre-existing errors (16 errors / 2 warnings, all from before this commit — `.ts` import paths and `Step[]` calls in ActiveSession; not introduced here).

---

## What's NOT done (deferred — pick up in a follow-up)

| Phase | Missing |
|---|---|
| **Tests** | No unit tests for `buildGroundUpSession`, no widget tests for the Sensation chips/score/save flow, no E2E for the Daily Routine card. Pre-existing test infra in this repo is light — set up Vitest + a Svelte testing layer first if going there. |
| **Builder.svelte** | The custom-workout builder doesn't yet expose the new fields (`phase` / `level` / `category` / `directions` / `cuesOverride`). User-built workouts can only carry name + sets/reps for now. |
| **Library.svelte** | Same — no UI to view/edit the new fields on the canonical exercise list. |
| **Firestore wiring** | The recorder still uses localStorage. To consume the same data the mobile app writes, replace `sessionStore.ts` with a Firestore-backed module + add Firebase Auth + emulator wiring. Big lift, separate phase. |
| **Camera bug** | The 2026-04-23 black-camera issue is unchanged. Cameras stay optional ("guided training only" path) so the routine works without them. See `frontend/web-recorder/HANDOFF.md`. |
| **Cloud Function seed** | Marco's mobile MVP seeds via in-app FAB; the Notion-CSV import script (mobile handoff Phase 1F-full) would also feed the recorder once Firestore is wired. |
| **Workout import in Settings** | The mobile-handoff Phase 4 mentioned a paste-and-import textarea in `Settings.svelte`. Not built — for now the seed is hardcoded. |
| **Sensation in summary view** | If/when a session detail page is added back to home (currently you land in ActiveSession review for completed sessions), the Sensation block should also show up there read-only. |

---

## Schema notes for whoever picks this up

- `ExerciseBlock.exerciseName` is still required (existing schema constraint). The seed sets `exerciseName = category` so legacy display paths still render the right string. New code should prefer `block.category ?? block.exerciseName`.
- `Session.idempotencyKey` for ground-up sessions: `ground-up:<userId>:<YYYY-MM-DD>`. If you switch to Firestore later, use this exact key for the query-before-write dedupe pattern (per `.claude/rules/firebase_backend/assistant_ingest.md`).
- `Source` enum already includes `"in-app-recorder"` from the recorder scaffold. Ground-up sessions stamp this — keep it that way for provenance.
- The Sensation card uses a `SensationFeedback` shape (`goodAreas[]`, `strugglingAreas[]`, `score 1-5`, `notes?`, `capturedAt?`) that mirrors the Flutter mobile SensationFeedback exactly. Don't drift — the cross-app assistant will consume both.

---

## How to merge

When ready, fast-forward this branch into `main` (no merge commit needed — it's a linear descendant of `e03117f`):

```bash
cd /projects/my-projects/personal/way2move/main
git merge --ff-only feature/web-recorder-training-week
git push origin main
```

Reminder per `~/.claude/rules/commit-hygiene.md`: **no `Co-Authored-By: Claude` trailer** on any commit. The commit on this branch already follows that rule.
