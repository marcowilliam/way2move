import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../workouts/domain/entities/workout.dart';
import '../../../workouts/domain/entities/workout_enums.dart';
import '../../../workouts/domain/repositories/workout_repository.dart';
import '../entities/protocol.dart';
import '../repositories/protocol_repository.dart';

/// Creates the canonical "From the Ground Up" workout + active protocol for
/// the given user, idempotently. Safe to call repeatedly — re-runs become
/// no-ops once the workout exists.
///
/// Hand-written from Marco's physio prescription (2026-04-26 chat). The
/// full Notion-CSV import that brings in ABCDE / Snacks / Bodybuilding is
/// deferred to a separate Cloud Function script.
class SeedGroundUpForUser {
  final WorkoutRepository _workouts;
  final ProtocolRepository _protocols;

  SeedGroundUpForUser(this._workouts, this._protocols);

  static const String workoutDocId = 'ground-up';

  Future<Either<AppFailure, Protocol>> call({
    required String userId,
    required DateTime startDate,
  }) async {
    final existingWorkout = await _workouts.getWorkoutById(workoutDocId);
    final hasWorkout = existingWorkout.isRight();

    if (!hasWorkout) {
      final created = await _workouts.createWorkout(_buildWorkout(userId));
      final failure = created.fold((f) => f, (_) => null);
      if (failure != null) return Left(failure);
    }

    final activeRes = await _protocols.getActiveProtocols(userId);
    final activeFailure = activeRes.fold((f) => f, (_) => null);
    if (activeFailure != null) return Left(activeFailure);

    final active = activeRes.getOrElse((_) => const []);
    final existing =
        active.where((p) => p.workoutIds.contains(workoutDocId)).toList();
    if (existing.isNotEmpty) return Right(existing.first);

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = start.add(const Duration(days: 42));
    final protocol = Protocol(
      id: '',
      userId: userId,
      name: 'From the Ground Up',
      kind: ProtocolKind.physio,
      startDate: start,
      endDate: end,
      durationWeeks: 6,
      prescription: 'All exercises every day, 1 set each, 6 weeks.',
      workoutIds: const [workoutDocId],
      status: ProtocolStatus.active,
      notes: 'Physio prescription — daily routine. Pinned on Today as a '
          'persistent card with X-of-Y progress.',
      createdAt: DateTime.now(),
    );
    return _protocols.createProtocol(protocol);
  }

  Workout _buildWorkout(String userId) {
    return Workout(
      id: workoutDocId,
      userId: userId,
      name: 'From the Ground Up',
      kind: WorkoutKind.fromGroundUp,
      focus: 'Foot, hip, posterior chain',
      planeTags: const ['sagittal', 'frontal'],
      intentTags: const [
        'foot awareness',
        'hip extension',
        'posterior capsule',
      ],
      iconEmoji: '🌱',
      estimatedMinutes: 25,
      exerciseBlocks: _buildBlocks(),
      notes: 'All exercises every day, 1 set each, 6 weeks. Hand-written from '
          'physio prescription dated 2026-04-26.',
      createdAt: DateTime.now(),
    );
  }

