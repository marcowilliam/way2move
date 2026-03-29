import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_providers.dart';

class AddGoalDialog extends ConsumerStatefulWidget {
  final String userId;

  const AddGoalDialog({super.key, required this.userId});

  @override
  ConsumerState<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends ConsumerState<AddGoalDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetMetricController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _unitController = TextEditingController();
  GoalCategory _selectedCategory = GoalCategory.general;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetMetricController.dispose();
    _targetValueController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: AppKeys.addGoalDialog,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Goal',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: AppKeys.goalNameField,
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Goal name',
                  hintText: 'e.g. Improve ankle mobility',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _CategoryChips(
                selected: _selectedCategory,
                onChanged: (c) => setState(() => _selectedCategory = c),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _targetMetricController,
                      decoration: const InputDecoration(
                        labelText: 'Metric',
                        hintText: 'e.g. reps, seconds',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: AppKeys.goalTargetValueField,
                      controller: _targetValueController,
                      decoration: const InputDecoration(labelText: 'Target'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: AppKeys.goalUnitField,
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: AppKeys.goalSaveButton,
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final goal = Goal(
      id: '',
      userId: widget.userId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      targetMetric: _targetMetricController.text.trim(),
      targetValue: double.parse(_targetValueController.text.trim()),
      unit: _unitController.text.trim(),
      source: GoalSource.manual,
    );

    final result =
        await ref.read(goalNotifierProvider.notifier).createGoal(goal);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save goal')),
      ),
      (_) => Navigator.of(context).pop(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final GoalCategory selected;
  final void Function(GoalCategory) onChanged;

  const _CategoryChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: GoalCategory.values.map((c) {
        final isSelected = c == selected;
        return ChoiceChip(
          label: Text(_label(c)),
          selected: isSelected,
          onSelected: (_) => onChanged(c),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        );
      }).toList(),
    );
  }

  String _label(GoalCategory c) {
    switch (c) {
      case GoalCategory.mobility:
        return 'Mobility';
      case GoalCategory.stability:
        return 'Stability';
      case GoalCategory.strength:
        return 'Strength';
      case GoalCategory.endurance:
        return 'Endurance';
      case GoalCategory.posture:
        return 'Posture';
      case GoalCategory.sport:
        return 'Sport';
      case GoalCategory.recovery:
        return 'Recovery';
      case GoalCategory.general:
        return 'General';
    }
  }
}
