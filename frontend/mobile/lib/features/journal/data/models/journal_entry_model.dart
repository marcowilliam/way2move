import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/journal_entry.dart';

class JournalEntryModel {
  final String id;
  final String userId;
  final DateTime date;
  final JournalType type;
  final String content;
  final String? audioUrl;
  final int? mood;
  final int? energyLevel;
  final List<String> painPoints;
  final String? linkedSessionId;
  final List<String> autoCreatedEntities;

  const JournalEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.type,
    required this.content,
    this.audioUrl,
    this.mood,
    this.energyLevel,
    required this.painPoints,
    this.linkedSessionId,
    required this.autoCreatedEntities,
  });

  factory JournalEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalEntryModel(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      type: _parseType(data['type'] as String),
      content: data['content'] as String,
      audioUrl: data['audioUrl'] as String?,
      mood: data['mood'] as int?,
      energyLevel: data['energyLevel'] as int?,
      painPoints: List<String>.from(data['painPoints'] ?? []),
      linkedSessionId: data['linkedSessionId'] as String?,
      autoCreatedEntities: List<String>.from(data['autoCreatedEntities'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'type': type.name,
        'content': content,
        'audioUrl': audioUrl,
        'mood': mood,
        'energyLevel': energyLevel,
        'painPoints': painPoints,
        'linkedSessionId': linkedSessionId,
        'autoCreatedEntities': autoCreatedEntities,
        'meta': {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        '_schemaVersion': 1,
      };

  JournalEntry toEntity() => JournalEntry(
        id: id,
        userId: userId,
        date: date,
        type: type,
        content: content,
        audioUrl: audioUrl,
        mood: mood,
        energyLevel: energyLevel,
        painPoints: painPoints,
        linkedSessionId: linkedSessionId,
        autoCreatedEntities: autoCreatedEntities,
      );

  factory JournalEntryModel.fromEntity(JournalEntry entity) =>
      JournalEntryModel(
        id: entity.id,
        userId: entity.userId,
        date: entity.date,
        type: entity.type,
        content: entity.content,
        audioUrl: entity.audioUrl,
        mood: entity.mood,
        energyLevel: entity.energyLevel,
        painPoints: entity.painPoints,
        linkedSessionId: entity.linkedSessionId,
        autoCreatedEntities: entity.autoCreatedEntities,
      );
}

JournalType _parseType(String s) => JournalType.values
    .firstWhere((e) => e.name == s, orElse: () => JournalType.general);
