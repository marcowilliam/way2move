# Repository Creation Notes

> This document records the step-by-step process used to create the Way2Move repository
> from a product specification. It can be used to automate future repo creation for
> similar Flutter + Firebase projects.

---

## Prerequisites

- Git installed
- Flutter SDK installed (stable channel)
- Node.js v20+ installed
- Firebase CLI installed (`npm install -g firebase-tools`)

---

## Step-by-step process

### Step 1: Initialize bare git repo with worktree structure

```bash
mkdir -p /projects/<project-name>
cd /projects/<project-name>
git init --bare .bare --initial-branch=main
echo "gitdir: .bare" > .git
git worktree add main
```

**Why bare + worktree?** Enables parallel feature development — each feature branch is a separate folder on disk, no stashing or context switching needed.

### Step 2: Create directory structure

```bash
cd /projects/<project-name>/main
mkdir -p docs/phases docs/features
mkdir -p frontend/mobile frontend/web
mkdir -p backend/functions/src/{auth,seed}
mkdir -p backend/functions/{scripts,seeds}
mkdir -p .claude/rules/{flutter_frontend,firebase_backend,web_frontend}
```

**Key directories:**
- `docs/` — all project documentation (spec, data model, architecture, workflow, phases)
- `docs/phases/` — phase task checklists (the work breakdown)
- `frontend/mobile/` — Flutter app
- `backend/functions/` — Firebase Cloud Functions (TypeScript)
- `.claude/rules/` — Claude Code architecture rules (auto-imported by CLAUDE.md)

### Step 3: Write GENERAL_PROJECT_SPECIFICATION.md

**Input:** Product brainstorm / conversation with stakeholder
**Output:** `docs/GENERAL_PROJECT_SPECIFICATION.md`

This is the authoritative product spec. It includes:
1. **Name and pitch** — problem, solution, vision
2. **Product principles** — 3-5 guiding principles
3. **Target users** — who this is for
4. **Roadmap** — phases with goals (one paragraph each)
5. **Phase 1 full specification** — detailed entities, screens, MVP scope
6. **Tech stack summary**

**Template structure:**
```markdown
# <Project> — General Product Specification
## Name
## Pitch (Problem, Solution, Vision)
## Product principles
## Target users
## Roadmap (Phase 1..N — title + goal + bullet points)
## Phase 1 — Full Specification
  ### Objective
  ### User roles
  ### Core concepts (domain-specific)
  ### Data model summary (collection table)
  ### Phase 1 screens (numbered list)
  ### Entity definitions (field tables per entity)
  ### MVP scope (included/excluded)
## Tech stack summary
```

### Step 4: Write CLAUDE.md

**Input:** Product spec + tech stack decisions
**Output:** `CLAUDE.md` at repo root

This is the master context file for Claude Code. It includes:
1. **What is this project** — one-sentence description
2. **Repo structure** — directory tree
3. **Tech stack table**
4. **Development commands** — Flutter, Firebase, Nx, seed data
5. **Environment variables**
6. **User roles** — current phase scope
7. **Development phases** — pointer to docs/phases/
8. **UI/UX guidelines** — aesthetic, animation rules
9. **Keeping docs in sync** — which doc to update for which decision type
10. **Best practices** — TDD, testing, lint rules
11. **Rule imports** — `@.claude/rules/<path>` references

**Key:** The `@` import syntax at the bottom pulls in all architecture rules automatically.

### Step 5: Write architecture rules (.claude/rules/)

**Input:** Tech stack + architecture decisions
**Output:** Multiple `.md` files in `.claude/rules/`

These are REUSABLE across projects with the same stack. For Flutter + Firebase + Riverpod:

