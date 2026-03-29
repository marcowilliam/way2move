import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../programs/presentation/providers/program_providers.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/session.dart';
import '../../domain/usecases/create_session.dart';
import '../../domain/usecases/generate_session_from_program.dart';
import '../../domain/usecases/get_session_history.dart';
import '../../domain/usecases/update_session.dart';

// ── Today's sessions (real-time stream) ──────────────────────────────────────

final todaySessionsProvider = StreamProvider<List<Session>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  final repo = ref.watch(sessionRepositoryProvider);
  final today = DateTime.now();
  return repo.watchSessionsByDate(userId, today);
});

// ── Session history ───────────────────────────────────────────────────────────

class SessionHistoryNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    final result = await GetSessionHistory(
      ref.read(sessionRepositoryProvider),
    )(userId);
    return result.fold((_) => [], (sessions) => sessions);
  }
}

final sessionHistoryProvider =
    AsyncNotifierProvider<SessionHistoryNotifier, List<Session>>(
  SessionHistoryNotifier.new,
);

// ── Active session state (in-progress workout) ────────────────────────────────

class ActiveSessionState {
  final Session session;
  final bool isSubmitting;

  const ActiveSessionState({
    required this.session,
    this.isSubmitting = false,
  });

  ActiveSessionState copyWith({Session? session, bool? isSubmitting}) =>
      ActiveSessionState(
        session: session ?? this.session,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class ActiveSessionNotifier extends AsyncNotifier<ActiveSessionState?> {
  DateTime? _startTime;

  @override
  Future<ActiveSessionState?> build() async => null;

  /// Load a planned session (generated from program or newly created standalone).
  void loadSession(Session session) {
    _startTime = DateTime.now();
    state = AsyncData(ActiveSessionState(session: session));
  }

  /// Add or replace a completed [SetEntry] for the given exercise block.
  void recordSet(String exerciseId, SetEntry setEntry) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedBlocks = current.session.exerciseBlocks.map((block) {
      if (block.exerciseId != exerciseId) return block;

      final existingIndex =
          block.actualSets.indexWhere((s) => s.setNumber == setEntry.setNumber);

      final List<SetEntry> updated = List.from(block.actualSets);
      if (existingIndex >= 0) {
        updated[existingIndex] = setEntry;
      } else {
        updated.add(setEntry);
      }

      return block.copyWith(actualSets: updated);
    }).toList();

    state = AsyncData(current.copyWith(
      session: current.session.copyWith(exerciseBlocks: updatedBlocks),
    ));
  }

  /// Set RPE (1–10) for an exercise block.
  void setRpe(String exerciseId, int rpe) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedBlocks = current.session.exerciseBlocks.map((block) {
      if (block.exerciseId != exerciseId) return block;
      return block.copyWith(rpe: rpe);
    }).toList();

    state = AsyncData(current.copyWith(
      session: current.session.copyWith(exerciseBlocks: updatedBlocks),
    ));
  }

  /// Set per-block notes.
  void setBlockNotes(String exerciseId, String notes) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedBlocks = current.session.exerciseBlocks.map((block) {
      if (block.exerciseId != exerciseId) return block;
      return block.copyWith(notes: notes);
    }).toList();

    state = AsyncData(current.copyWith(
      session: current.session.copyWith(exerciseBlocks: updatedBlocks),
    ));
  }

  /// Persist the session as planned (after generating from program).
  Future<Session?> saveSession() async {
    final current = state.valueOrNull;
    if (current == null) return null;

    state = AsyncData(current.copyWith(isSubmitting: true));
    final useCase = CreateSession(ref.read(sessionRepositoryProvider));
    final result = await useCase(current.session);

    return result.fold(
      (_) {
        state = AsyncData(current.copyWith(isSubmitting: false));
        return null;
      },
      (saved) {
        state = AsyncData(
          ActiveSessionState(
            session: saved.copyWith(status: SessionStatus.inProgress),
          ),
        );
        return saved;
      },
    );
  }

  /// Mark session as completed and persist all exercise data.
  Future<Session?> completeSession({String? notes}) async {
    final current = state.valueOrNull;
    if (current == null) return null;

    final elapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inMinutes
        : null;

    state = AsyncData(current.copyWith(isSubmitting: true));

    final completed = current.session.copyWith(
      status: SessionStatus.completed,
      notes: notes,
      durationMinutes: elapsed,
    );

    // Session already exists in Firestore if id is set; otherwise create it
    final Either<AppFailure, Session> result;
    if (completed.id.isEmpty) {
      result =
          await CreateSession(ref.read(sessionRepositoryProvider))(completed);
    } else {
      result =
          await UpdateSession(ref.read(sessionRepositoryProvider))(completed);
    }

    return result.fold(
      (_) {
        state = AsyncData(current.copyWith(isSubmitting: false));
        return null;
      },
      (saved) {
        state = const AsyncData(null); // clear active session
        ref.invalidate(todaySessionsProvider);
        ref.invalidate(sessionHistoryProvider);
        return saved;
      },
    );
  }

  /// Discard the in-progress session state without saving.
  void discard() {
    _startTime = null;
    state = const AsyncData(null);
  }
}

final activeSessionProvider =
    AsyncNotifierProvider<ActiveSessionNotifier, ActiveSessionState?>(
  ActiveSessionNotifier.new,
);

// ── Generate + start today's session from active program ──────────────────────

class StartTodaySessionNotifier extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async => null;

  Future<Session?> generateAndStart() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    final programAsync = ref.read(activeProgramProvider);
    final program = programAsync.valueOrNull;
    if (program == null) return null;

    state = const AsyncLoading();

    final generated =
        const GenerateSessionFromProgram()(program, userId, DateTime.now());
    if (generated == null) {
      state = const AsyncData(null);
      return null; // rest day
    }

    // Persist to Firestore
    final result =
        await CreateSession(ref.read(sessionRepositoryProvider))(generated);

    return result.fold(
      (_) {
        state = const AsyncData(null);
        return null;
      },
      (session) {
        state = AsyncData(session);
        ref.read(activeSessionProvider.notifier).loadSession(session);
        return session;
      },
    );
  }
}

final startTodaySessionProvider =
    AsyncNotifierProvider<StartTodaySessionNotifier, Session?>(
  StartTodaySessionNotifier.new,
);
