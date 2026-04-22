import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/weight_log.dart';

class WeightLogModel {
  final String id;
  final String userId;
  final DateTime date;
  final double weight;
  final String unit;
  final String? notes;
  final String source;
  final String? idempotencyKey;

  const WeightLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.unit,
    this.notes,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory WeightLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return WeightLogModel(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      unit: data['unit'] as String,
      notes: data['notes'] as String?,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  factory WeightLogModel.fromEntity(WeightLog log) {
    return WeightLogModel(
      id: log.id,
      userId: log.userId,
      date: log.date,
      weight: log.weight,
      unit: log.unit.name,
      notes: log.notes,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'weight': weight,
        'unit': unit,
        if (notes != null) 'notes': notes,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  WeightLog toEntity() => WeightLog(
        id: id,
        userId: userId,
        date: date,
        weight: weight,
        unit: _parseUnit(unit),
        notes: notes,
      );

  static WeightUnit _parseUnit(String value) {
    return WeightUnit.values.firstWhere(
      (u) => u.name == value,
      orElse: () => WeightUnit.kg,
    );
  }
}
