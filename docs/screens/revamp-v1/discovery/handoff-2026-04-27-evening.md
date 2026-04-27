# Handoff — Way2Move revamp v1.1: main is clean, Phase B is next

**Date:** 2026-04-27 (evening)
**Branch:** `main` (pushed, clean)
**Working tree:** `/projects/my-projects/personal/way2move/main`
**Picks up from:** `handoff-2026-04-27.md` (same folder)

## Where we left things

`main` is fully merged and pushed. Working tree is clean. The mid-merge state described in `handoff-2026-04-27.md` is resolved — every WIP file in that handoff's "Working tree state" table is now committed.

### What this session committed (last 2 commits)

```
ee7853a feat(web-recorder): scaffold Svelte 5 + Vite sibling for 3-camera training capture
5e97f56 docs(revamp-v1): sync phase A — mark v1.1 work shipped
```

The first one is commit #4 from the previous handoff's table (Phase A docs sync, plus Phase A.3 marker edits the previous session never got to: `Status: ✅ shipped 2026-04-26` markers on C1 / C2 / Phase D in `phases-plan.md`, and a rewritten priority list dropping the now-shipped items). The second is commit #7 (web-recorder scaffold).

Commits #1, #2, #3, #5, #6 from the previous handoff's table were already shipped in the gap between the two handoffs:

```
c846fd0 docs(revamp): add v1.1 phases plan and handoffs              # #4 partial — phases-plan.md + handoff-2026-04-26.md + sonnet-handoff
e33001c refactor(brand): drop "from the ground up" tagline ...       # #5 + #6 combined (branding + splash + sign_up)
1a0033e feat(onboarding): revamp steps 1-5 with shared shell ...     # #3
8e064a0 feat(home): collapse dashboard from 8 to 6 sections ...      # #2
a805cae fix(journal): cache stt service in voice input ...           # #1
```

## What still needs doing

### 1. Phase B — Full Specs (B1–B7)

This is the next dispatchable unit per `phases-plan.md`. Seven independent spec groups, all parallelizable in principle, but the previous handoff explicitly recommended **one worktree at a time** (or a single umbrella agent) to keep voice and structure consistent across the 7 specs and avoid clashes on the shared `docs/screens/revamp-v1/` folder.

| Group | Screens | Folder |
|---|---|---|
| B1 | Auth (Splash · Sign In · Sign Up · Onboarding Welcome) | `docs/screens/revamp-v1/auth/` |
| B2 | Session (Home · Active Session · Session Summary) | `session/` |
| B3 | Exercise (Library · Detail · Program Detail) | `exercise/` |
| B4 | Assessment / AI (Flow · Results · AI Review) | `assessment/` |
| B5 | Body Awareness (Compensation Profile · Goals List · Goal Detail) | `body-awareness/` |
| B6 | Daily Logging (Journal · Nutrition · Sleep) | `daily-logging/` |
| B7 | Profile | `profile/` |

Each group produces a `spec.md` + `test-cases.md`. **DoD requires ≥3 edge cases the spec author had to dig out of the actual code** — paraphrasing `plan.md` is explicitly called out as adding no value. See `phases-plan.md` lines ~51–77 for the full spec.

**How to dispatch:**

```
Agent({
  description: "Phase B umbrella — write all 7 spec groups",
  isolation: "worktree",
  prompt: <see prompt skeleton below>
})
```

Or one-at-a-time worktrees if the umbrella agent is too long-running.

The worktree branches off `main` HEAD which now includes all the C1/C2/D code and the synced docs — exactly what each spec author needs to read.

#### Prompt skeleton for the Phase B agent

> You are writing full specs (`spec.md` + `test-cases.md`) for 7 screen groups in a Flutter app revamp.
>
> Read first:
> - `docs/screens/revamp-v1/discovery/phases-plan.md` — full Phase B spec, lines ~51–77
> - `docs/screens/revamp-v1/discovery/plan.md` — what shipped in revamp v1.0 + v1.1
> - `docs/branding/brand-identity-plan.md` — design tokens
> - The actual production `.dart` files for the screens you're speccing — DoD requires ≥3 edge cases per group dug out of the code, not paraphrased from plan.md
>
> Produce one folder per group: `docs/screens/revamp-v1/<group-folder>/spec.md` + `test-cases.md`. Match the style of existing specs (none exist yet for v1.1 — establish the pattern with B1).
>
> Work sequentially through B1 → B7. Don't fan out — voice consistency matters.

### 2. Phase E — Final QA Sweep (after B is done, or in parallel if user prefers)

