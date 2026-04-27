import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/week_plan/domain/entities/week_plan.dart';
import 'package:way2move/features/week_plan/domain/repositories/week_plan_repository.dart';
import 'package:way2move/features/week_plan/domain/usecases/get_or_create_current_week_plan.dart';
import 'package:way2move/features/workouts/domain/entities/workout.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';
import 'package:way2move/features/workouts/domain/repositories/workout_repository.dart';

class MockWeekPlanRepository extends Mock implements WeekPlanRepository {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late MockWeekPlanRepository mockWeekPlanRepo;
  late MockWorkoutRepository mockWorkoutRepo;
  late GetOrCreateCurrentWeekPlan getOrCreate;

  // Monday April 27, 2026 (ISO 2026-W18) — used as "today" anchor.
  final tNow = DateTime(2026, 4, 27);

  const tDayA = Workout(
    id: 'day-a',
    userId: 'user1',
    name: 'DAY A',
    kind: WorkoutKind.abcde,
  );
  const tDayB = Workout(
    id: 'day-b',
    userId: 'user1',
    name: 'DAY B',
    kind: WorkoutKind.abcde,
  );
  const tDayC = Workout(
    id: 'day-c',
    userId: 'user1',
    name: 'DAY C',
    kind: WorkoutKind.abcde,
  );
  const tDayD = Workout(
    id: 'day-d',
    userId: 'user1',
    name: 'DAY D',
    kind: WorkoutKind.abcde,
  );
  const tDayE = Workout(
    id: 'day-e',
    userId: 'user1',
    name: 'DAY E',
    kind: WorkoutKind.abcde,
  );

  setUp(() {
    mockWeekPlanRepo = MockWeekPlanRepository();
    mockWorkoutRepo = MockWorkoutRepository();
    getOrCreate = GetOrCreateCurrentWeekPlan(
      weekPlanRepo: mockWeekPlanRepo,
      workoutRepo: mockWorkoutRepo,
    );
    registerFallbackValue(WeekPlan(
      id: '_',
      userId: '_',
      isoYearWeek: '_',
      startDate: DateTime(2026),
      endDate: DateTime(2026, 1, 8),
    ));
  });

  test('returns existing week plan without creating a new one', () async {
    final existing = WeekPlan(
      id: 'wp1',
      userId: 'user1',
      isoYearWeek: '2026-W18',
      startDate: DateTime(2026, 4, 27),
      endDate: DateTime(2026, 5, 4),
      intent: 'alignment',
    );
    when(() => mockWeekPlanRepo.getWeekPlan('user1', '2026-W18'))
        .thenAnswer((_) async => Right(existing));

    final result = await getOrCreate(userId: 'user1', now: tNow);

    expect(result, Right<AppFailure, WeekPlan>(existing));
    verifyNever(() => mockWeekPlanRepo.createWeekPlan(any()));
  });

  test('creates a new week plan with auto Mon-Fri ABCDE assignment', () async {
    when(() => mockWeekPlanRepo.getWeekPlan('user1', '2026-W18'))
        .thenAnswer((_) async => const Right(null));
    when(() => mockWorkoutRepo.getWorkouts('user1', kind: WorkoutKind.abcde))
        .thenAnswer(
            (_) async => const Right([tDayA, tDayB, tDayC, tDayD, tDayE]));

    WeekPlan? captured;
    when(() => mockWeekPlanRepo.createWeekPlan(any())).thenAnswer((inv) async {
      captured = inv.positionalArguments.first as WeekPlan;
      return Right(captured!);
    });

    final result = await getOrCreate(userId: 'user1', now: tNow);

    expect(result.isRight(), true);
    expect(captured, isNotNull);
    expect(captured!.isoYearWeek, '2026-W18');
    expect(captured!.startDate, DateTime(2026, 4, 27));
    expect(captured!.endDate, DateTime(2026, 5, 4));
    expect(captured!.plannedSlots.length, 5);

    final byDay = {for (final s in captured!.plannedSlots) s.day: s};
    expect(byDay[1]?.workoutId, 'day-a');
    expect(byDay[2]?.workoutId, 'day-b');
    expect(byDay[3]?.workoutId, 'day-c');
    expect(byDay[4]?.workoutId, 'day-d');
    expect(byDay[5]?.workoutId, 'day-e');
    expect(byDay[1]?.autoAssigned, true);
    expect(byDay[1]?.slot, SessionSlot.afternoon);
  });

  test('creates an empty week plan when user has fewer than 5 ABCDE workouts',
      () async {
    when(() => mockWeekPlanRepo.getWeekPlan('user1', '2026-W18'))
        .thenAnswer((_) async => const Right(null));
    when(() => mockWorkoutRepo.getWorkouts('user1', kind: WorkoutKind.abcde))
        .thenAnswer((_) async => const Right([tDayA, tDayB])); // partial

    WeekPlan? captured;
    when(() => mockWeekPlanRepo.createWeekPlan(any())).thenAnswer((inv) async {
      captured = inv.positionalArguments.first as WeekPlan;
      return Right(captured!);
    });

    await getOrCreate(userId: 'user1', now: tNow);

    expect(captured!.plannedSlots.length, 2);
    expect(captured!.plannedSlots[0].workoutId, 'day-a');
    expect(captured!.plannedSlots[1].workoutId, 'day-b');
  });

  test('propagates failure when fetching workouts for auto-fill', () async {
    when(() => mockWeekPlanRepo.getWeekPlan('user1', '2026-W18'))
        .thenAnswer((_) async => const Right(null));
    when(() => mockWorkoutRepo.getWorkouts('user1', kind: WorkoutKind.abcde))
        .thenAnswer((_) async => const Left(ServerFailure('offline')));

    final result = await getOrCreate(userId: 'user1', now: tNow);

    expect(result.isLeft(), true);
    verifyNever(() => mockWeekPlanRepo.createWeekPlan(any()));
  });
}
