# Way2Move -- Development Workflow

## Development Organization

All feature development is driven by phase task files in `docs/phases/`.
Each phase has a task file with checkboxes tracking completion:

```
docs/phases/
├── phase01-tasks.md    # Training MVP
├── phase02-tasks.md    # AI-Powered Assessment
├── phase03-tasks.md    # Nutrition
├── phase04-tasks.md    # Smart Recovery
├── phase05-tasks.md    # Social & Coaching
└── phase06-tasks.md    # Distribution
```

When asked to "continue development", "work on the next task", or similar -- always
open the current phase file first, find the next incomplete task, and work from there.

---

## Branch Strategy

### Main branches

| Branch | Purpose |
|---|---|
| `main` | Production-ready code, always deployable |
| `phase/1-training` | Phase 1: Training MVP development |
| `phase/2-ai-assessment` | Phase 2: AI-Powered Assessment |
| `phase/3-nutrition` | Phase 3: Nutrition Planning |
| `phase/4-recovery` | Phase 4: Smart Recovery |
| `phase/5-social` | Phase 5: Social & Coaching |
| `phase/6-distribution` | Phase 6: Distribution & App Store |

### Feature branches within phases

Feature branches are created from the current phase branch:

```bash
# Working on a feature within Phase 1
git checkout phase/1-training
git checkout -b feature/exercise-library

# When feature is done, merge back to phase branch
git checkout phase/1-training
git merge feature/exercise-library

# When phase is complete, merge to main
git checkout main
git merge phase/1-training
```

Feature branch naming convention:
```
feature/<short-description>     # new feature
fix/<short-description>         # bug fix
refactor/<short-description>    # code improvement
chore/<short-description>       # tooling, deps, config
```

---

## Git Worktree Setup

Way2Move uses a bare repo + worktree pattern for parallel development across phases.

### Initial setup

```bash
# Clone as bare repo
git clone --bare git@github.com:<org>/way2move.git /projects/way2move/.bare

# Create symlink for git discovery
echo "gitdir: /projects/way2move/.bare" > /projects/way2move/.git

# Create main worktree
git worktree add /projects/way2move/main main
```

### Working with worktrees

```bash
# Add a worktree for a phase branch
git worktree add /projects/way2move/phase1 phase/1-training

# Add a worktree for a feature branch
git worktree add /projects/way2move/feature/exercise-lib feature/exercise-library

# List all worktrees
git worktree list

# Remove a worktree when done
git worktree remove /projects/way2move/feature/exercise-lib
```

### Worktree directory structure

```
/projects/way2move/
├── .bare/                          # bare git repo (do not touch)
├── .git                            # gitdir pointer to .bare
├── main/                           # main worktree
├── phase1/                         # Phase 1 worktree (when active)
└── feature/
    └── exercise-lib/               # feature worktree (when active)
```

Each worktree is a full checkout -- it has its own `node_modules`, `.dart_tool`, etc.
Run `flutter pub get` and `npm install` in each new worktree.

---

## TDD Workflow (Mandatory)

Every feature follows the red-green-refactor cycle:

### 1. Red -- Write a failing test

Write a test that describes the expected behavior. Run it. It must fail.

```dart
test('calculateTotalVolume returns sum of all set volumes', () {
  final block = ExerciseBlock(
    exerciseId: 'squat',
    sets: 3,
    reps: 10,
    weight: 60.0,
  );
  expect(block.totalVolume, 1800.0); // 3 * 10 * 60
});
```

### 2. Green -- Write minimum code to pass

Write only enough implementation to make the test pass. No more.

```dart
class ExerciseBlock {
  // ... fields
  double get totalVolume => sets * reps * (weight ?? 0);
}
```

### 3. Refactor -- Clean up without breaking tests

Improve naming, extract methods, remove duplication. Tests must stay green.

### Implementation order per feature

1. Domain entities + tests
2. Domain repository interfaces
3. Domain use cases + tests
4. Data models + tests
5. Datasources
6. Repository implementations + integration tests
7. Riverpod providers
8. Widgets + widget tests

Never write implementation before the test exists.

---

## Git Hooks via Lefthook

Lefthook manages git hooks. Configuration lives in `lefthook.yml` at the repo root.

### Pre-commit hook (must complete in < 5 seconds)

Runs on every commit. Blocks commit if any check fails.

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    flutter-format:
      glob: "*.dart"
      run: cd frontend/mobile && dart format --set-exit-if-changed {staged_files}
    flutter-analyze:
      glob: "*.dart"
      run: cd frontend/mobile && flutter analyze --no-pub
    ts-lint:
      glob: "*.ts"
      run: cd backend/functions && npx eslint {staged_files}
