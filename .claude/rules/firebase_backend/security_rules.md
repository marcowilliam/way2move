# Firebase Backend — Security Rules

## Principles
- Security rules are access control, not business logic
- Default to deny — only open what is explicitly needed
- Never put computation or data validation in rules (do that in Cloud Functions)
- Always test rules with the Firebase Emulator before deploying

## Firestore rules (firestore.rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isCoachOnSession(sessionData) {
      return isSignedIn() && request.auth.uid in sessionData.coachIds;
    }

    function isFlyerOnSession(sessionData) {
      return isSignedIn() && request.auth.uid in sessionData.flyerIds;
    }

    // Seed / reference data: read-only for all authenticated users
    match /disciplines/{id} {
      allow read: if isSignedIn();
      allow write: if false;   // written by Cloud Functions only
    }

    match /skills/{id} {
      allow read: if isSignedIn();
      allow write: if false;
    }

    match /skillLevels/{id} {
      allow read: if isSignedIn();
      allow write: if false;
    }

    match /skillLevel_Skills/{id} {
      allow read: if isSignedIn();
      allow write: if false;
    }

    // User documents: own profile only
    match /users/{userId} {
      allow read: if isOwner(userId);
      allow create: if false;   // created by onUserCreate Cloud Function
      allow update: if isOwner(userId)
        && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['id', 'email', 'totalXp', 'meta']);
      allow delete: if false;
    }

    // Sessions: flyer can create/update, coach can read if tagged
    match /sessions/{sessionId} {
      allow read: if isFlyerOnSession(resource.data) || isCoachOnSession(resource.data);
      allow create: if isSignedIn()
        && request.auth.uid in request.resource.data.flyerIds;
      allow update: if isFlyerOnSession(resource.data);
      allow delete: if isFlyerOnSession(resource.data);
    }

    // User skills: own data only
    match /user_Skills/{id} {
      allow read, write: if isSignedIn()
        && request.auth.uid == resource.data.userId;
      allow create: if isSignedIn()
        && request.auth.uid == request.resource.data.userId;
    }

    match /user_Disciplines/{id} {
      allow read, write: if isSignedIn()
        && request.auth.uid == resource.data.userId;
      allow create: if isSignedIn()
        && request.auth.uid == request.resource.data.userId;
    }

    // XP events: written by Cloud Functions (Admin SDK bypasses rules)
    // Users can read their own XP events
    match /xpEvents/{id} {
      allow read: if isSignedIn() && request.auth.uid == resource.data.userId;
      allow write: if false;   // written only by Cloud Functions
    }

    // Badges: read-only for owner
    match /badges/{id} {
      allow read: if isSignedIn() && request.auth.uid == resource.data.userId;
      allow write: if false;
    }

    // Teams and camps: Phase 2 — locked down until implemented
    match /teams/{teamId} {
      allow read, write: if false;
    }

    match /camps/{campId} {
      allow read, write: if false;
    }
  }
}
```

## Storage rules (storage.rules)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // User avatars: owner read/write, public read
    match /users/{userId}/avatar/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
        && request.auth.uid == userId
        && request.resource.size < 2 * 1024 * 1024   // 2MB max
        && request.resource.contentType.matches('image/.*');
    }

    // Everything else: locked
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Testing rules
Test rules using the Firebase emulator — never deploy untested rules to production.

```bash
# Run rules tests (uses @firebase/rules-unit-testing)
cd backend/functions && npm run test:rules
```

Example rules test:
```typescript
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';

const env = await initializeTestEnvironment({ projectId: 'way2fly-dev' });

// Authenticated user can read own session
await assertSucceeds(
  env.authenticatedContext('user1').firestore()
    .doc('sessions/sess1').get()
);

// Different user cannot read session they're not part of
await assertFails(
  env.authenticatedContext('user2').firestore()
    .doc('sessions/sess1').get()
);
```

## Rules deployment
```bash
# Deploy only security rules (fast, no function rebuild)
firebase deploy --only firestore:rules,storage

# Deploy rules + indexes together
firebase deploy --only firestore
```

## Admin SDK bypasses rules
Cloud Functions using the Admin SDK bypass all security rules. This is intentional — Functions are trusted server code. Be careful what you write inside Functions; they have full read/write access to Firestore.
