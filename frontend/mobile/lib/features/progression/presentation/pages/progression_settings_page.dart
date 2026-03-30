import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../domain/entities/progression_rule.dart';
import '../providers/progression_providers.dart';

class ProgressionSettingsPage extends ConsumerStatefulWidget {
  const ProgressionSettingsPage({super.key});

  @override
  ConsumerState<ProgressionSettingsPage> createState() =>
      _ProgressionSettingsPageState();
}

class _ProgressionSettingsPageState
    extends ConsumerState<ProgressionSettingsPage> {
  int _completionThreshold = 3;
  double _sleepThreshold = 3.5;
  double _pulseThreshold = 3.0;
  double _stomachThreshold = 3.0;
  bool _initialized = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final ruleAsync = ref.watch(globalProgressionRuleNotifierProvider);
    final theme = Theme.of(context);

    ruleAsync.whenData((rule) {
      if (!_initialized) {
        _completionThreshold = rule.completionThreshold;
        _sleepThreshold = rule.sleepThreshold;
        _pulseThreshold = rule.pulseThreshold;
        _stomachThreshold = rule.stomachThreshold;
        _initialized = true;
      }
    });

    return Scaffold(
      key: AppKeys.progressionSettingsPage,
      appBar: AppBar(
        title: const Text('Auto-Progression Settings'),
        centerTitle: true,
      ),
      body: ruleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) => _buildBody(theme),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: FilledButton(
            key: AppKeys.progressionSaveButton,
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _SectionHeader(title: 'Global Thresholds'),
        const SizedBox(height: 16),
        _SliderTile(
          label: 'Suggest after completions',
          value: _completionThreshold.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          displayValue: '$_completionThreshold',
          onChanged: (v) => setState(() => _completionThreshold = v.round()),
        ),
        const SizedBox(height: 8),
        _SliderTile(
          label: 'Sleep quality threshold',
          value: _sleepThreshold,
          min: 1,
          max: 5,
          divisions: 8,
          displayValue: _sleepThreshold.toStringAsFixed(1),
          onChanged: (v) => setState(() => _sleepThreshold = v),
        ),
        const SizedBox(height: 8),
        _SliderTile(
          label: 'Energy/pulse threshold',
          value: _pulseThreshold,
          min: 1,
          max: 5,
          divisions: 8,
          displayValue: _pulseThreshold.toStringAsFixed(1),
          onChanged: (v) => setState(() => _pulseThreshold = v),
        ),
        const SizedBox(height: 8),
        _SliderTile(
          label: 'Gut/stomach threshold',
          value: _stomachThreshold,
          min: 1,
          max: 5,
          divisions: 8,
          displayValue: _stomachThreshold.toStringAsFixed(1),
          onChanged: (v) => setState(() => _stomachThreshold = v),
        ),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'About Auto-Progression'),
        const SizedBox(height: 12),
        Text(
          'Way2Move watches your training patterns and body signals to suggest '
          'when to progress or take it easier. After you complete an exercise '
          'enough times (based on your completion threshold), the system will '
          'suggest increasing reps, adding load, or advancing to the next '
          'exercise variation.\n\n'
          'If your sleep quality, energy levels, or gut feeling are below your '
          'set thresholds, the system will recommend a deload to help your body '
          'recover — keeping you healthy for the long game.\n\n'
          'Values of 0 in any signal mean "no data" and will not block '
          'progression suggestions.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final rule = ProgressionRule(
      completionThreshold: _completionThreshold,
      sleepThreshold: _sleepThreshold,
      pulseThreshold: _pulseThreshold,
      stomachThreshold: _stomachThreshold,
    );
    await ref.read(globalProgressionRuleNotifierProvider.notifier).save(rule);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValue,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
