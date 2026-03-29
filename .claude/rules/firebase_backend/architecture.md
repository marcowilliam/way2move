# Firebase Backend — Architecture

## Overview

Firebase is the infrastructure layer for Phase 1 and 2. Clients (Flutter, React) communicate with Firebase services directly via the Firebase SDK — there is **no custom REST API** until Phase 3.

```
┌─────────────────────────────────────────────┐
│               Flutter App                   │
│  firebase_auth  │  cloud_firestore  │  storage│
└────────┬────────┴────────┬──────────┴────────┘
         │                 │
┌────────▼─────────────────▼──────────────────┐
│              Firebase Platform               │
│  Auth  │  Firestore  │  Functions  │  Storage│
└────────────────────────────────────────────┘
              ↑ triggered by
┌─────────────────────────────────────────────┐
│         Cloud Functions (TypeScript)         │
│  Auth triggers  │  Firestore triggers  │ HTTP│
└─────────────────────────────────────────────┘
```

## What Firebase provides
- **Auth**: identity, JWT tokens, provider federation (email, Google, Apple)
- **Firestore**: NoSQL document database with real-time sync and offline support
- **Cloud Functions**: serverless compute — business logic too complex for security rules, or needs Admin SDK
- **Storage**: binary file storage (avatars, videos Phase 3)
- **Remote Config**: feature flags, synced to all clients

## Phase 1–2: No custom REST API
The Flutter app calls Firebase SDKs directly. For operations that need server-side logic, use Callable Cloud Functions — the Firebase SDK calls these as if they were RPCs (no URL handling needed in client code).

**Phase 3+**: Add Node.js API (Express/Fastify) for video processing, complex SQL queries. Firebase Auth is kept for identity even then.

## TypeScript for all Functions

All Cloud Functions are TypeScript. Zero plain JavaScript.

```
backend/functions/
├── src/
│   ├── auth/
│   │   └── onUserCreate.ts        # Auth trigger: create Firestore user doc
│   ├── sessions/
│   │   └── onSessionCreate.ts     # Firestore trigger: award XP
│   ├── xp/
│   │   └── calculateXp.ts         # Callable: compute XP for a session
│   ├── seed/
│   │   └── seedDatabase.ts        # Callable (admin-only): seed disciplines/skills
│   └── index.ts                   # exports all functions
├── scripts/
│   └── migrate.ts                 # one-off data migration scripts
├── seeds/
│   ├── disciplines.json
│   ├── skills.json
│   └── skill_levels.json
├── package.json
└── tsconfig.json
```

## Function types

### Auth triggers — react to user lifecycle events
```typescript
// src/auth/onUserCreate.ts
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection('users').doc(user.uid).set({
    id: user.uid,
    email: user.email,
    name: user.displayName ?? '',
    roles: ['flyer'],
    disciplines: [],
    totalXp: 0,
    meta: { createdAt: admin.firestore.FieldValue.serverTimestamp() },
  });
});
```

### Firestore triggers — react to document events
```typescript
// src/sessions/onSessionCreate.ts
export const onSessionCreate = functions.firestore
  .document('sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const session = snap.data() as Session;
    // award base XP to each flyer
    await awardSessionXp(session);
  });
```

### Callable functions — client-invoked server logic
```typescript
// src/xp/calculateXp.ts
export const calculateXp = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
  }
  // validate input
  const { sessionId } = data as { sessionId: string };
  if (!sessionId) {
    throw new functions.https.HttpsError('invalid-argument', 'sessionId required');
  }
  // business logic
  return { xp: await computeXpForSession(sessionId, context.auth.uid) };
});
```

Called from Flutter:
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('calculateXp')
    .call({'sessionId': id});
```

## Admin SDK vs Client SDK
- Inside Cloud Functions: always use **Admin SDK** (`firebase-admin`) — bypasses security rules
- Client apps (Flutter): always use **Client SDK** (`firebase_core`, `cloud_firestore`) — subject to security rules
- Never expose the Admin SDK service account to clients

## Environments
- Development: Firebase Local Emulator Suite (all services emulated locally)
- Production: real Firebase project
- Config: `FIREBASE_PROJECT_ID`, `GCLOUD_PROJECT` env vars; `.env` file for local overrides

## Business logic placement
| Logic type | Where it lives |
|---|---|
| Input validation (server-side) | Callable Function |
| Access control | Firestore security rules |
| Data aggregation / XP calculation | Cloud Function trigger or Callable |
| Client-side validation (UX) | Flutter use cases |
| Auth token verification | Security rules (`request.auth`) |

Never put business logic inside security rules — rules are for access control only.
