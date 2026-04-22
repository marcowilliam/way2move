# Firebase Backend — Cross-app Assistant Ingest Pattern

## Why this exists
Way2Move, Way2Fly, and Way2Save feed data into the same cross-app assistant. The assistant reads from and writes to each app's Firestore (Phase 1) and, later, Postgres (Phase 3+). For the assistant to ingest, dedupe, and edit data without corrupting provenance, every user-writeable document in every app carries the same two fields.

## The contract — every user-writeable document has:

```json
{
  "source": "in-app-typed",           // enum, required on write
  "idempotencyKey": "string"          // optional, unique per collection
}
```

### `source` (required, string enum)
Tracks where the document came from. Values:

| Value | Meaning | Who writes it |
|---|---|---|
| `in-app-typed` | User filled a form / tapped buttons in the mobile app | Flutter (default) |
| `in-app-voice` | User dictated via speech-to-text in the app | Flutter (STT flows only) |
| `assistant-ingest` | Assistant created this doc from an external source (ical import, screenshot OCR, another app's data) | Assistant / Admin SDK |
| `assistant-edit` | Assistant modified an existing user-created doc | Assistant / Admin SDK |

Rules:
- Required on `create` — default to `in-app-typed` in Flutter client code if the caller doesn't specify.
- **Immutable on `update`** — security rules deny changes to `source` after the doc is written. Provenance is history, not mutable state.
- Validated by security rules against the enum above.

### `idempotencyKey` (optional, string, ≤ 64 chars)
Lets the assistant safely re-run the same ingest without creating duplicates. The assistant builds the key deterministically (e.g. `meal:hash(externalId)`) and uses it as the lookup before writing: if a doc in the same collection already has that key, update it instead of creating a new one.

Rules:
- Unique per collection (enforced in application code; Firestore has no unique indexes — use a query-before-write pattern in the ingest path).
- **Immutable on `update`** — same as `source`.
- Not present on client-typed docs unless the client has a reason (e.g. offline retry dedupe).

## Where this applies

Every collection that accepts **user or assistant** writes. In Way2Move that means:

```
users                 programs             sessions
assessments           sleepLogs            progressionRules
goals                 compensations        meals
progressPhotos        weightLogs           journals
exercises (custom)    recoveryScores       reAssessmentSchedules
nutritionTargets      videoAnalyses        foodItems (custom)
```

Does **not** apply to:
- Seed / reference data (`exercises` where `isBuiltIn == true`, etc.) — these are deployed by Cloud Functions, not user-written, and don't need provenance tracking.
- Derived / computed data written only by triggers (e.g. xpEvents in Way2Fly) — tag with `source: 'assistant-ingest'` if added by a Cloud Function, since Functions are the server-side writer.

## Flutter implementation
Every `Model.toFirestore()` includes the `source` + `idempotencyKey` fields via the shared helper at `lib/shared/data/assistant_meta.dart`:

```dart
Map<String, dynamic> toFirestore() => {
  'userId': userId,
  // ... other fields ...
  ...writeAssistantMeta(source: WriteSource.inAppTyped),
};
```

See `shared/data/assistant_meta.dart` for the enum constants and helpers.

## Security rules implementation
See `firestore.rules` — the `isValidSource()` and `isAssistantMetaImmutable()` helpers enforce the contract on every `match` block.

## Reading the data
Every `Model.fromFirestore()` reads both fields via `readAssistantMeta(data)` and stores them on the domain entity. The entity can then drive UI ("edited by assistant" badge, etc.) or analytics.