  List<ExerciseBlock> _buildBlocks() => const [
        ExerciseBlock(
          exerciseId: 'gu-foam-roller-bridge',
          plannedSets: 1,
          plannedReps: '15-30s',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Foam Roller Bridge — Double Legged',
          directions: '1-2 sets of 15-30s',
          cuesOverride: [
            'Jelly belly — roll pelvis backward to flatten lower back without using abs',
            'Squash an orange under your arch as you lift the foot',
            'Lift hips just enough to slide a credit card under your bum',
            'Push through inside edge of foot — knee tracks toward midline',
          ],
          currentlyIncluded: true,
          order: 1,
          plannedSeconds: 30,
        ),
        ExerciseBlock(
          exerciseId: 'gu-single-leg-midfoot-bridge',
          plannedSets: 1,
          plannedReps: '30-45s/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Single-Leg Midfoot Bridge (opposite knee to chest)',
          directions: '1-2 sets of 30-45s per side',
          cuesOverride: [
            'Sock under arch — keep contact with inner edge of foot',
            'Foot away from bum — heel barely lifting off the floor',
          ],
          currentlyIncluded: true,
          order: 2,
          plannedSeconds: 45,
        ),
        ExerciseBlock(
          exerciseId: 'gu-calf-bridge',
          plannedSets: 1,
          plannedReps: '15-30s/leg',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Calf Bridge',
          directions: '1-2 sets x 15-30s per leg',
          cuesOverride: ['Push through ball of big toe'],
          currentlyIncluded: true,
          order: 3,
          plannedSeconds: 30,
        ),
        ExerciseBlock(
          exerciseId: 'gu-side-lying-scissor-slides',
          plannedSets: 1,
          plannedReps: '10/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Side-lying Scissor Slides — both directions',
          directions: '1 set of 10 reps per side, last rep 3-5 breaths',
          cuesOverride: ['Pull back with top heel, no bum activation'],
          currentlyIncluded: true,
          order: 4,
        ),
        ExerciseBlock(
          exerciseId: 'gu-half-kneeling-adductor-pullback',
          plannedSets: 1,
          plannedReps: '5 breaths + 5 reps',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Half-Kneeling Adductor Pullback',
          directions: '5 breaths at end range, then 5 reps',
          cuesOverride: ['Knee in front of ankle', 'Pull lead heel back'],
          currentlyIncluded: true,
          order: 5,
        ),
        ExerciseBlock(
          exerciseId: 'gu-posterior-capsule-stretch',
          plannedSets: 2,
          plannedReps: '5-10 breaths/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Posterior Capsule Stretch — stay upright',
          directions: '2 sets of 5-10 breaths per side',
          cuesOverride: ['Slide pelvis toward stretching butt'],
          currentlyIncluded: true,
          order: 6,
        ),
        ExerciseBlock(
          exerciseId: 'gu-coiling-posterior-capsule-stretch',
          plannedSets: 2,
          plannedReps: '5-10 breaths/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Coiling Core POSTERIOR Capsule Stretch',
          directions: '2 sets of 5-10 breaths per side',
          cuesOverride: ['Same setup + coiling cue through the core'],
          currentlyIncluded: true,
          order: 7,
        ),
        ExerciseBlock(
          exerciseId: 'gu-coiling-posterior-lateral-hip-stretch',
          plannedSets: 2,
          plannedReps: '5-10 breaths/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Coiling Core Posterior LATERAL Hip Capsule Stretch',
          directions: '2 sets of 5-10 breaths per side',
          currentlyIncluded: true,
          order: 8,
        ),
        ExerciseBlock(
          exerciseId: 'gu-kickstand-chop',
          plannedSets: 1,
          plannedReps: 'quality reps',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Kickstand Chop (with wedges)',
          directions: 'Quality over count',
          cuesOverride: [
            'Big toe knuckle heavy',
            'Lean opposite shoulder forward',
          ],
          currentlyIncluded: true,
          order: 9,
        ),
        ExerciseBlock(
          exerciseId: 'gu-foot-flattener',
          plannedSets: 1,
          plannedReps: '6 slow reps/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Foot Flattener (back foot off floor)',
          directions: '1-2 sets of 6 slow reps per side',
          cuesOverride: ['HEAVY heel', 'Relaxed toes'],
          currentlyIncluded: true,
          order: 10,
        ),
        ExerciseBlock(
          exerciseId: 'gu-split-stance-contralateral-reach',
          plannedSets: 1,
          plannedReps: '4-8/side',
          phase: ExercisePhase.main,
          level: ExerciseLevel.foundation,
          category: 'Split Stance Contralateral Reach',
          directions: '1-2 sets of 4-8 per side',
          cuesOverride: ['Hip outside foot', 'Inside edge glued'],
          currentlyIncluded: true,
          order: 11,
        ),
      ];
}
