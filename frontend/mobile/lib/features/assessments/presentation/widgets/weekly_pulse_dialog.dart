import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/assessment.dart';
import '../providers/assessment_providers.dart';

/// Shows the weekly pulse check-in as a bottom sheet.
///
/// Usage:
/// ```dart
/// showWeeklyPulseDialog(context);
/// ```
Future<void> showWeeklyPulseDialog(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const WeeklyPulseDialog(),
  );
}

class WeeklyPulseDialog extends ConsumerStatefulWidget {
  const WeeklyPulseDialog({super.key});

  @override
  ConsumerState<WeeklyPulseDialog> createState() => _WeeklyPulseDialogState();
}

class _WeeklyPulseDialogState extends ConsumerState<WeeklyPulseDialog> {
  int _energy = 3;
  int _soreness = 3;
  int _motivation = 3;
  int _sleepQuality = 3;
  final _notesController = TextEditingController();
  bool _saving = false;
  bool _saved = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      Navigator.of(context).pop();
      return;
    }

    final pulse = WeeklyPulse(
      id: '',
      userId: userId,
      date: DateTime.now(),
      energyScore: _energy,
      sorenessScore: _soreness,
      motivationScore: _motivation,
      sleepQualityScore: _sleepQuality,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final ok = await ref.read(weeklyPulseProvider.notifier).log(pulse);

    if (mounted) {
      if (ok) {
        setState(() {
          _saving = false;
          _saved = true;
        });
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Container(
        key: AppKeys.weeklyPulseDialog,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Weekly Pulse',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              "How's your body feeling this week?",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _SliderRow(
              label: 'Energy',
              emoji: '⚡',
              value: _energy,
              lowLabel: 'Drained',
              highLabel: 'Full energy',
              onChanged: (v) => setState(() => _energy = v),
            ),
            _SliderRow(
              label: 'Soreness',
              emoji: '💪',
              value: _soreness,
              lowLabel: 'Very sore',
              highLabel: 'No soreness',
              onChanged: (v) => setState(() => _soreness = v),
            ),
            _SliderRow(
              label: 'Motivation',
              emoji: '🎯',
              value: _motivation,
              lowLabel: 'Low',
              highLabel: 'Pumped',
              onChanged: (v) => setState(() => _motivation = v),
            ),
            _SliderRow(
              label: 'Sleep Quality',
              emoji: '🌙',
              value: _sleepQuality,
              lowLabel: 'Poor',
              highLabel: 'Excellent',
              onChanged: (v) => setState(() => _sleepQuality = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Any notes? (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _saving
                  ? const Center(child: CircularProgressIndicator())
                  : _saved
                      ? Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text('Saved!'),
                            ],
                          ),
                        )
                      : FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Save Pulse'),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String emoji;
  final int value;
  final String lowLabel;
  final String highLabel;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.emoji,
    required this.value,
    required this.lowLabel,
    required this.highLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$emoji ', style: const TextStyle(fontSize: 16)),
              Text(
                label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _DotIndicator(value: value),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lowLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                Text(highLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int value; // 1-5
  const _DotIndicator({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: i < value ? 8 : 6,
          height: i < value ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
