import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../sessions/domain/entities/session.dart';
import '../providers/calendar_providers.dart';

class CalendarWeekStrip extends ConsumerWidget {
  /// Any day within the target week — the strip shows Mon–Sun of that week.
  final DateTime weekDay;
  final DateTime selectedDay;
  final void Function(DateTime) onDayTap;

  const CalendarWeekStrip({
    super.key,
    required this.weekDay,
    required this.selectedDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = weekDay.subtract(Duration(days: weekDay.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return SizedBox(
      key: AppKeys.calendarWeekStrip,
      height: 80,
      child: Row(
        children: days.map((day) {
          final sessionsAsync = ref.watch(sessionsForDayProvider(day));
          final sessions = sessionsAsync.valueOrNull ?? [];

          final isSelected = day.year == selectedDay.year &&
              day.month == selectedDay.month &&
              day.day == selectedDay.day;
          final isToday = day.year == DateTime.now().year &&
              day.month == DateTime.now().month &&
              day.day == DateTime.now().day;

          return Expanded(
            child: _WeekDayCell(
              day: day,
              sessions: sessions,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => onDayTap(day),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeekDayCell extends StatelessWidget {
  final DateTime day;
  final List<Session> sessions;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _WeekDayCell({
    required this.day,
    required this.sessions,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final label = dayLabels[day.weekday - 1];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        isSelected ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 10,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            if (sessions.isNotEmpty)
              _SessionTypeIcon(sessions: sessions, isSelected: isSelected)
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _SessionTypeIcon extends StatelessWidget {
  final List<Session> sessions;
  final bool isSelected;

  const _SessionTypeIcon({required this.sessions, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final session = sessions.first;
    final focus = session.focus?.toLowerCase() ?? '';
    final isRecovery = focus.contains('recovery') || focus.contains('rest');

    IconData icon;
    Color color;
    if (isRecovery) {
      icon = Icons.self_improvement_outlined;
      color = isSelected ? Colors.white : const Color(0xFF8E44AD);
    } else if (session.status == SessionStatus.completed) {
      icon = Icons.check_circle_outline;
      color = isSelected ? Colors.white : AppColors.accentGreen;
    } else if (session.status == SessionStatus.skipped) {
      icon = Icons.cancel_outlined;
      color = isSelected ? Colors.white70 : AppColors.textSecondary;
    } else {
      icon = Icons.fitness_center_outlined;
      color = isSelected ? Colors.white : AppColors.primary;
    }

    return Icon(icon, size: 14, color: color);
  }
}
