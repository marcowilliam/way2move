class ExerciseEntry {
  final String exerciseId;
  final int sets;
  final String reps; // e.g. "10", "30s", "AMRAP"
  final String? notes;

  const ExerciseEntry({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.notes,
  });

  ExerciseEntry copyWith({
    String? exerciseId,
    int? sets,
    String? reps,
    String? notes,
  }) =>
      ExerciseEntry(
        exerciseId: exerciseId ?? this.exerciseId,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
        notes: notes ?? this.notes,
      );

  @override
  bool operator ==(Object other) =>
      other is ExerciseEntry && other.exerciseId == exerciseId;

  @override
  int get hashCode => exerciseId.hashCode;
}

class DayTemplate {
  /// Descriptive focus for the day, e.g. "Core & Breathing".
  final String? focus;
  final List<ExerciseEntry> exerciseEntries;
  final bool isRestDay;

  const DayTemplate({
    this.focus,
    required this.exerciseEntries,
    required this.isRestDay,
  });

  DayTemplate copyWith({
    String? focus,
    List<ExerciseEntry>? exerciseEntries,
    bool? isRestDay,
  }) =>
      DayTemplate(
        focus: focus ?? this.focus,
        exerciseEntries: exerciseEntries ?? this.exerciseEntries,
        isRestDay: isRestDay ?? this.isRestDay,
      );

  static const DayTemplate rest = DayTemplate(
    exerciseEntries: [],
    isRestDay: true,
  );
}

class WeekTemplate {
  /// Key is day-of-week index: 0 = Monday … 6 = Sunday.
  final Map<int, DayTemplate> days;

  const WeekTemplate({required this.days});

  WeekTemplate copyWith({Map<int, DayTemplate>? days}) =>
      WeekTemplate(days: days ?? this.days);

  static WeekTemplate empty() => WeekTemplate(
        days: {for (int i = 0; i < 7; i++) i: DayTemplate.rest},
      );
}

class Program {
  final String id;
  final String userId;
  final String name;
  final String goal;
  final int durationWeeks;
  final WeekTemplate weekTemplate;
  final bool isActive;
  final DateTime createdAt;

  const Program({
    required this.id,
    required this.userId,
    required this.name,
    required this.goal,
    required this.durationWeeks,
    required this.weekTemplate,
    required this.isActive,
    required this.createdAt,
  });

  Program copyWith({
    String? id,
    String? userId,
    String? name,
    String? goal,
    int? durationWeeks,
    WeekTemplate? weekTemplate,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      Program(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        goal: goal ?? this.goal,
        durationWeeks: durationWeeks ?? this.durationWeeks,
        weekTemplate: weekTemplate ?? this.weekTemplate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) => other is Program && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
