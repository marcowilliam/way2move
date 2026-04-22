# Way2Move — Claude Code Context

## What is this project?
Way2Move is a movement-first training platform for normal life athletes.
Think "the movement operating system" — build body awareness through voice-first journaling, track compensations and movement goals, follow PRI/DNS-based corrective programs, log training + recovery sessions, track nutrition (with IBS/gut awareness), sleep, and progress photos. Gait cycle education teaches users to move from the ground up.

## Central Nervous System

This project is part of Marco's CNS at `/projects/my-projects/marco-cns/`.
Project state: `marco-cns/projects/way2move/`

### Read from CNS
- Domain knowledge (defaults): `marco-cns/cortex/` (dev-workflow, design, architecture, etc.)
- This project's state: `marco-cns/projects/way2move/` (PROFILE, STATUS, ROADMAP, DECISIONS, LEARNINGS)
- This project's domain overrides: `marco-cns/projects/way2move/cortex/` (when they exist)
- Templates: `marco-cns/templates/`
- Prompts: `marco-cns/spine/prompts/`

### Write to CNS (not to this repo) when:
- Status/roadmap/decisions change → update `marco-cns/projects/way2move/`
- You discover a reusable pattern → append to `marco-cns/projects/way2move/LEARNINGS.md`
- A decision affects multiple projects → append to `marco-cns/DECISIONS.md`
- Session ending → update `marco-cns/projects/way2move/SESSION_HANDOFF.md`

### Override model
Check `marco-cns/projects/way2move/DECISIONS.md` for domain overrides before applying general defaults.
Full routing rules: `marco-cns/spine/rules/cns-update-rules.md`

## Repo structure
```
/projects/way2move/
├── .bare/                    # bare git repo (do not touch)
├── .git                      # gitdir pointer to .bare
└── main/                     # main worktree (this folder)
    ├── CLAUDE.md
    ├── .claude/rules/        # detailed architecture rules (imported below)
    ├── docs/
    ├── frontend/
    │   ├── mobile/           # Flutter app (iOS + Android)
    │   └── web/              # React + Vite (Phase 5+)
    └── backend/
        └── functions/        # Firebase Cloud Functions (TypeScript)
```

Feature branches use git worktrees — each worktree folder IS the branch:
```bash
git worktree add /projects/way2move/feature/exercise-library feature/exercise-library
```

## Tech stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (stable), Dart |
| Web (Phase 5+) | React + Vite + TypeScript |
| Backend (Phase 1-3) | Firebase: Auth, Firestore, Functions, Storage |
| Backend (Phase 3+) | External AI APIs for food photo recognition |
| Monorepo | Nx (root), Melos (Flutter), pnpm workspaces (JS) |
| Git hooks | Lefthook — pre-commit: format+lint, pre-push: tests |
| CI/CD | GitHub Actions (Android + web + Firebase), Codemagic (iOS → TestFlight) |
| Observability | Sentry (free tier, initialized on day one) |
| Feature flags | Firebase Remote Config |

## Development commands

### Flutter (mobile)
```bash
# Run on Android emulator
cd frontend/mobile && flutter run

# Run on web (fast UI iteration)
cd frontend/mobile && flutter run -d chrome

# Run all tests
cd frontend/mobile && flutter test

# Run tests with coverage
cd frontend/mobile && flutter test --coverage

# Analyze + format
cd frontend/mobile && flutter analyze && dart format .

# Check environment
flutter doctor
```

### Firebase emulators (native)
```bash
# Start all emulators (Auth:9099 Firestore:8080 Functions:5001 Storage:9199 UI:4000)
firebase emulators:start

# Start with seed data from a saved snapshot
firebase emulators:start --import=./emulator-data

# Export emulator state (useful during dev)
firebase emulators:export ./emulator-data
```

### Firebase emulators (Docker)
```bash
# Start emulators via Docker Compose (recommended for consistent env)
docker compose up emulators

# Start in background
docker compose up -d emulators

# View logs
docker compose logs -f emulators

# Stop
docker compose down
```

### Cloud Functions (TypeScript)
```bash
cd backend/functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Run tests (against emulator)
npm test

# Watch mode during development
npm run build:watch

# Deploy to Firebase (prod)
firebase deploy --only functions
```

### Monorepo (Nx)
```bash
# Run all tests across the monorepo
nx run-many --target=test --all

# Run mobile tests only
nx test mobile

# Run functions tests only
nx test functions

# Show dependency graph
nx graph
```

### Seed data
```bash
# Run seed scripts against local emulator (emulators must be running)
cd backend/functions && npm run seed

# Run seed scripts against production (first deploy only)
cd backend/functions && npm run seed:prod
```

## Environment

| Variable | Value |
|---|---|
| OS | Ubuntu 24.04 |
| Shell | zsh — PATH exports in `~/.zshrc` |
| Android SDK | `/projects/Android/Sdk` |
| Android AVDs | `/projects/Android/avd` |
| Node.js | v20 via nvm |
| Package manager | pnpm (JS root), npm (functions only) |
| Flutter channel | stable |

## User roles
Phase 1: **Athlete only** — single self-guided role.
Phase 5+: Coach role can be added (same dual-role model as Way2Fly).

