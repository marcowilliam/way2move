import 'package:way2move/features/programs/domain/entities/program.dart';
import '../entities/session.dart';

/// Generates a planned [Session] for [date] based on the active [program]'s
/// week template. Returns null when [date] is a rest day.
class GenerateSessionFromProgram {
  const GenerateSessionFromProgram();

  Session? call(Program program, String userId, DateTime date) {
    // DateTime.weekday: 1 = Monday … 7 = Sunday → convert to 0-indexed
    final dayIndex = date.weekday - 1;
    final dayTemplate = program.weekTemplate.days[dayIndex];

    if (dayTemplate == null || dayTemplate.isRestDay) return null;

    final blocks = dayTemplate.exerciseEntries
        .map(
          (entry) => ExerciseBlock(
            exerciseId: entry.exerciseId,
            plannedSets: entry.sets,
            plannedReps: entry.reps,
          ),
        )
        .toList();

    return Session(
      id: '',
      userId: userId,
      programId: program.id,
      focus: dayTemplate.focus,
      date: DateTime(date.year, date.month, date.day),
      status: SessionStatus.planned,
      exerciseBlocks: blocks,
    );
  }
}
