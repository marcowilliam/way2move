import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/week_plan/domain/entities/week_plan.dart';
import 'package:way2move/features/week_plan/domain/repositories/week_plan_repository.dart';
import 'package:way2move/features/week_plan/domain/usecases/assign_workout_to_slot.dart';
import 'package:way2move/features/workouts/domain/entities/workout_enums.dart';

class MockWeekPlanRepository extends Mock implements WeekPlanRepository {}

void main() {
  late MockWeekPlanRepository mockRepo;
  late AssignWorkoutToSlot assign;

  final basePlan = WeekPlan(
    id: 'wp1',
    userId: 'user1',
    isoYearWeek: '2026-W18',
    startDate: DateTime(2026, 4, 27),
    endDate: DateTime(2026, 5, 4),
    plannedSlots: [
      const PlannedSlot(
        day: 1,
        slot: SessionSlot.afternoon,
        workoutId: 'day-a',
        autoAssigned: true,
      ),
    ],
  );

  setUp(() {
    mockRepo = MockWeekPlanRepository();
    assign = AssignWorkoutToSlot(mockRepo);
    registerFallbackValue(basePlan);
  });

  test('replaces existing slot for the same day+slot', () async {
    WeekPlan? captured;
    when(() => mockRepo.updateWeekPlan(any())).thenAnswer((inv) async {
      captured = inv.positionalArguments.first as WeekPlan;
      return Right(captured!);
    });

    await assign(
      plan: basePlan,
      day: 1,
      slot: SessionSlot.afternoon,
      workoutId: 'cranium',
    );

    expect(captured!.plannedSlots.length, 1);
    expect(captured!.plannedSlots.first.workoutId, 'cranium');
    expect(captured!.plannedSlots.first.autoAssigned, false);
  });

  test('appends a new slot when no existing slot at day+slot', () async {
    WeekPlan? captured;
    when(() => mockRepo.updateWeekPlan(any())).thenAnswer((inv) async {
      captured = inv.positionalArguments.first as WeekPlan;
      return Right(captured!);
    });

    await assign(
      plan: basePlan,
      day: 2,
      slot: SessionSlot.morning,
      workoutId: 'day-b',
    );

    expect(captured!.plannedSlots.length, 2);
    final newSlot = captured!.plannedSlots.firstWhere((s) => s.day == 2);
    expect(newSlot.slot, SessionSlot.morning);
    expect(newSlot.workoutId, 'day-b');
    expect(newSlot.autoAssigned, false);
  });

  test('clears slot when workoutId is null', () async {
    WeekPlan? captured;
    when(() => mockRepo.updateWeekPlan(any())).thenAnswer((inv) async {
      captured = inv.positionalArguments.first as WeekPlan;
      return Right(captured!);
    });

    await assign(
      plan: basePlan,
      day: 1,
      slot: SessionSlot.afternoon,
      workoutId: null,
    );

    expect(captured!.plannedSlots, isEmpty);
  });
}
