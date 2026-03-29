import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/features/programs/domain/entities/program.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/usecases/generate_session_from_program.dart';

void main() {
  late GenerateSessionFromProgram generate;

  // Monday = weekday index 0 in our scheme (DateTime.weekday is 1=Mon)
  final tMonday = DateTime(2026, 3, 30); // a Monday

  const tExerciseEntry = ExerciseEntry(
    exerciseId: 'ex_deadbug',
    sets: 3,
    reps: '10',
  );

  const tTrainingDay = DayTemplate(
    focus: 'Core & Breathing',
    exerciseEntries: [tExerciseEntry],
    isRestDay: false,
  );

  const tRestDay = DayTemplate.rest;

  final tProgram = Program(
    id: 'p1',
    userId: 'user1',
    name: 'Corrective Program',
    goal: 'Fix posture',
    durationWeeks: 8,
    weekTemplate: const WeekTemplate(days: {
      0: tTrainingDay, // Monday
      1: tRestDay, // Tuesday
      2: tTrainingDay, // Wednesday
      3: tRestDay,
      4: tTrainingDay, // Friday
      5: tRestDay,
      6: tRestDay,
    }),
    isActive: true,
    createdAt: DateTime(2026, 3, 1),
  ); // ignore: prefer_const_constructors — createdAt is not const

  setUp(() {
    generate = const GenerateSessionFromProgram();
  });

  group('GenerateSessionFromProgram', () {
    test('returns Session with exercise blocks on a training day', () {
      final result = generate(tProgram, 'user1', tMonday);

      expect(result, isNotNull);
      expect(result!.userId, 'user1');
      expect(result.programId, 'p1');
      expect(result.focus, 'Core & Breathing');
      expect(result.status, SessionStatus.planned);
      expect(result.exerciseBlocks.length, 1);
      expect(result.exerciseBlocks.first.exerciseId, 'ex_deadbug');
      expect(result.exerciseBlocks.first.plannedSets, 3);
      expect(result.exerciseBlocks.first.plannedReps, '10');
      expect(result.exerciseBlocks.first.actualSets, isEmpty);
    });

    test('returns null on a rest day', () {
      final tuesday = DateTime(2026, 3, 31);
      final result = generate(tProgram, 'user1', tuesday);
      expect(result, isNull);
    });

    test('date field on generated session matches input date', () {
      final result = generate(tProgram, 'user1', tMonday);
      expect(result, isNotNull);
      expect(result!.date.year, tMonday.year);
      expect(result.date.month, tMonday.month);
      expect(result.date.day, tMonday.day);
    });

    test('generated session id is empty (not yet persisted)', () {
      final result = generate(tProgram, 'user1', tMonday);
      expect(result, isNotNull);
      expect(result!.id, isEmpty);
    });

    test('program with no training days returns null for any day', () {
      final allRestProgram = Program(
        id: 'p2',
        userId: 'user1',
        name: 'Rest Program',
        goal: 'Rest',
        durationWeeks: 1,
        weekTemplate: WeekTemplate.empty(),
        isActive: true,
        createdAt: DateTime(2026, 3, 1),
      );

      final result = generate(allRestProgram, 'user1', tMonday);
      expect(result, isNull);
    });
  });
}
