import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/sleep_log.dart';

class SleepLogModel {
  final String id;
  final String userId;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int quality;
  final String? notes;
  final DateTime date;
  final String source;
  final String? idempotencyKey;

  const SleepLogModel({
    required this.id,
    required this.userId,
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
    this.notes,
    required this.date,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory SleepLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return SleepLogModel(
      id: doc.id,
      userId: data['userId'] as String,
      bedTime: (data['bedTime'] as Timestamp).toDate(),
      wakeTime: (data['wakeTime'] as Timestamp).toDate(),
      quality: (data['quality'] as num).toInt(),
      notes: data['notes'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'bedTime': Timestamp.fromDate(bedTime),
        'wakeTime': Timestamp.fromDate(wakeTime),
        'quality': quality,
        'notes': notes,
        'date': Timestamp.fromDate(date),
        'meta': {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        '_schemaVersion': 1,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  SleepLog toEntity() => SleepLog(
        id: id,
        userId: userId,
        bedTime: bedTime,
        wakeTime: wakeTime,
        quality: quality,
        notes: notes,
        date: date,
      );

  factory SleepLogModel.fromEntity(SleepLog entity) => SleepLogModel(
        id: entity.id,
        userId: entity.userId,
        bedTime: entity.bedTime,
        wakeTime: entity.wakeTime,
        quality: entity.quality,
        notes: entity.notes,
        date: entity.date,
      );
}
