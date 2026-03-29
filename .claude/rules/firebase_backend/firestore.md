# Firebase Backend — Firestore

## Core concepts
Firestore is a NoSQL document database. Documents live in collections. There are no joins — design for your read patterns, not for normalized data.

Key properties relevant to this app:
- Real-time sync via listeners (used for sessions, user skills)
- Offline persistence on Flutter (enabled by default with the SDK)
- Security rules run on every read/write
- No aggregation queries (use counters or Cloud Functions for counts)

## Collection naming
- `camelCase` for collection names: `users`, `skillLevels`, `userSkills`
- Junction collections follow `entity1_Entity2` pattern: `user_Skills`, `skillLevel_Skills`

## Document IDs
- Auto-generated Firebase IDs for all user-created data (sessions, xpEvents, etc.)
- Fixed IDs for seed data only (disciplines, skills, skillLevels) — use slugs like `discipline_aff`
- Never use email or sequential integers as document IDs

## Timestamps
Always use server timestamps, never client clock:
```typescript
// TypeScript (Functions)
meta: { createdAt: admin.firestore.FieldValue.serverTimestamp() }

// Dart (Flutter)
'createdAt': FieldValue.serverTimestamp()
```

## Repository pattern (Flutter)

Flutter never calls Firestore directly. All Firestore access goes through a repository interface defined in the domain layer.

```dart
// domain/repositories/session_repository.dart
abstract class SessionRepository {
  Stream<List<Session>> watchSessions(String userId);
  Future<Either<AppFailure, Session>> logSession(SessionInput input);
  Future<Either<AppFailure, Session>> getSession(String sessionId);
}

// data/repositories/session_repository_impl.dart
class SessionRepositoryImpl implements SessionRepository {
  final FirebaseFirestore _db;
  SessionRepositoryImpl(this._db);

  @override
  Stream<List<Session>> watchSessions(String userId) {
    return _db
        .collection('sessions')
        .where('flyerIds', arrayContains: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SessionModel.fromFirestore(doc).toEntity())
            .toList());
  }
}
```

## Models — Firestore ↔ Dart

Models live in `data/models/` and handle serialization:
```dart
// data/models/session_model.dart
class SessionModel {
  // ... fields

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      flyerIds: List<String>.from(data['flyerIds'] ?? []),
      // ...
    );
  }

  Map<String, dynamic> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'flyerIds': flyerIds,
    // ...
  };

  Session toEntity() => Session(id: id, date: date, flyerIds: flyerIds);
}
```

## Query design — index first
Firestore requires composite indexes for multi-field queries. Think about queries before designing schema.

Key queries in this app:
```
sessions where flyerIds array-contains userId, ordered by date desc
  → index: flyerIds ASC, date DESC

user_Skills where userId == X
  → no composite index needed (single field)

users where roles array-contains 'coach', where name >= search, name < search+'z'
  → index: roles ASC, name ASC
```

Add indexes to `firestore.indexes.json` — deployed with `firebase deploy --only firestore`.

## Denormalization
Duplicate read-heavy data to avoid multiple fetches. Example: store coach `displayName` on the session document alongside `coachIds` so the session list can render coach names without extra reads.

Only denormalize after profiling — keep data model clean first.

## Seed data
Seed documents are created once at first deploy. The seed script is idempotent — it checks before writing:
```typescript
// src/seed/seedDatabase.ts
async function seedDisciplines() {
  const disciplines: Discipline[] = require('../../seeds/disciplines.json');
  const batch = admin.firestore().batch();

  for (const d of disciplines) {
    const ref = admin.firestore().collection('disciplines').doc(d.id);
    const snap = await ref.get();
    if (!snap.exists) {  // idempotent: only write if missing
      batch.set(ref, d);
    }
  }
  await batch.commit();
}
```

Run via:
```bash
# Against emulator
cd backend/functions && npm run seed

# Against production (first deploy only)
cd backend/functions && npm run seed:prod
```

## Schema versioning and migrations

Firestore has no schema migrations. Strategy:

1. Add a `_schemaVersion` field to documents that may evolve:
   ```json
   { "_schemaVersion": 1, ... }
   ```
2. When schema changes, write a migration script in `backend/functions/scripts/`:
   ```typescript
   // scripts/migrate_sessions_v2.ts
   // Reads all sessions with _schemaVersion < 2, updates them
   ```
3. Run migration manually against prod before deploying new code that expects the new schema
4. Keep old field names readable by new code during transition (read both, write new only)

## Offline strategy (Flutter)
Firestore offline persistence is enabled by default in the Flutter SDK. Key behaviors:
- Writes are queued locally and synced when online
- Reads serve from cache when offline, from server when online
- `source: Source.cache` to force cache read; `source: Source.server` to force network read

Per-entity offline strategy (from DATA_MODEL.md):
| Entity | Offline write | Offline read |
|---|---|---|
| sessions | Yes | Cached on first load |
| user_Skills | Yes | Cached |
| disciplines / skills / skillLevels | No | Permanently cached |
| xpEvents | Queued | Cached |
| teams / camps | No | Cached |

## Pagination
Use cursor-based pagination for lists that may grow large (sessions list):
```dart
Query query = _db.collection('sessions')
    .where('flyerIds', arrayContains: userId)
    .orderBy('date', descending: true)
    .limit(20);

// Next page
query = query.startAfterDocument(lastDocument);
```
