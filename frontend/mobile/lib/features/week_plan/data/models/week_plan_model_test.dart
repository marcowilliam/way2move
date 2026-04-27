import 'package:flutter_test/flutter_test.dart';

import '../../../workouts/domain/entities/workout_enums.dart';
import '../../domain/entities/week_plan.dart';
import 'week_plan_model.dart';

void main() {
  group('WeekPlanModel', () {
    test('round-trip preserves intent, focusAreas, plannedSlots', () {
      final plan = WeekPlan(
        id: 'u1_2026-W18',
        userId: 'u1',
        isoYearWeek: '2026-W18',
        startDate: DateTime.utc(2026, 4, 27),
        endDate: DateTime.utc(2026, 5, 4),
        intent: 'Alignment + body awareness',
        focusAreas: const ['eyes', 'neck', 'si_joint'],
        plannedSlots: const [
          PlannedSlot(
            day: 1,
            slot: SessionSlot.afternoon,
            workoutId: 'day-a',
            autoAssigned: true,
          ),
          PlannedSlot(
            day: 2,
            slot: SessionSlot.morning,
            workoutId: 'snack-cranium',
          ),
        ],
      );

      final map = WeekPlanModel.fromEntity(plan).toFirestore();
      expect(map['intent'], 'Alignment + body awareness');
      expect(map['focusAreas'], ['eyes', 'neck', 'si_joint']);

      final slots = map['plannedSlots'] as List;
      expect(slots.length, 2);
      expect((slots[0] as Map)['slot'], 'afternoon');
      expect((slots[0] as Map)['autoAssigned'], true);
      expect((slots[1] as Map)['slot'], 'morning');
      expect((slots[1] as Map)['autoAssigned'], false);
    });
  });
}
