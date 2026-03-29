import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sessions/domain/entities/session.dart';
import '../providers/calendar_providers.dart';

class CalendarMonthGrid extends ConsumerWidget {
  final DateTime month;
  final DateTime selectedDay;
  final void Function(DateTime) onDayTap;

  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsForMonthProvider(
      DateTime(month.year, month.month, 1),
    ));

    return sessionsAsync.when(
      loading: () => _CalendarGrid(
        month: month,
        selectedDay: selectedDay,
        sessionsByDay: const {},
        onDayTap: onDayTap,
      ),
      error: (_, __) => _CalendarGrid(
        month: month,
        selectedDay: selectedDay,
        sessionsByDay: const {},
        onDayTap: onDayTap,
      ),
      data: (sessions) {
        final byDay = <int, List<Session>>{};
        for (final s in sessions) {
          byDay.putIfAbsent(s.date.day, () => []).add(s);
        }
        return _CalendarGrid(
          key: AppKeys.calendarMonthGrid,
          month: month,
          selectedDay: selectedDay,
          sessionsByDay: byDay,
          onDayTap: onDayTap,
        );
      },
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Map<int, List<Session>> sessionsByDay;
  final void Function(DateTime) onDayTap;

  const _CalendarGrid({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.sessionsByDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    // 0=Monday in Dart weekday; convert to 0=Sunday offset for grid
    final startOffset = (firstDay.weekday % 7); // 0=Sun,...,6=Sat
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Column(
      children: [
        const _WeekdayHeader(),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) {
              return const SizedBox.shrink();
            }
            final day = index - startOffset + 1;
            final date = DateTime(month.year, month.month, day);
            final sessions = sessionsByDay[day] ?? [];
            final isSelected = date.year == selectedDay.year &&
                date.month == selectedDay.month &&
                date.day == selectedDay.day;
            final isToday = date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            return _DayCell(
              day: day,
              date: date,
              sessions: sessions,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => onDayTap(date),
            );
          },
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final DateTime date;
  final List<Session> sessions;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.date,
    required this.sessions,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                  ),
            ),
            if (sessions.isNotEmpty) ...[
              const SizedBox(height: 2),
              _SessionDots(sessions: sessions, isSelected: isSelected),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionDots extends StatelessWidget {
  final List<Session> sessions;
  final bool isSelected;

  const _SessionDots({required this.sessions, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    // Show at most 3 dots
    final visible = sessions.take(3).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: visible.asMap().entries.map((entry) {
        final session = entry.value;
        final color = isSelected
            ? Colors.white.withValues(alpha: 0.9)
            : _dotColor(session);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200 + entry.key * 80),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _dotColor(Session s) {
    final focus = s.focus?.toLowerCase() ?? '';
    if (focus.contains('recovery') || focus.contains('rest')) {
      return const Color(0xFF8E44AD); // purple
    }
    switch (s.status) {
      case SessionStatus.completed:
        return AppColors.accentGreen;
      case SessionStatus.skipped:
        return AppColors.textSecondary;
      case SessionStatus.planned:
      case SessionStatus.inProgress:
        return AppColors.primary;
    }
  }
}
