# Development Workflow

## Feature Development Phases
Every feature follows this workflow. Skip phases only when explicitly noted.

1. **Discovery** (flexible) — references, prototype (if needed), plan
2. **Design Build** — UI only, hardcoded data, iterate with user
3. **Full Specs** — spec.md + test-cases.md
4. **Domain + Unit Tests** — TDD, pure business logic, zero framework imports
5. **UI Wiring + Widget Tests** — connect UI to domain
6. **Adapters + Integration Tests** — real Firebase/API adapters
7. **E2E + QA** — end-to-end tests, fix until green
8. **Deploy** — staging then production

## Feature Folder Structure
All feature docs live in `docs/screens/[feature-name]/`:
```
docs/screens/[feature-name]/
├── discovery/
│   ├── references/              # Screenshots, GIFs of similar apps
│   ├── reference-specs.md       # AI descriptions of references
│   ├── prototype-learnings.md   # What we learned from prototype (if exists)
│   └── plan.md                  # Scope, architecture, dependencies
├── design/
│   ├── reference-spec.md        # Design description for AI
│   ├── design-v1.md             # First iteration
│   └── design-final.md          # Approved design
├── spec.md                      # Full spec: user flows, edge cases, validation
└── test-cases.md                # All test scenarios (unit, widget, integration, E2E)
```

## How to Add a Reference
1. Save screenshot/GIF to `docs/screens/[feature]/discovery/references/`
2. Describe it in `docs/screens/[feature]/discovery/reference-specs.md`:
   - Source (app/URL), what you like, motion/animation details, layout notes

## How to Start a New Feature
1. Create folder: `docs/screens/[feature-name]/discovery/`
2. Write `plan.md` with scope, user stories, architecture decisions
3. Collect references if needed
4. Proceed through phases sequentially

## Refining a Prototype Feature
1. Create `docs/screens/[feature]/discovery/prototype-learnings.md`
   - What was built, what works, what needs improvement
2. Decide: refine (add tests + polish) or rewrite (start from Phase 2)
3. Write spec.md and test-cases.md
4. Add missing tests (Phases 4-7)
5. Feature flag it until all tests pass

## Feature Flags
- All prototype features must be behind Firebase Remote Config flags
- See docs/FEATURE_FLAGS_INVENTORY.md for the full list
- Flag naming: `feature_[name]` (e.g., `feature_nutrition`)

## Architecture (Hexagonal + Vertical Slice)
For new features, use this structure inside the code:
```
features/[feature_name]/
├── domain/          # Pure Dart/TS, ZERO framework imports
│   ├── entities/
│   └── use_cases/
├── ports/           # Interfaces only, depends on domain/ only
├── adapters/        # Firebase, API implementations
└── ui/              # Screens, widgets, providers
```
Existing features use domain/data/presentation — equivalent, don't rename unless refining.

## Strategy Reference
Full strategy docs at: /projects/my-projects/way2do/
- strategy/DECISIONS.md — all tech decisions
- strategy/WORKFLOW.md — detailed workflow guide
- strategy/ARCHITECTURE.md — architecture patterns
- templates/ — all templates with examples
