import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/sleep_log.dart';
import '../providers/sleep_providers.dart';
import '../widgets/sleep_history_chart.dart';

class SleepHistoryPage extends ConsumerWidget {
  const SleepHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepLogsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep History'),
      ),
      body: sleepAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load sleep logs: $e'),
        ),
        data: (logs) => RefreshIndicator(
          onRefresh: () => ref.refresh(sleepLogsNotifierProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SleepHistoryChart(logs: logs),
                    ),
                  ),
                ),
              ),
              if (logs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bedtime_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sleep logs yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to log your first night',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _SleepLogRow(log: logs[i]),
                    childCount: logs.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SleepLogRow extends StatelessWidget {
  final SleepLog log;

  const _SleepLogRow({required this.log});

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat.jm();
    final dateFmt = DateFormat.MMMEd();
    final duration = log.wakeTime.difference(log.bedTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFmt.format(log.date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${timeFmt.format(log.bedTime)} → ${timeFmt.format(log.wakeTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Duration
              Expanded(
                flex: 2,
                child: Text(
                  _formatDuration(duration),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Quality stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < log.quality ? Icons.star : Icons.star_border,
                    size: 16,
                    color: i < log.quality
                        ? const Color(0xFFFFCA28)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
