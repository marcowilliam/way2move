import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../../domain/entities/protocol.dart';

class ProtocolModel {
  final String id;
  final String userId;
  final String name;
  final String kind;
  final DateTime startDate;
  final DateTime endDate;
  final int durationWeeks;
  final String prescription;
  final List<String> workoutIds;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String source;
  final String? idempotencyKey;

  const ProtocolModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    required this.startDate,
    required this.endDate,
    required this.durationWeeks,
    required this.prescription,
    required this.workoutIds,
    this.status = 'active',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory ProtocolModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return ProtocolModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      kind: data['kind'] as String? ?? 'physio',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      durationWeeks: (data['durationWeeks'] as num).toInt(),
      prescription: data['prescription'] as String? ?? '',
      workoutIds: (data['workoutIds'] as List<dynamic>? ?? [])
          .map((w) => w as String)
          .toList(),
      status: data['status'] as String? ?? 'active',
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'kind': kind,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'durationWeeks': durationWeeks,
        'prescription': prescription,
        'workoutIds': workoutIds,
        'status': status,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  Protocol toEntity() => Protocol(
        id: id,
        userId: userId,
        name: name,
        kind: _kindFromString(kind),
        startDate: startDate,
        endDate: endDate,
        durationWeeks: durationWeeks,
        prescription: prescription,
        workoutIds: workoutIds,
        status: _statusFromString(status),
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory ProtocolModel.fromEntity(Protocol p) => ProtocolModel(
        id: p.id,
        userId: p.userId,
        name: p.name,
        kind: p.kind.name,
        startDate: p.startDate,
        endDate: p.endDate,
        durationWeeks: p.durationWeeks,
        prescription: p.prescription,
        workoutIds: p.workoutIds,
        status: p.status.name,
        notes: p.notes,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      );

  static ProtocolKind _kindFromString(String s) =>
      ProtocolKind.values.firstWhere(
        (k) => k.name == s,
        orElse: () => ProtocolKind.physio,
      );

  static ProtocolStatus _statusFromString(String s) =>
      ProtocolStatus.values.firstWhere(
        (k) => k.name == s,
        orElse: () => ProtocolStatus.active,
      );
}