| File | Content |
|---|---|
| `flutter_frontend/architecture.md` | Clean Architecture layers, feature folder structure, naming conventions, error handling, implementation order |
| `flutter_frontend/state_management.md` | Riverpod provider types, when to use each, rules |
| `flutter_frontend/navigation.md` | GoRouter setup, route constants, auth gating |
| `flutter_frontend/testing.md` | Test types, TDD workflow, mocktail usage, coverage targets |
| `firebase_backend/architecture.md` | Firebase services overview, function types, Admin SDK rules |
| `firebase_backend/firestore.md` | Collection naming, document IDs, repository pattern, models, queries |
| `firebase_backend/cloud_functions.md` | TypeScript setup, function anatomy, error handling, deployment |
| `firebase_backend/auth.md` | Auth providers, Flutter integration, token handling, emulator setup |
| `firebase_backend/security_rules.md` | Firestore and Storage rules with helper functions |
| `web_frontend/architecture.md` | Placeholder for future web (React + Vite) |
| `testing.md` | Cross-cutting testing philosophy, TDD workflow, test types |
| `docker.md` | Docker Compose for Firebase emulators |

**These files are ~90% reusable.** Only domain-specific examples (entity names, collection names, route names) need adaptation per project.

### Step 6: Write supporting documentation

| File | Content | Adapts from |
|---|---|---|
| `docs/ARCHITECTURE.md` | System diagram, monorepo tooling, testing strategy, layout | Spec + tech stack |
| `docs/DEV_WORKFLOW.md` | Phase branches, worktree setup, TDD workflow, hooks, CI | Same across projects |
| `docs/DATA_MODEL.md` | Firestore collection schemas, decisions, offline strategy | Spec entities |
| `docs/DEVELOPMENT_PLAN_HIGH_LEVEL.md` | Phase dependency diagram, parallel execution notes | Spec roadmap |

### Step 7: Write phase task files

**Input:** Phase 1 spec (entities, screens, features)
**Output:** `docs/phases/phase01-tasks.md` (detailed), `phase02-06-tasks.md` (high-level)

Phase 1 task file structure:
1. **Block 0 — Project Setup** (Flutter init, Firebase config, dependencies, tooling)
2. **Block 1 — Auth** (always first feature — domain → data → presentation → tests)
3. **Block 2..N — Features** (one block per feature, following implementation order)
4. Each task is a checkbox `- [ ]` scoped to ~one work session
5. Tasks follow Clean Architecture order: domain → data → presentation → tests

Future phase files are kept at block-level (not task-level) since scope may change.

### Step 8: Initialize Flutter project

```bash
cd frontend/
flutter create --org com.<project-name> --project-name <project_name> mobile
```

Then create the Clean Architecture folder structure:
```bash
cd mobile/lib
mkdir -p core/{constants,errors,extensions,router/guards,theme,utils,providers}
mkdir -p features/<feature>/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{pages,widgets,providers}}
mkdir -p shared/{widgets,l10n}
```

**Repeat the features/ structure for each feature identified in Phase 1.**

### Step 9: Initialize Firebase backend

Create:
- `backend/functions/package.json` — scripts for build, test, seed, lint
- `backend/functions/tsconfig.json` — strict TypeScript config
- `backend/functions/src/index.ts` — admin.initializeApp() + function exports
- `backend/functions/src/auth/onUserCreate.ts` — auth trigger (always needed)
- `backend/functions/src/seed/seedDatabase.ts` — seed script scaffold

Create root Firebase files:
- `firebase.json` — emulator config, functions source, rules paths
- `firestore.rules` — security rules based on data model
- `firestore.indexes.json` — composite indexes for known queries
- `storage.rules` — storage access rules

### Step 10: Create .gitignore

Standard ignores for: node_modules, build outputs, IDE files, OS files, Firebase logs, .env files, Flutter generated files, coverage.

### Step 11: Create the CLI worktree switcher script

Create `scripts/w<abbrev>.sh` (e.g. `w2m.sh` for Way2Move, `w2f.sh` for Way2Fly).
This gives you a single command to switch branches, start the emulator + Flutter web, seed data, stop everything, and check status.

