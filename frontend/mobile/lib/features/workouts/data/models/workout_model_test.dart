import 'package:flutter_test/flutter_test.dart';

import '../../../sessions/domain/entities/session.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_enums.dart';
import 'workout_model.dart';

void main() {
  group('WorkoutModel', () {
    test('round-trip preserves all fields including extended ExerciseBlock',
        () {
      const workout = Workout(
        id: 'ground-up',
        userId: 'user-1',
        name: 'From the Ground Up',
        kind: WorkoutKind.fromGroundUp,
        focus: 'Foot, hip, posterior chain',
        planeTags: ['sagittal', 'frontal'],
        intentTags: ['arch awareness', 'glute med'],
        color: '#C4622D',
        iconEmoji: '🌱',
        estimatedMinutes: 25,
        exerciseBlocks: [
          ExerciseBlock(
            exerciseId: 'foam-roller-bridge',
            plannedSets: 2,
            plannedReps: '15-30s',
            phase: ExercisePhase.main,
            level: ExerciseLevel.foundation,
            category: 'Hip extension',
            directions: '1-2 sets of 15-30s',
            cuesOverride: ['Jelly belly', 'Roll pelvis backwards'],
            currentlyIncluded: true,
            order: 1,
            plannedSeconds: 30,
          ),
        ],
        notes: 'All exercises every day, 1 set each, 6 weeks.',
      );

      final model = WorkoutModel.fromEntity(workout);
      final map = model.toFirestore();

      expect(map['name'], 'From the Ground Up');
      expect(map['kind'], 'fromGroundUp');
      expect(map['planeTags'], ['sagittal', 'frontal']);
      expect(map['source'], 'in-app-typed');

      final block = (map['exerciseBlocks'] as List).first as Map;
      expect(block['phase'], 'main');
      expect(block['level'], 'foundation');
      expect(block['cuesOverride'], ['Jelly belly', 'Roll pelvis backwards']);
      expect(block['currentlyIncluded'], true);
    });

    test('parked block (currentlyIncluded == false) round-trips correctly', () {
      const workout = Workout(
        id: 'w1',
        userId: 'u1',
        name: 'A',
        kind: WorkoutKind.abcde,
        exerciseBlocks: [
          ExerciseBlock(
            exerciseId: 'parked',
            plannedSets: 3,
            plannedReps: '10',
            currentlyIncluded: false,
          ),
        ],
      );

      final roundTripped =
          WorkoutModel.fromEntity(workout).toFirestore()['exerciseBlocks'];
      final parked = (roundTripped as List).first as Map;
      expect(parked['currentlyIncluded'], false);
    });
  });
}
