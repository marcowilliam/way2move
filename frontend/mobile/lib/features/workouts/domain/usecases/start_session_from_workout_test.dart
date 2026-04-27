import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/sessions/domain/entities/session.dart';
import 'package:way2move/features/sessions/domain/repositories/session_repository.dart';
import 'package:way2move/features/workouts/domain/entities/workout.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';
import 'package:way2move/features/workouts/domain/usecases/start_session_from_workout.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  late MockSessionRepository mockSessionRepo;
  late StartSessionFromWorkout startSession;

  const tWarmupBlock = ExerciseBlock(
    exerciseId: 'supine-dns-breathing',
    plannedSets: 2,
    plannedReps: '5-6 breaths',
    phase: ExercisePhase.warmup,
    level: ExerciseLevel.access,
    order: 1,
  );
  const tMainBlock = ExerciseBlock(
    exerciseId: 'quadruped-arm-lift',
    plannedSets: 3,
    plannedReps: '6/side',
    phase: ExercisePhase.main,
    level: ExerciseLevel.foundation,
    order: 5,
  );
  const tParkedBlock = ExerciseBlock(
    exerciseId: 'active-hang',
    plannedSets: 4,
    plannedReps: '15-30s',
    phase: ExercisePhase.main,
    level: ExerciseLevel.strength,
    currentlyIncluded: false, // user hasn't unlocked this yet
  );

  const tWorkout = Workout(
    id: 'day-a',
    userId: 'user1',
    name: 'DAY A — Anterior Chain',
    kind: WorkoutKind.abcde,
    focus: 'Anterior chain + flexion',
    estimatedMinutes: 90,
    exerciseBlocks: [tWarmupBlock, tMainBlock, tParkedBlock],
  );

  setUp(() {
    mockSessionRepo = MockSessionRepository();
    startSession = StartSessionFromWorkout(mockSessionRepo);
    registerFallbackValue(Session(
      id: '_',
      userId: '_',
      date: DateTime(2026),
      status: SessionStatus.planned,
      exerciseBlocks: const [],
    ));
  });

  group('StartSessionFromWorkout', () {
    test('creates a session that copies workout name, kind, and blocks', () async {
      Session? captured;
      when(() => mockSessionRepo.createSession(any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments.first as Session;
        return Right(captured!);
      });

      await startSession(
        workout: tWorkout,
        userId: 'user1',
        date: DateTime(2026, 4, 27),
        slot: SessionSlot.morning,
      );

      expect(captured, isNotNull);
      expect(captured!.userId, 'user1');
      expect(captured!.workoutId, 'day-a');
      expect(captured!.kind, WorkoutKind.abcde);
      expect(captured!.focus, 'Anterior chain + flexion');
      expect(captured!.slot, SessionSlot.morning);
      expect(captured!.status, SessionStatus.planned);
    });

    test('skips parked (currentlyIncluded=false) blocks by default', () async {
      Session? captured;
      when(() => mockSessionRepo.createSession(any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments.first as Session;
        return Right(captured!);
      });

      await startSession(
        workout: tWorkout,
        userId: 'user1',
        date: DateTime(2026, 4, 27),
        slot: SessionSlot.morning,
      );

      expect(captured!.exerciseBlocks.length, 2);
      expect(
        captured!.exerciseBlocks.map((b) => b.exerciseId).toList(),
        ['supine-dns-breathing', 'quadruped-arm-lift'],
      );
    });

    test('includes parked blocks when includeParked: true', () async {
      Session? captured;
      when(() => mockSessionRepo.createSession(any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments.first as Session;
        return Right(captured!);
      });

      await startSession(
        workout: tWorkout,
        userId: 'user1',
        date: DateTime(2026, 4, 27),
        slot: SessionSlot.morning,
        includeParked: true,
      );

      expect(captured!.exerciseBlocks.length, 3);
    });

    test('derives durationCategory from workout estimatedMinutes', () async {
      Session? captured;
      when(() => mockSessionRepo.createSession(any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments.first as Session;
        return Right(captured!);
      });

      await startSession(
        workout: tWorkout, // 90 min → long
        userId: 'user1',
        date: DateTime(2026, 4, 27),
        slot: SessionSlot.morning,
      );

      expect(captured!.durationCategory, DurationCategory.long);
    });

    test('passes optional place through to the session', () async {
      Session? captured;
      when(() => mockSessionRepo.createSession(any()))
          .thenAnswer((inv) async {
        captured = inv.positionalArguments.first as Session;
        return Right(captured!);
      });

      await startSession(
        workout: tWorkout,
        userId: 'user1',
        date: DateTime(2026, 4, 27),
        slot: SessionSlot.morning,
        place: 'Econofitness',
      );

      expect(captured!.place, 'Econofitness');
    });
  });
}
