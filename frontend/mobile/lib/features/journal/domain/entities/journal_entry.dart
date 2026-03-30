enum JournalType {
  morningCheckIn,
  preSession,
  postSession,
  eveningReflection,
  general,
}

class JournalEntry {
  final String id;
  final String userId;
  final DateTime date;
  final JournalType type;
  final String content;
  final String? audioUrl;
  final int? mood; // 1-5
  final int? energyLevel; // 1-5
  final List<String> painPoints;
  final String? linkedSessionId;
  final List<String> autoCreatedEntities;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.content,
    this.audioUrl,
    this.mood,
    this.energyLevel,
    this.painPoints = const [],
    this.linkedSessionId,
    this.autoCreatedEntities = const [],
  });

  JournalEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    JournalType? type,
    String? content,
    String? audioUrl,
    int? mood,
    int? energyLevel,
    List<String>? painPoints,
    String? linkedSessionId,
    List<String>? autoCreatedEntities,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      type: type ?? this.type,
      content: content ?? this.content,
      audioUrl: audioUrl ?? this.audioUrl,
      mood: mood ?? this.mood,
      energyLevel: energyLevel ?? this.energyLevel,
      painPoints: painPoints ?? this.painPoints,
      linkedSessionId: linkedSessionId ?? this.linkedSessionId,
      autoCreatedEntities: autoCreatedEntities ?? this.autoCreatedEntities,
    );
  }

  @override
  bool operator ==(Object other) => other is JournalEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
