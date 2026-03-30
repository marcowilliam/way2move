import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/journal_audio_storage_datasource.dart';
import '../../data/repositories/journal_repository_impl.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/usecases/create_journal_entry.dart';
import '../../domain/usecases/get_journals_by_date.dart';
import '../../domain/usecases/get_journals_for_session.dart';

final journalAudioStorageProvider =
    Provider<JournalAudioStorageDatasource>((ref) {
  return JournalAudioStorageDatasource(ref.watch(firebaseStorageProvider));
});

// Use case providers
final createJournalEntryUseCaseProvider = Provider<CreateJournalEntry>(
    (ref) => CreateJournalEntry(ref.watch(journalRepositoryProvider)));

final getJournalsByDateUseCaseProvider = Provider<GetJournalsByDate>(
    (ref) => GetJournalsByDate(ref.watch(journalRepositoryProvider)));

final getJournalsForSessionUseCaseProvider = Provider<GetJournalsForSession>(
    (ref) => GetJournalsForSession(ref.watch(journalRepositoryProvider)));

// Daily journals notifier
class DailyJournalsNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];
    final result = await ref
        .watch(getJournalsByDateUseCaseProvider)
        .call(uid, DateTime.now());
    return result.getRight().getOrElse(() => []);
  }

  Future<void> refresh() => ref.refresh(dailyJournalsNotifierProvider.future);
}

final dailyJournalsNotifierProvider =
    AsyncNotifierProvider<DailyJournalsNotifier, List<JournalEntry>>(
        DailyJournalsNotifier.new);

// Journal creation notifier
class JournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  @override
  Future<List<JournalEntry>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];
    final result = await ref.watch(journalRepositoryProvider).getHistory(uid);
    return result.getRight().getOrElse(() => []);
  }

  Future<Either<AppFailure, JournalEntry>> create(JournalEntry entry) async {
    final result =
        await ref.read(createJournalEntryUseCaseProvider).call(entry);
    if (result.isRight()) ref.invalidateSelf();
    return result;
  }
}

final journalNotifierProvider =
    AsyncNotifierProvider<JournalNotifier, List<JournalEntry>>(
        JournalNotifier.new);
