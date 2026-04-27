import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../../../sessions/domain/entities/session.dart';
import '../../../sessions/domain/repositories/session_repository.dart';
import '../entities/workout.dart';
import '../entities/workout_enums.dart';

/// Builds a Session from a Workout template and writes it to the session
/// repository. The Session inherits the workout's blocks, focus, and kind;
/// the caller specifies date, slot, and (optional) place.
///
/// By default parked blocks (currentlyIncluded == false) are skipped — the
/// session reflects what the user is actually working on this week. Pass
/// `includeParked: true` for a "show me everything" run-through.
class StartSessionFromWorkout {
  final SessionRepository _sessionRepo;
  const StartSessionFromWorkout(this._sessionRepo);

  Future<Either<AppFailure, Session>> call({
    required Workout workout,
    required String userId,
    required DateTime date,
    required SessionSlot slot,
    String? place,
    bool includeParked = false,
    String? sessionId,
  }) {
    final blocks = includeParked
        ? workout.exerciseBlocks
        : workout.activeBlocks;

    final session = Session(
      id: sessionId ?? '',
      userId: userId,
      date: date,
      status: SessionStatus.planned,
      exerciseBlocks: blocks,
      workoutId: workout.id,
      kind: workout.kind,
      slot: slot,
      durationCategory: _categorize(workout.estimatedMinutes),
      place: place,
      focus: workout.focus,
      durationMinutes: workout.estimatedMinutes,
    );

    return _sessionRepo.createSession(session);
  }

  static DurationCategory? _categorize(int? minutes) {
    if (minutes == null) return null;
    if (minutes < 15) return DurationCategory.snack;
    if (minutes < 30) return DurationCategory.short;
    if (minutes < 60) return DurationCategory.medium;
    return DurationCategory.long;
  }
}
