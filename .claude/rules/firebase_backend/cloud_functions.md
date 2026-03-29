# Firebase Backend — Cloud Functions

## Language and setup
TypeScript only. No plain JavaScript.

```
backend/functions/
├── src/
│   ├── index.ts            # re-exports all functions
│   ├── auth/               # Auth lifecycle triggers
│   ├── sessions/           # Session-related triggers and callables
│   ├── xp/                 # XP calculation logic
│   └── seed/               # Admin callable for seeding
├── scripts/                # one-off migration scripts (not deployed as functions)
├── seeds/                  # JSON seed data files
├── package.json
└── tsconfig.json
```

## tsconfig.json baseline
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017"
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

## package.json scripts
```json
{
  "scripts": {
    "build": "tsc",
    "build:watch": "tsc --watch",
    "serve": "npm run build && firebase emulators:start --only functions",
    "test": "jest --config jest.config.js",
    "lint": "eslint src --ext .ts",
    "seed": "FIRESTORE_EMULATOR_HOST=localhost:8080 ts-node src/seed/seedDatabase.ts",
    "seed:prod": "ts-node src/seed/seedDatabase.ts"
  }
}
```

## Function anatomy

### Auth trigger
```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  await db.collection('users').doc(user.uid).set({
    id: user.uid,
    email: user.email ?? '',
    name: user.displayName ?? '',
    avatarUrl: user.photoURL ?? '',
    roles: ['flyer'],
    disciplines: [],
    totalXp: 0,
    meta: { createdAt: admin.firestore.FieldValue.serverTimestamp() },
  });
});
```

### Firestore trigger
```typescript
export const onSessionCreate = functions.firestore
  .document('sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const session = snap.data() as Session;
    const { sessionId } = context.params;

    const xp = BASE_SESSION_XP;
    const batch = admin.firestore().batch();

    for (const userId of session.flyerIds) {
      const xpRef = admin.firestore().collection('xpEvents').doc();
      batch.set(xpRef, {
        userId,
        amount: xp,
        sourceId: sessionId,
        sourceType: 'session',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const userRef = admin.firestore().collection('users').doc(userId);
      batch.update(userRef, {
        totalXp: admin.firestore.FieldValue.increment(xp),
      });
    }

    await batch.commit();
  });
```

### Callable function
```typescript
interface CalculateXpData {
  sessionId: string;
}

interface CalculateXpResult {
  xp: number;
}

export const calculateXp = functions.https.onCall(
  async (data: CalculateXpData, context): Promise<CalculateXpResult> => {
    // 1. Auth check
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in');
    }

    // 2. Input validation
    const { sessionId } = data;
    if (!sessionId || typeof sessionId !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'sessionId must be a non-empty string');
    }

    // 3. Business logic
    const xp = await computeXpForSession(sessionId, context.auth.uid);
    return { xp };
  }
);
```

## Error handling in callables
Always throw `HttpsError` — never throw plain errors:
```typescript
throw new functions.https.HttpsError(
  'not-found',          // gRPC status code (see list below)
  'Session not found',  // message for client
  { sessionId }         // optional details
);
```

Common codes: `unauthenticated`, `permission-denied`, `invalid-argument`, `not-found`, `already-exists`, `internal`

## index.ts — export all functions
```typescript
// src/index.ts
import * as admin from 'firebase-admin';
admin.initializeApp();

export { onUserCreate } from './auth/onUserCreate';
export { onSessionCreate } from './sessions/onSessionCreate';
export { calculateXp } from './xp/calculateXp';
export { seedDatabase } from './seed/seedDatabase';
```

Note: `admin.initializeApp()` is called exactly once in `index.ts`.

## Testing Cloud Functions

Test with Vitest against the Firebase emulator:
```typescript
// src/xp/calculateXp.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Set env before importing functions
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

describe('calculateXp', () => {
  it('returns base XP for a session', async () => {
    // arrange: create session in emulator Firestore
    // act: call the function
    // assert: verify XP event was created
  });
});
```

Run tests with emulator running:
```bash
firebase emulators:start --only firestore,auth &
npm test
```

## Deployment
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy a single function
firebase deploy --only functions:onUserCreate

# Deploy to specific environment
firebase use production && firebase deploy --only functions
```

## Performance rules
- Keep functions under 60s (default timeout) — increase to 540s max only for migrations
- Use Firestore batch writes for multi-document updates (max 500 ops per batch)
- Use `Promise.all` for parallel async operations that don't depend on each other
- Cold start time matters: keep `index.ts` imports lean; don't import unused SDKs
