import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../journal/presentation/widgets/voice_input_widget.dart';
import '../../domain/entities/meal.dart';
import '../providers/nutrition_providers.dart';

class MealLogPage extends ConsumerStatefulWidget {
  const MealLogPage({super.key});

  @override
  ConsumerState<MealLogPage> createState() => _MealLogPageState();
}

class _MealLogPageState extends ConsumerState<MealLogPage> {
  MealType? _selectedType;
  int? _selectedFeeling;
  final _descController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _showVoiceInput = false;

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _selectedType != null &&
      _selectedFeeling != null &&
      _descController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final meal = Meal(
      id: '',
      userId: userId,
      date: DateTime.now(),
      mealType: _selectedType!,
      description: _descController.text.trim(),
      stomachFeeling: _selectedFeeling!,
      stomachNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      source: 'manual',
    );

    await ref.read(dailyMealsNotifierProvider.notifier).addMeal(meal);

    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.mealLogPage,
      appBar: AppBar(
        title: const Text('Log Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Meal type'),
            const SizedBox(height: 8),
            _MealTypeSelector(
              selected: _selectedType,
              onSelect: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('What did you eat?'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: AppKeys.mealDescriptionField,
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe your meal...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: AppKeys.voiceInputButton,
                  icon: Icon(
                    _showVoiceInput ? Icons.mic : Icons.mic_outlined,
                  ),
                  tooltip: 'Voice input',
                  style: IconButton.styleFrom(
                    backgroundColor: _showVoiceInput
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _showVoiceInput = !_showVoiceInput),
                ),
              ],
            ),
            if (_showVoiceInput) ...[
              const SizedBox(height: 12),
              Center(
                child: VoiceInputWidget(
                  onTranscription: (text) {
                    setState(() {
                      _descController.text = text;
                      _descController.selection =
                          TextSelection.collapsed(offset: text.length);
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            const _SectionLabel('How did your stomach feel?'),
            const SizedBox(height: 8),
            _StomachFeelingSelector(
              selected: _selectedFeeling,
              onSelect: (f) => setState(() => _selectedFeeling = f),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Notes (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              key: AppKeys.stomachNotesField,
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Any stomach symptoms? (bloating, pain, etc.)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                key: AppKeys.saveMealButton,
                onPressed: _canSave && !_isSubmitting ? _save : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Meal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _MealTypeSelector extends StatelessWidget {
  final MealType? selected;
  final void Function(MealType) onSelect;

  const _MealTypeSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: AppKeys.mealTypeSelector,
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: MealType.values.map((type) {
          final isSelected = selected == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_label(type)),
              selected: isSelected,
              onSelected: (_) => onSelect(type),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(MealType t) => switch (t) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
        MealType.drink => 'Drink',
      };
}

class _StomachFeelingSelector extends StatelessWidget {
  final int? selected;
  final void Function(int) onSelect;

  const _StomachFeelingSelector(
      {required this.selected, required this.onSelect});

  static const _feelings = [
    (value: 1, emoji: '😣', label: 'Terrible'),
    (value: 2, emoji: '😕', label: 'Bad'),
    (value: 3, emoji: '😐', label: 'Okay'),
    (value: 4, emoji: '🙂', label: 'Good'),
    (value: 5, emoji: '😊', label: 'Great'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      key: AppKeys.stomachFeelingSelector,
      children: _feelings
          .map((f) => Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(f.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected == f.value
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected == f.value
                            ? AppColors.primary
                            : AppColors.border,
                        width: selected == f.value ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(f.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          f.label,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: selected == f.value
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
