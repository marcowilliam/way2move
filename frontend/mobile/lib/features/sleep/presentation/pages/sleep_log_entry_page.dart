import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
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
      appBar: AppBar(
        title: const Text('Log Sleep'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time pickers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TimePickerRow(
                      label: 'Bed time',
                      time: _bedTime,
                      onTap: _pickBedTime,
                      icon: Icons.bedtime_outlined,
                    ),
                    const Divider(height: 24),
                    _TimePickerRow(
                      label: 'Wake time',
                      time: _wakeTime,
                      onTap: _pickWakeTime,
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _formatDuration(duration),
                  key: ValueKey('$_bedTime$_wakeTime'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                'duration',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quality selector
            Text(
              'Sleep quality',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
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
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$q',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            if (_quality != null)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Center(
                  child: Text(
                    _qualityLabel(_quality!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Notes (optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'How did you sleep? Any disturbances?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _quality == null || _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Sleep Log'),
              ),
            ),
          ],
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            Text(
              time.format(context),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
