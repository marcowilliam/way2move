import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/sleep_repository_impl.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/usecases/get_average_sleep_quality.dart';
import '../../domain/usecases/get_sleep_logs.dart';
import '../../domain/usecases/log_sleep.dart';

// Use case providers
final logSleepUseCaseProvider = Provider<LogSleep>(
  (ref) => LogSleep(ref.watch(sleepRepositoryProvider)),
);

final getSleepLogsUseCaseProvider = Provider<GetSleepLogs>(
  (ref) => GetSleepLogs(ref.watch(sleepRepositoryProvider)),
);

final getAverageSleepQualityUseCaseProvider = Provider<GetAverageSleepQuality>(
  (ref) => GetAverageSleepQuality(ref.watch(sleepRepositoryProvider)),
);

// Sleep logs notifier — loads recent logs for current user
class SleepLogsNotifier extends AsyncNotifier<List<SleepLog>> {
  @override
  Future<List<SleepLog>> build() async {
    final uid = ref.watch(currentUserIdProvider);
    if (uid == null) return [];
    final result = await ref.watch(getSleepLogsUseCaseProvider).call(uid);
    return result.getRight().getOrElse(() => []);
  }
}

final sleepLogsNotifierProvider =
    AsyncNotifierProvider<SleepLogsNotifier, List<SleepLog>>(
  SleepLogsNotifier.new,
);

// Sleep notifier with logSleep action
class SleepNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Either<AppFailure, SleepLog>> logSleep(SleepLog sleepLog) async {
    final result = await ref.read(logSleepUseCaseProvider).call(sleepLog);
    if (result.isRight()) {
      ref.invalidate(sleepLogsNotifierProvider);
    }
    return result;
  }
}

final sleepNotifierProvider =
    AsyncNotifierProvider<SleepNotifier, void>(SleepNotifier.new);
