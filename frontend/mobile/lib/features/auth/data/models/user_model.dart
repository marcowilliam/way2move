import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/data/assistant_meta.dart';
import '../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final DateTime createdAt;
  final String source;
  final String? idempotencyKey;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.createdAt,
    this.source = WriteSource.inAppTyped,
    this.idempotencyKey,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final meta = readAssistantMeta(data);
    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      createdAt: data['meta'] != null &&
              (data['meta'] as Map<String, dynamic>)['createdAt'] != null
          ? ((data['meta'] as Map<String, dynamic>)['createdAt'] as Timestamp)
              .toDate()
          : DateTime.now(),
      source: meta.source,
      idempotencyKey: meta.idempotencyKey,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'meta': {
          'createdAt': Timestamp.fromDate(createdAt),
        },
        ...writeAssistantMeta(source: source, idempotencyKey: idempotencyKey),
      };

  AppUser toEntity() => AppUser(
        id: id,
        email: email,
        name: name,
        avatarUrl: avatarUrl,
        createdAt: createdAt,
      );

  factory UserModel.fromEntity(AppUser user) => UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl,
        createdAt: user.createdAt,
      );
}