```

### Pre-push hook (runs full test suite)

Runs before pushing to remote. Blocks push if tests fail.

```yaml
pre-push:
  parallel: true
  commands:
    flutter-test:
      run: cd frontend/mobile && flutter test
    functions-test:
      run: cd backend/functions && npm test
```

### Rules

- Never skip hooks with `--no-verify` -- if a hook fails, fix the underlying issue
- Zero lint/analyze warnings before finishing any task
- Run `flutter analyze` and `dart format .` from `frontend/mobile/` before considering a task done
- Common issues: `prefer_const_constructors`, `deprecated_member_use` -- fix inline, not as separate cleanup

---

## CI Pipeline (GitHub Actions)

### On pull request

```yaml
# .github/workflows/pr.yml
name: PR Checks
on: [pull_request]

jobs:
  flutter-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: cd frontend/mobile && flutter pub get
      - run: cd frontend/mobile && flutter analyze
      - run: cd frontend/mobile && dart format --set-exit-if-changed .
      - run: cd frontend/mobile && flutter test --coverage

  functions-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: cd backend/functions && npm ci
      - run: cd backend/functions && npm run lint
      - run: cd backend/functions && npm run build
      - run: cd backend/functions && npm test

  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: npm install -g firebase-tools
      - run: firebase emulators:start --only auth,firestore,functions &
      - run: cd frontend/mobile && flutter test integration_test/
```

### On merge to main

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd backend/functions && npm ci && npm run build
      - run: firebase deploy --only functions --project way2move-prod

  deploy-rules:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: firebase deploy --only firestore:rules,storage --project way2move-prod
```

### iOS builds (Codemagic)

iOS builds are handled by Codemagic, which publishes to TestFlight.
Triggered on merge to main or manually for beta releases.

---

## Code Review Process

### Before opening a PR

1. All tests pass locally (`flutter test` + `npm test`)
2. Zero lint/analyze warnings (`flutter analyze` returns clean)
3. Code is formatted (`dart format .` produces no changes)
4. Phase task file is updated (checkbox marked `[x]` for completed tasks)
5. Any architecture or data model decisions are documented in the relevant doc

### PR requirements

- PR title: short, descriptive (under 70 characters)
- PR description: what changed, why, how to test
- At least one approval before merge
- All CI checks pass
- No force-pushes to main

### Review checklist

- [ ] Follows Clean Architecture layers (no cross-layer imports)
- [ ] Tests exist and are meaningful (not just happy path)
- [ ] Error handling uses Either, not thrown exceptions across boundaries
- [ ] Riverpod providers are correctly scoped
- [ ] No business logic in widgets
- [ ] Firestore queries are indexed (check `firestore.indexes.json`)
- [ ] Animations are smooth and controllers are disposed

---

## Development Commands Quick Reference

```bash
# Flutter
cd frontend/mobile && flutter run                    # run on connected device
cd frontend/mobile && flutter run -d chrome           # run on web (fast iteration)
cd frontend/mobile && flutter test                    # run all tests
cd frontend/mobile && flutter test --coverage         # tests with coverage
cd frontend/mobile && flutter analyze                 # static analysis
cd frontend/mobile && dart format .                   # format all Dart files

# Firebase emulators
firebase emulators:start                              # start all emulators
firebase emulators:start --import=./emulator-data     # start with seed data
firebase emulators:export ./emulator-data             # export current state
docker compose up emulators                           # start via Docker

# Cloud Functions
cd backend/functions && npm install                   # install deps
cd backend/functions && npm run build                 # build TypeScript
cd backend/functions && npm test                      # run tests
cd backend/functions && npm run build:watch           # watch mode
cd backend/functions && npm run seed                  # seed emulator

# Monorepo
nx run-many --target=test --all                       # test everything
nx graph                                              # dependency graph
```

---

## Keeping Docs in Sync (Non-Negotiable)

Whenever a decision is made or changed, update the relevant doc before moving on:

| Decision type | File to update |
|---|---|
| Product features, scope, user roles, flows | `docs/GENERAL_PROJECT_SPECIFICATION.md` |
| Data structures, collections, fields | `docs/DATA_MODEL.md` |
| Architecture, tech stack, layer rules | `docs/ARCHITECTURE.md` |
| Dev workflow, branching, CI, hooks | `docs/DEV_WORKFLOW.md` (this file) |
| Phase task status | `docs/phases/phase0X-tasks.md` (mark `[x]`) |
| High-level roadmap changes | `docs/DEVELOPMENT_PLAN_HIGH_LEVEL.md` |

Never leave a decision only in chat history -- if it matters, it must be in a doc.
