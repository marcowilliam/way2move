/// Cross-app assistant ingest pattern.
///
/// Every user-writeable Firestore document carries a `source` (provenance) and
/// an optional `idempotencyKey` (dedupe key for assistant-driven writes). Way2Move,
/// Way2Fly, and Way2Save share the same contract so a single assistant can read
/// and write across all three apps without corrupting provenance.
///
/// See `.claude/rules/firebase_backend/assistant_ingest.md` for the full contract.
library;

/// WriteSource enum values. Stored as plain strings in Firestore.
abstract class WriteSource {
  /// User filled a form or tapped buttons in the app.
  static const String inAppTyped = 'in-app-typed';

  /// User dictated via speech-to-text in the app.
  static const String inAppVoice = 'in-app-voice';

  /// Assistant created this doc from an external source (ical import,
  /// screenshot OCR, another app's data, etc.).
  static const String assistantIngest = 'assistant-ingest';

  /// Assistant modified an existing user-created doc.
  static const String assistantEdit = 'assistant-edit';

  static const Set<String> all = {
    inAppTyped,
    inAppVoice,
    assistantIngest,
    assistantEdit,
  };

  static bool isValid(String value) => all.contains(value);
}

/// Metadata attached to every user-writeable document.
class AssistantMeta {
  final String source;
  final String? idempotencyKey;

  const AssistantMeta({
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  /// Default: in-app-typed, no idempotency key.
  static const AssistantMeta defaultMeta = AssistantMeta();
}

/// Produces the map fragment to spread into a `toFirestore()` result:
///
/// ```dart
/// Map<String, dynamic> toFirestore() => {
///   ...otherFields,
///   ...writeAssistantMeta(source: WriteSource.inAppTyped),
/// };
/// ```
Map<String, dynamic> writeAssistantMeta({
  String source = WriteSource.inAppTyped,
  String? idempotencyKey,
}) {
  assert(WriteSource.isValid(source), 'Invalid source value: $source');
  return {
    'source': source,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };
}

/// Reads assistant meta from a Firestore document map. Defaults to
/// `in-app-typed` if `source` is missing — keeps older documents readable.
AssistantMeta readAssistantMeta(Map<String, dynamic> data) {
  final raw = data['source'] as String?;
  return AssistantMeta(
    source: (raw != null && WriteSource.isValid(raw)) ? raw : WriteSource.inAppTyped,
    idempotencyKey: data['idempotencyKey'] as String?,
  );
}
