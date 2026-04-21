import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/sleep_log.dart';
import '../providers/sleep_providers.dart';

class SleepLogEntryPage extends ConsumerStatefulWidget {
  const SleepLogEntryPage({super.key});

  @override
  ConsumerState<SleepLogEntryPage> createState() => _SleepLogEntryPageState();
}

class _SleepLogEntryPageState extends ConsumerState<SleepLogEntryPage> {
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 0);
  int? _quality;
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Duration _calculateDuration() {
    final now = DateTime.now();
    final bed =
        DateTime(now.year, now.month, now.day, _bedTime.hour, _bedTime.minute);
    var wake = DateTime(
        now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    if (wake.isBefore(bed)) {
      wake = wake.add(const Duration(days: 1));
    }
    return wake.difference(bed);
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}min';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }

  Future<void> _pickBedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedTime,
      helpText: 'Bed time',
    );
    if (picked != null) setState(() => _bedTime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      helpText: 'Wake time',
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  Future<void> _save() async {
    if (_quality == null) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final bed =
        DateTime(now.year, now.month, now.day, _bedTime.hour, _bedTime.minute);
    var wake = DateTime(
        now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);
    if (wake.isBefore(bed)) {
      wake = wake.add(const Duration(days: 1));
    }

    final log = SleepLog(
      id: '',
      userId: '',
      bedTime: bed,
      wakeTime: wake,
      quality: _quality!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: wake,
    );

    final notifier = ref.read(sleepNotifierProvider.notifier);
    final result = await notifier.logSleep(log);

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save sleep log. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep log saved!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  String _qualityLabel(int q) {
    switch (q) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration();
    final theme = Theme.of(context);

    return Scaffold(
      key: AppKeys.sleepEntryWidget,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Log Sleep'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How\'d you sleep?',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            _TimePickerRow(
              label: 'Bed time',
              time: _bedTime,
              onTap: _pickBedTime,
              icon: Icons.bedtime_outlined,
            ),
            Divider(height: AppSpacing.lg, color: theme.colorScheme.outlineVariant),
            _TimePickerRow(
              label: 'Wake time',
              time: _wakeTime,
              onTap: _pickWakeTime,
              icon: Icons.wb_sunny_outlined,
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _formatDuration(duration),
                  key: ValueKey('$_bedTime$_wakeTime'),
                  style: AppTypography.fraunces(
                    size: 40,
                    weight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'in bed',
                style: theme.textTheme.labelSmall,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Quality',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final q = i + 1;
                final isSelected = _quality == q;
                return GestureDetector(
                  onTap: () => setState(() => _quality = q),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 68,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _qualityEmoji(q),
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$q',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_quality != null)
              Center(
                child: Text(
                  _qualityLabel(_quality!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Notes',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'How did you sleep? Any disturbances?',
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _quality == null || _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Text('Save Sleep Log'),
            ),
          ],
        ),
      ),
    );
  }

  String _qualityEmoji(int q) {
    switch (q) {
      case 1:
        return '😣';
      case 2:
        return '😕';
      case 3:
        return '🌙';
      case 4:
        return '🌠';
      case 5:
        return '✨';
      default:
        return '•';
    }
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final IconData icon;

  const _TimePickerRow({
    required this.label,
    required this.time,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              time.format(context),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
