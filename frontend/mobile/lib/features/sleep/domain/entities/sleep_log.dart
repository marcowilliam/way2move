class SleepLog {
  final String id;
  final String userId;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int quality; // 1-5
  final String? notes;
  final DateTime date;

  const SleepLog({
    required this.id,
    required this.userId,
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
    this.notes,
    required this.date,
  });

  Duration get duration => wakeTime.difference(bedTime);

  SleepLog copyWith({
    String? id,
    String? userId,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? quality,
    String? notes,
    DateTime? date,
  }) {
    return SleepLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) => other is SleepLog && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
