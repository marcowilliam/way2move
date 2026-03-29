import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_month_grid.dart';
import '../widgets/calendar_week_strip.dart';
import '../widgets/day_sessions_sheet.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _monthSlideController;
  late Animation<Offset> _slideInFromRight;

  /// Track last direction to animate correctly.
  bool _slidingForward = true;

  @override
  void initState() {
    super.initState();
    _monthSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _rebuildSlideAnimations();
    _monthSlideController.forward(from: 1.0); // start completed
  }

  void _rebuildSlideAnimations() {
    _slideInFromRight = Tween<Offset>(
      begin: Offset(_slidingForward ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _monthSlideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _monthSlideController.dispose();
    super.dispose();
  }

  void _navigateMonth(int delta) {
    final current = ref.read(selectedDateProvider);
    final newMonth = DateTime(current.year, current.month + delta, 1);
    setState(() {
      _slidingForward = delta > 0;
      _rebuildSlideAnimations();
    });
    ref.read(selectedDateProvider.notifier).state = DateTime(
        newMonth.year,
        newMonth.month,
        current.day.clamp(
          1,
          DateUtils.getDaysInMonth(newMonth.year, newMonth.month),
        ));
    _monthSlideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final mode = ref.watch(calendarModeProvider);

    return Scaffold(
      key: AppKeys.calendarPage,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: month name + arrows + mode toggle
            _CalendarTopBar(
              month: selectedDate,
              mode: mode,
              onPreviousMonth: () => _navigateMonth(-1),
              onNextMonth: () => _navigateMonth(1),
              onModeChanged: (m) =>
                  ref.read(calendarModeProvider.notifier).state = m,
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    if (mode == CalendarMode.month)
                      SlideTransition(
                        position: _slideInFromRight,
                        child: CalendarMonthGrid(
                          month: DateTime(
                              selectedDate.year, selectedDate.month, 1),
                          selectedDay: selectedDate,
                          onDayTap: (day) {
                            ref.read(selectedDateProvider.notifier).state = day;
                            showDaySessionsSheet(context, day);
                          },
                        ),
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: CalendarWeekStrip(
                          weekDay: selectedDate,
                          selectedDay: selectedDate,
                          onDayTap: (day) {
                            ref.read(selectedDateProvider.notifier).state = day;
                            showDaySessionsSheet(context, day);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarTopBar extends StatelessWidget {
  final DateTime month;
  final CalendarMode mode;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final void Function(CalendarMode) onModeChanged;

  const _CalendarTopBar({
    required this.month,
    required this.mode,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    const monthNames = [
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
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          // Month navigation
          IconButton(
            onPressed: onPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            color: AppColors.textPrimary,
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Center(
              child: Text(
                '${monthNames[month.month]} ${month.year}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNextMonth,
            icon: const Icon(Icons.chevron_right),
            color: AppColors.textPrimary,
            tooltip: 'Next month',
          ),
          const SizedBox(width: 8),
          // Mode toggle
          _ModeToggle(
            mode: mode,
            onChanged: onModeChanged,
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final CalendarMode mode;
  final void Function(CalendarMode) onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleButton(
          widgetKey: AppKeys.calendarMonthToggle,
          label: 'Month',
          isSelected: mode == CalendarMode.month,
          onTap: () => onChanged(CalendarMode.month),
        ),
        const SizedBox(width: 4),
        _ToggleButton(
          widgetKey: AppKeys.calendarWeekToggle,
          label: 'Week',
          isSelected: mode == CalendarMode.week,
          onTap: () => onChanged(CalendarMode.week),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final Key widgetKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.widgetKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: widgetKey,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}