## Development phases
All feature development is driven by the phase task files in `docs/phases/`:
```
docs/phases/
├── phase01-tasks.md    # Training System (MVP)
├── phase02-tasks.md    # AI Movement Assessment
├── phase03-tasks.md    # Nutrition
├── phase04-tasks.md    # Smart Recovery
├── phase05-tasks.md    # Social & Coaching
├── phase06-tasks.md    # Deployment & Distribution
```
When asked to "continue development", "work on the next task", or similar — always open the current phase file first, find the next incomplete task, and work from there.

## UI/UX guidelines
No Figma designs yet — Claude makes all UI/UX decisions as a senior designer + senior Flutter mobile developer. When Figma is provided, it supersedes these defaults.

**Aesthetic:** Clean, calm, and functional. Wellness meets performance — think Headspace meets Strava. Works outdoors in bright sun and with sweaty hands. Light-mode-first with dark mode support, high contrast, generous tap targets (min 48×48px). Rounded corners, soft shadows, muted earth tones with accent colors for progress and achievements.

**Motion and animation (non-negotiable):**
- Every screen transition is animated — no raw `MaterialPageRoute`; use custom `PageRouteBuilder` with slide or fade transitions
- State changes (loading → data, locked → unlocked, progression) are always animated, never instant swaps
- Exercise completion and session completion show brief celebratory animations
- List items animate in with staggered entrance (e.g., `Interval`-based stagger)
- Use `Hero` transitions wherever an element travels between two screens (exercise card → exercise detail, session card → session detail)
- Use implicit animations (`AnimatedContainer`, `AnimatedOpacity`) for simple property changes; explicit `AnimationController` for sequences and interactive gestures
- Always `dispose()` controllers — no memory leaks
- Calendar view transitions are smooth — swipe between weeks/months
- Progress indicators (rings, bars) animate on load

**Flutter animation skill** is installed at `../.claude/skills/flutter-animating-apps/SKILL.md` and auto-imported below.

## Keeping docs in sync (non-negotiable)
Whenever a business, technical, or workflow decision is made — or changed — update the relevant doc before moving on:

| Decision type | File to update |
|---|---|
| Product features, scope, user roles, flows | `docs/GENERAL_PROJECT_SPECIFICATION.md` |
| Data structures, collections, fields | `docs/DATA_MODEL.md` |
| Architecture, tech stack, layer rules | `docs/ARCHITECTURE.md` and `.claude/rules/` |
| Dev workflow, branching, CI, hooks | `docs/DEV_WORKFLOW.md` |
| Phase task status | `docs/phases/phase0X-tasks.md` (mark `[x]` when done) |
| High-level roadmap changes | `docs/DEVELOPMENT_PLAN_HIGH_LEVEL.md` |
| UI changes (new screens, interactions, flows) | `docs/phases/phase0X-tasks.md` under the block's `### UI — What to test` subsection — **never create a separate file** |

Never leave a decision only in chat history — if it matters, it must be in a doc.

## Best practices (non-negotiable)
- **TDD always** — write the test first, then the implementation. Every feature must have tests before it ships.
- **Every feature is tested** — unit, integration, and at least one E2E for critical flows. A feature is not done without tests.
- **Follow the architecture rules** for each layer — Flutter uses Clean Architecture + Riverpod, Firebase Functions use TypeScript with the repository pattern. See imported rules below.
- **Never hit real Firebase in tests** — always use the Local Emulator Suite.
- TypeScript for all Cloud Functions code. No plain JS.
- Phase 1–3: clients talk to Firebase SDKs directly — no custom REST API.
- Prefer Firebase Spark (free) plan through the early phases. A custom Node server is fine earlier if it's justified — e.g. the cross-app assistant ingest service, or anything that needs long-lived workers, shared state across apps, or libraries that don't fit Cloud Functions. Default stays: clients talk to Firebase SDKs directly; reach for a Node service when Functions genuinely won't do.
- Feature plans live in `docs/features/`. No Jira — everything lives in this repo.
- **Zero lint/analyze warnings before finishing any task** — Lefthook runs `flutter analyze` and `dart format` on pre-commit. Fix all issues as part of the task, not as a separate clean-up step. Common issues to watch: `prefer_const_constructors` (add `const` to constructors that accept only literal/const args), `deprecated_member_use` (follow the migration hint in the warning). Run `flutter analyze` and `dart format .` from `frontend/mobile/` before considering a task done.

---

## Detailed rules (auto-imported by Claude)

@.claude/rules/flutter_frontend/architecture.md
@.claude/rules/flutter_frontend/state_management.md
@.claude/rules/flutter_frontend/navigation.md
@.claude/rules/flutter_frontend/testing.md
@.claude/rules/firebase_backend/architecture.md
@.claude/rules/firebase_backend/firestore.md
@.claude/rules/firebase_backend/cloud_functions.md
@.claude/rules/firebase_backend/auth.md
@.claude/rules/firebase_backend/security_rules.md
@.claude/rules/web_frontend/architecture.md
@.claude/rules/testing.md
@.claude/rules/docker.md
@../.claude/skills/flutter-animating-apps/SKILL.md
@.claude/skills/ios-staging-codemagic/SKILL.md
