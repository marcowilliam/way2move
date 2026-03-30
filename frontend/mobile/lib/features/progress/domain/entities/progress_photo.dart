enum PhotoAngle { front, sideLeft, sideRight, back }

class ProgressPhoto {
  final String id;
  final String userId;
  final DateTime date;
  final String photoUrl;
  final PhotoAngle angle;
  final String? notes;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.date,
    required this.photoUrl,
    required this.angle,
    this.notes,
  });

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? photoUrl,
    PhotoAngle? angle,
    String? notes,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      photoUrl: photoUrl ?? this.photoUrl,
      angle: angle ?? this.angle,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressPhoto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          date == other.date &&
          photoUrl == other.photoUrl &&
          angle == other.angle &&
          notes == other.notes;

  @override
  int get hashCode => Object.hash(id, userId, date, photoUrl, angle, notes);
}
