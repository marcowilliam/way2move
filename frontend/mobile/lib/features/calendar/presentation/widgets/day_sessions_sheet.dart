import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sessions/domain/entities/session.dart';
import '../providers/calendar_providers.dart';

/// Shows a bottom sheet with the sessions for a given [day].
Future<void> showDaySessionsSheet(
  BuildContext context,
  DateTime day,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DaySessionsSheet(day: day),
  );
}

class DaySessionsSheet extends ConsumerWidget {
  final DateTime day;
  const DaySessionsSheet({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsForDayProvider(day));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          key: AppKeys.daySessionsSheet,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _formatDate(day),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              Expanded(
                child: sessionsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e'),
                  ),
                  data: (sessions) => sessions.isEmpty
                      ? _EmptyDayView(day: day)
                      : _SessionList(
                          sessions: sessions,
                          scrollController: scrollController,
                        ),
                ),
              ),
              _StartSessionButton(day: day),
            ],
          ),
        );
      },
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<Session> sessions;
  final ScrollController scrollController;

  const _SessionList({
    required this.sessions,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: sessions.length,
      itemBuilder: (context, i) => _SessionCard(session: sessions[i]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(session.status);

    return Card(
      elevation: 0,
      color: AppColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.focus ?? 'Training',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (session.durationMinutes != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${session.durationMinutes} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            _StatusChip(status: session.status, color: statusColor),
          ],
        ),
      ),
    );
  }

  Color _statusColor(SessionStatus s) {
    switch (s) {
      case SessionStatus.planned:
        return AppColors.primary;
      case SessionStatus.inProgress:
        return AppColors.accent;
      case SessionStatus.completed:
        return AppColors.accentGreen;
      case SessionStatus.skipped:
        return AppColors.textSecondary;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final SessionStatus status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(status),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  String _label(SessionStatus s) {
    switch (s) {
      case SessionStatus.planned:
        return 'Planned';
      case SessionStatus.inProgress:
        return 'In Progress';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.skipped:
        return 'Skipped';
    }
  }
}

class _EmptyDayView extends StatelessWidget {
  final DateTime day;
  const _EmptyDayView({required this.day});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 12),
            Text(
              'No sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap 'Start New Session' to add one.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartSessionButton extends StatelessWidget {
  final DateTime day;
  const _StartSessionButton({required this.day});

  @override
  Widget build(BuildContext context) {
    final isToday = day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;

    // Only show "Start" button for today or future; past days show "Log" label
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: FilledButton.icon(
        key: AppKeys.startNewSessionButton,
        onPressed: () {
          Navigator.of(context).pop();
          context.push(Routes.sessionStandalone);
        },
        icon: const Icon(Icons.play_arrow_outlined),
        label: Text(isToday ? 'Start New Session' : 'Log Session'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  const days = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  return '${days[dt.weekday]}, ${months[dt.month]} ${dt.day}';
}