`phases-plan.md` Phase E is a one-unit task: full `flutter test` + `flutter analyze` sweep, fix anything that drifted, document what's left. The 747/0 number from the 2026-04-26 handoff should still hold since nothing in `frontend/mobile/` has changed since — but verify before declaring victory.

### 3. Phase G — Deploy

Codemagic iOS staging + Android internal track. The `ios-staging-codemagic` skill at `.claude/skills/ios-staging-codemagic/SKILL.md` covers the iOS side end-to-end. Phase G expects: bump `pubspec.yaml` build number, push, watch Codemagic, smoke-test the TestFlight build.

### 4. Phase F — Calendar v2

Independent of the v1.1 deliverable. Schedule when capacity allows. See `phases-plan.md` Phase F for scope.

## Parallel deliverable: Training Week Organizer

Between this session's first and second pushes, a **separate parallel feature** got merged into `main` from `feature/training-week-organizer`:

```
5f9e773 Merge branch 'feature/training-week-organizer' into main
f5de44c docs(training-week): add handoff for next agent to finish Phases 1D-6
4eb4cd9 feat(domain): add training-week organizer use cases and ISO-week helpers
e9524c4 feat(domain): add training-week organizer entities (Protocol, Workout, WeekPlan)
```

This is **Marco's "From the Ground Up" 6-week physio prescription + ABCDE gym split + Snacks** feature. Domain layer (entities + use cases + unit tests) shipped — Phases 1D → 6 remain. Its own self-contained handoff lives at `docs/screens/training-week-organizer/discovery/handoff-2026-04-27.md` — read that if you're picking up that feature.

**It does not block Phase B.** They touch disjoint folders (`docs/screens/revamp-v1/` vs `frontend/mobile/lib/features/protocols/` etc.). They can run in parallel — Phase B writes specs only, Training Week Organizer continues with data layer + UI.

## Working-tree state at handoff (2026-04-27 evening)

```
git status: clean
git log --oneline -8:
  8c4243d docs(revamp-v1): handoff for next agent — main is clean, Phase B is next
  5f9e773 Merge branch 'feature/training-week-organizer' into main
  f5de44c docs(training-week): add handoff for next agent to finish Phases 1D-6
  ee7853a feat(web-recorder): scaffold Svelte 5 + Vite sibling for 3-camera training capture
  5e97f56 docs(revamp-v1): sync phase A — mark v1.1 work shipped
  f034c6b chore(lint): clear two pre-existing analyze info warnings
  4eb4cd9 feat(domain): add training-week organizer use cases and ISO-week helpers
  e9524c4 feat(domain): add training-week organizer entities (Protocol, Workout, WeekPlan)
origin/main: in sync
```

## Suggested next-step priority

1. **Spawn the Phase B worktree agent** (umbrella, sequential B1→B7) — see prompt skeleton above. ~7 units of work but it's all docs, no code, so it's parallel-safe with anything in `frontend/mobile/`.
2. **Continue Training Week Organizer Phases 1D → 6** in `feature/training-week-organizer` — this is its own track with its own handoff (link above). Independent of the revamp work.
3. **Phase E QA sweep** — can run before B finishes since it doesn't touch the docs folder. Quick (~1 unit). Should ideally happen *after* Training Week Organizer lands so the sweep covers everything.
4. **Phase G deploy** — once E is green, B is at least partially landed, and Training Week Organizer is at a deployable checkpoint.
5. **Phase F calendar v2** — schedule independently.

Total time-to-deploy: ~10 units (B umbrella) + Training Week Organizer remaining phases + 1 unit (E) + Codemagic build runtime.

## Notes for the next agent

- **Working dir vs git worktree:** the actual main worktree is at `/projects/my-projects/personal/way2move/main/`, not `/projects/my-projects/personal/way2move/`. The repo is bare-cloned with two worktrees (`main/` and `feature/`). When spawning new worktrees, branch off `main` HEAD inside `main/`.
- **Commit hygiene:** global rule — no `Co-Authored-By: Claude` trailer on any commit. See `~/.claude/rules/commit-hygiene.md`.
- **Pre-push hook:** Lefthook runs `flutter test` + `flutter analyze` on pre-push. The two commits in this push didn't touch `frontend/mobile/` so the hook either skipped or ran fast — push completed in seconds. Future Phase B work also doesn't touch Flutter, so pre-push will stay quick. Phase E and Phase G will exercise the full sweep.
- **Cross-app perception sidecar:** unrelated to Phase B but relevant memory — way2sense ships the pose+hand Python sidecar on `ws://localhost:8766` and way2move reuses it via port-discovery. If anyone touches the web-recorder camera pipeline, that's the auto-pose hook to wire in later.
