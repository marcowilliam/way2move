# Web Frontend — Architecture (Phase 3)

Status: **NOT YET IMPLEMENTED** — placeholder for when Phase 3 begins.
Do not scaffold or implement any React code until Phase 3 is started.

---

## Planned stack
- React 19 + Vite + TypeScript (strict mode)
- React Query (TanStack Query v5) — server/Firebase state
- Zustand — global UI state only (modals, sidebar, preferences)
- React Router v6 — routing
- Tailwind CSS — styling
- Vitest + React Testing Library — unit + component tests
- Playwright — E2E tests

## Planned folder structure
```
frontend/web/src/
├── core/
│   ├── router/             # React Router definition, auth guards
│   ├── firebase/           # Firebase SDK init
│   └── utils/
├── features/
│   └── <feature>/
│       ├── api/            # Firebase/API calls (used by React Query hooks)
│       ├── components/     # feature-scoped components
│       ├── hooks/          # useQuery / useMutation hooks
│       └── pages/          # route-level components
└── shared/
    ├── components/         # app-wide UI primitives
    └── hooks/
```

## Key conventions (when Phase 3 starts)
- Feature-based structure mirrors Flutter — same domain model, different UI
- React Query for all data fetching — no manual fetch/useEffect patterns
- TypeScript strict: `"strict": true` in tsconfig, no `any`
- Co-locate tests with source: `LoginPage.test.tsx` next to `LoginPage.tsx`
- No Redux — Zustand for the small amount of global UI state this app needs

## TypeScript
All web code is TypeScript. Shared types between web and functions can live in a `packages/shared-types/` workspace package when needed.

## REST API vs Firebase SDK (Phase 3)
Phase 3 introduces an **Express** API (TypeScript) in `backend/api/` for video and debrief operations. The web app will call:
- Firebase SDK directly for: auth, real-time data, user profiles
- Express REST API for: video upload (presigned URLs), debrief CRUD, processing status

Video is stored in **Firebase Storage**. Debrief data (videos metadata, debriefs, markers, voice notes) lives in **PostgreSQL (Supabase)**.

REST API conventions:
- JSON request/response bodies
- `Authorization: Bearer <firebase-id-token>` header for all authenticated routes
- Standard HTTP status codes
- Versioned endpoints: `/api/v1/...`
- Error format: `{ error: { code, message, details? } }`

### Web app scope (Phase 3)
Web provides: sessions list, session detail (video + debrief creation), debriefs list, debrief editor (video + markers + summary), and standalone debrief creation (upload video or paste YouTube link, pick discipline + skills). YouTube videos embedded via IFrame API. Profile and skill tree remain mobile-only.
