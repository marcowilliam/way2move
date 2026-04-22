import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/progress_photo.dart';

class ProgressPhotoModel {
  final String id;
  final String userId;
  final DateTime date;
  final String photoUrl;
  final String angle;
  final String? notes;
  final String source;
  final String? idempotencyKey;

  const ProgressPhotoModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.photoUrl,
    required this.angle,
    this.notes,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory ProgressPhotoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return ProgressPhotoModel(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'] as String,
      angle: data['angle'] as String,
      notes: data['notes'] as String?,
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  factory ProgressPhotoModel.fromEntity(ProgressPhoto photo) {
    return ProgressPhotoModel(
      id: photo.id,
      userId: photo.userId,
      date: photo.date,
      photoUrl: photo.photoUrl,
      angle: photo.angle.name,
      notes: photo.notes,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'photoUrl': photoUrl,
        'angle': angle,
        if (notes != null) 'notes': notes,
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  ProgressPhoto toEntity() => ProgressPhoto(
        id: id,
        userId: userId,
        date: date,
        photoUrl: photoUrl,
        angle: _parseAngle(angle),
        notes: notes,
      );

  static PhotoAngle _parseAngle(String value) {
    return PhotoAngle.values.firstWhere(
      (a) => a.name == value,
      orElse: () => PhotoAngle.front,
    );
  }
}
