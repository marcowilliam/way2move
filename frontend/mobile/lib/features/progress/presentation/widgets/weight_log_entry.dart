import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/weight_log.dart';

class WeightLogEntry extends StatefulWidget {
  final void Function(double weight, WeightUnit unit, String? notes) onLog;

  const WeightLogEntry({super.key, required this.onLog});

  @override
  State<WeightLogEntry> createState() => _WeightLogEntryState();
}

class _WeightLogEntryState extends State<WeightLogEntry> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  WeightUnit _selectedUnit = WeightUnit.kg;
  bool _isLogging = false;

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleLog() async {
    final raw = _weightController.text.trim();
    if (raw.isEmpty) return;
    final weight = double.tryParse(raw);
    if (weight == null || weight <= 0) return;

    setState(() => _isLogging = true);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    widget.onLog(weight, _selectedUnit, notes);
    _weightController.clear();
    _notesController.clear();
    setState(() => _isLogging = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('weight_input_field'),
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      hintText:
                          _selectedUnit == WeightUnit.kg ? '75.0' : '165.0',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<WeightUnit>(
                  key: const Key('weight_unit_toggle'),
                  segments: const [
                    ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                    ButtonSegment(value: WeightUnit.lbs, label: Text('lbs')),
                  ],
                  selected: {_selectedUnit},
                  onSelectionChanged: (sel) =>
                      setState(() => _selectedUnit = sel.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('weight_notes_field'),
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Morning, after workout…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('log_weight_button'),
                onPressed: _isLogging ? null : _handleLog,
                child: _isLogging
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Log Weight',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
