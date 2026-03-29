import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/compensation.dart';

class CompensationHistoryEntryModel {
  final DateTime date;
  final CompensationSeverity severity;
  final CompensationStatus status;
  final String note;

  const CompensationHistoryEntryModel({
    required this.date,
    required this.severity,
    required this.status,
    required this.note,
  });

  factory CompensationHistoryEntryModel.fromMap(Map<String, dynamic> map) {
    return CompensationHistoryEntryModel(
      date: (map['date'] as Timestamp).toDate(),
      severity: _parseSeverity(map['severity'] as String),
      status: _parseStatus(map['status'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'severity': severity.name,
        'status': status.name,
        'note': note,
      };

  CompensationHistoryEntry toEntity() => CompensationHistoryEntry(
        date: date,
        severity: severity,
        status: status,
        note: note,
      );

  factory CompensationHistoryEntryModel.fromEntity(
      CompensationHistoryEntry entry) {
    return CompensationHistoryEntryModel(
      date: entry.date,
      severity: entry.severity,
      status: entry.status,
      note: entry.note,
    );
  }
}

class CompensationModel {
  final String id;
  final String userId;
  final String name;
  final CompensationType type;
  final CompensationRegion region;
  final CompensationSeverity severity;
  final CompensationStatus status;
  final CompensationSource source;
  final List<String> relatedGoalIds;
  final List<String> relatedExerciseIds;
  final List<CompensationHistoryEntryModel> history;
  final DateTime detectedAt;
  final DateTime? resolvedAt;

  const CompensationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.region,
    required this.severity,
    required this.status,
    required this.source,
    required this.relatedGoalIds,
    required this.relatedExerciseIds,
    required this.history,
    required this.detectedAt,
    this.resolvedAt,
  });

  factory CompensationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompensationModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      type: _parseType(data['type'] as String),
      region: _parseRegion(data['region'] as String),
      severity: _parseSeverity(data['severity'] as String),
      status: _parseStatus(data['status'] as String),
      source: _parseSource(data['source'] as String),
      relatedGoalIds: List<String>.from(data['relatedGoalIds'] ?? []),
      relatedExerciseIds: List<String>.from(data['relatedExerciseIds'] ?? []),
      history: ((data['history'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>()
          .map(CompensationHistoryEntryModel.fromMap)
          .toList(),
      detectedAt: (data['detectedAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'type': type.name,
        'region': region.name,
        'severity': severity.name,
        'status': status.name,
        'source': source.name,
        'relatedGoalIds': relatedGoalIds,
        'relatedExerciseIds': relatedExerciseIds,
        'history': history.map((h) => h.toMap()).toList(),
        'detectedAt': Timestamp.fromDate(detectedAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'meta': {
          'updatedAt': FieldValue.serverTimestamp(),
        },
        '_schemaVersion': 1,
      };

  Compensation toEntity() => Compensation(
        id: id,
        userId: userId,
        name: name,
        type: type,
        region: region,
        severity: severity,
        status: status,
        source: source,
        relatedGoalIds: relatedGoalIds,
        relatedExerciseIds: relatedExerciseIds,
        history: history.map((h) => h.toEntity()).toList(),
        detectedAt: detectedAt,
        resolvedAt: resolvedAt,
      );

  factory CompensationModel.fromEntity(Compensation entity) {
    return CompensationModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      type: entity.type,
      region: entity.region,
      severity: entity.severity,
      status: entity.status,
      source: entity.source,
      relatedGoalIds: entity.relatedGoalIds,
      relatedExerciseIds: entity.relatedExerciseIds,
      history:
          entity.history.map(CompensationHistoryEntryModel.fromEntity).toList(),
      detectedAt: entity.detectedAt,
      resolvedAt: entity.resolvedAt,
    );
  }
}

// Parse helpers
CompensationType _parseType(String s) =>
    CompensationType.values.firstWhere((e) => e.name == s,
        orElse: () => CompensationType.posturalPattern);

CompensationRegion _parseRegion(String s) => CompensationRegion.values
    .firstWhere((e) => e.name == s, orElse: () => CompensationRegion.core);

CompensationSeverity _parseSeverity(String s) => CompensationSeverity.values
    .firstWhere((e) => e.name == s, orElse: () => CompensationSeverity.mild);

CompensationStatus _parseStatus(String s) => CompensationStatus.values
    .firstWhere((e) => e.name == s, orElse: () => CompensationStatus.active);

CompensationSource _parseSource(String s) => CompensationSource.values
    .firstWhere((e) => e.name == s, orElse: () => CompensationSource.manual);