```bash
mkdir -p /projects/<project-name>/main/scripts
# copy scripts/w2f.sh from way2fly as a template, then:
#   - replace W2F_ → W<ABBREV>_ throughout
#   - replace W2F_ROOT with /projects/<project-name>
#   - replace the function name w2f → w<abbrev>
#   - replace internal helper names _w2f_ → _w<abbrev>_
#   - update the header comment
#   - set W2M_EMU_DATA to a project-specific path (e.g. ~/way2move-emulator-data)
#     so each project has its own emulator snapshot directory
```

Then source it in `~/.zshrc`:

```bash
# Way2Move environment switcher
source /projects/<project-name>/main/scripts/w<abbrev>.sh
```

Reload the shell:
```bash
source ~/.zshrc
```

**Script capabilities:**
- `w<abbrev> <branch>` — stop current, build functions, start emulator, start Flutter web
- `w<abbrev> <branch> --seed` — same + seed the database
- `w<abbrev> stop` — gracefully stop emulator (exports data) + kill Flutter
- `w<abbrev> ls` — list all available worktrees
- `w<abbrev> status` — show what's currently running

Logs go to `/tmp/w<abbrev>/` (emulator.log, flutter.log). Emulator data is persisted across restarts via `--import`/`--export-on-exit`.

### Step 12: Initial commit

```bash
cd /projects/<project-name>/main
git add -A
git commit -m "chore: initial project scaffold — docs, Flutter app, Firebase functions, architecture rules"
```

---

## What's reusable vs project-specific

### Reusable (copy as-is or with minimal changes):
- `.claude/rules/` — all architecture rules (~90% identical)
- `docs/DEV_WORKFLOW.md` — same workflow pattern
- `CLAUDE.md` structure — same sections, different content
- `firebase.json` — same emulator config
- `.gitignore` — same ignores
- `backend/functions/tsconfig.json` — same config
- `backend/functions/package.json` — same scripts, different name

### Project-specific (must be written from spec):
- `docs/GENERAL_PROJECT_SPECIFICATION.md` — unique per product
- `docs/DATA_MODEL.md` — unique collections/schemas per product
- `docs/DEVELOPMENT_PLAN_HIGH_LEVEL.md` — unique phase dependencies
- `docs/phases/*.md` — unique task breakdowns per product
- `firestore.rules` — unique collections and access patterns
- `firestore.indexes.json` — unique queries
- `storage.rules` — unique storage patterns
- Seed data (`backend/functions/seeds/`) — unique per domain
- Flutter feature folder names — unique per domain
- `backend/functions/src/` function files — unique per domain

---

## Automation opportunities

An agent that automates this process would need:

1. **Input:** A product specification document (or structured conversation output)
2. **Template engine:** For reusable files (rules, workflow, CLAUDE.md structure)
3. **AI generation:** For project-specific files (spec → data model, spec → phase tasks, spec → security rules)
4. **Shell execution:** For `git init`, `flutter create`, `mkdir`
5. **Validation:** Check that all required files exist and cross-reference correctly

### Suggested automation flow:
```
1. User provides: product name, description, tech stack choice, feature list
2. Agent generates: GENERAL_PROJECT_SPECIFICATION.md (from conversation/input)
3. Agent copies: architecture rules templates (parameterized by project name)
4. Agent generates: DATA_MODEL.md (from spec entities)
5. Agent generates: phase task files (from spec features)
6. Agent generates: CLAUDE.md (from spec + tech stack)
7. Agent generates: security rules (from data model)
8. Agent runs: git init, flutter create, mkdir
9. Agent generates: seed data scaffolds
10. Agent generates: CLI switcher script (scripts/w<abbrev>.sh) and adds source line to ~/.zshrc
11. Agent commits: initial scaffold
```

Total files created: ~30-40
Time to create manually: ~2-3 hours
Time with automation: ~5-10 minutes
