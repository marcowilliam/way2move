import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../journal/presentation/widgets/voice_input_widget.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal.dart';
import '../../domain/usecases/search_food_items.dart';
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
  final _foodSearchController = TextEditingController();
  bool _isSubmitting = false;
  bool _showVoiceInput = false;

  // Food tracking state
  final List<FoodItem> _foodItems = [];
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _descController.dispose();
    _notesController.dispose();
    _foodSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  bool get _canSave =>
      _selectedType != null &&
      _selectedFeeling != null &&
      _descController.text.trim().isNotEmpty;

  double get _totalCalories =>
      _foodItems.fold(0, (s, i) => s + i.scaledCalories);
  double get _totalProtein => _foodItems.fold(0, (s, i) => s + i.scaledProtein);
  double get _totalCarbs => _foodItems.fold(0, (s, i) => s + i.scaledCarbs);
  double get _totalFat => _foodItems.fold(0, (s, i) => s + i.scaledFat);

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await ref.read(searchFoodItemsProvider).call(query.trim());
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults =
              result.fold((_) => [], (items) => items.take(5).toList());
        });
      }
    });
  }

  void _addFoodItem(FoodItem item) {
    setState(() {
      _foodItems.add(item);
      _searchResults = [];
      _foodSearchController.clear();
    });
  }

  void _removeFoodItem(int index) {
    setState(() => _foodItems.removeAt(index));
  }

  void _updatePortion(int index, double grams) {
    if (grams <= 0) return;
    setState(() {
      _foodItems[index] = _foodItems[index].copyWith(portionGrams: grams);
    });
  }

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
      foodItems: _foodItems.isEmpty ? null : List.unmodifiable(_foodItems),
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
            // ── Food search ───────────────────────────────────────────────
            const _SectionLabel('Search food'),
            const SizedBox(height: 8),
            TextField(
              key: AppKeys.foodSearchField,
              controller: _foodSearchController,
              decoration: InputDecoration(
                hintText: 'Search food database...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 4),
              _FoodSearchResultsList(
                results: _searchResults,
                onAdd: _addFoodItem,
              ),
            ],
            if (_foodItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const _SectionLabel('Added foods'),
              const SizedBox(height: 8),
              _FoodItemsList(
                key: AppKeys.foodItemsList,
                items: _foodItems,
                onRemove: _removeFoodItem,
                onPortionChanged: _updatePortion,
              ),
              const SizedBox(height: 12),
              _MacroTotalsRow(
                key: AppKeys.macroTotalsRow,
                calories: _totalCalories,
                protein: _totalProtein,
                carbs: _totalCarbs,
                fat: _totalFat,
              ),
            ],
            const SizedBox(height: 20),

            // ── Meal type ─────────────────────────────────────────────────
            const _SectionLabel('Meal type'),
            const SizedBox(height: 8),
            _MealTypeSelector(
              selected: _selectedType,
              onSelect: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 20),

            // ── Description ───────────────────────────────────────────────
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

            // ── Stomach feeling ───────────────────────────────────────────
            const _SectionLabel('How did your stomach feel?'),
            const SizedBox(height: 8),
            _StomachFeelingSelector(
              selected: _selectedFeeling,
              onSelect: (f) => setState(() => _selectedFeeling = f),
            ),
            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────────────────
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

// ── Food search results ───────────────────────────────────────────────────────

class _FoodSearchResultsList extends StatelessWidget {
  final List<FoodItem> results;
  final void Function(FoodItem) onAdd;

  const _FoodSearchResultsList({required this.results, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: AppKeys.foodSearchResults,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: results
            .map((item) => ListTile(
                  dense: true,
                  title: Text(
                    item.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${item.calories.toStringAsFixed(0)} kcal · '
                    'P${item.protein.toStringAsFixed(1)}g · '
                    'C${item.carbs.toStringAsFixed(1)}g · '
                    'F${item.fat.toStringAsFixed(1)}g',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                    onPressed: () => onAdd(item),
                    tooltip: 'Add food',
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Added food items list ─────────────────────────────────────────────────────

class _FoodItemsList extends StatelessWidget {
  final List<FoodItem> items;
  final void Function(int index) onRemove;
  final void Function(int index, double grams) onPortionChanged;

  const _FoodItemsList({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onPortionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _FoodItemRow(
          item: item,
          onRemove: () => onRemove(index),
          onPortionChanged: (grams) => onPortionChanged(index, grams),
        );
      }).toList(),
    );
  }
}

class _FoodItemRow extends StatefulWidget {
  final FoodItem item;
  final VoidCallback onRemove;
  final void Function(double grams) onPortionChanged;

  const _FoodItemRow({
    required this.item,
    required this.onRemove,
    required this.onPortionChanged,
  });

  @override
  State<_FoodItemRow> createState() => _FoodItemRowState();
}

class _FoodItemRowState extends State<_FoodItemRow> {
  late final TextEditingController _portionController;

  @override
  void initState() {
    super.initState();
    _portionController = TextEditingController(
      text: widget.item.portionGrams.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(_FoodItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.portionGrams != widget.item.portionGrams) {
      _portionController.text = widget.item.portionGrams.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _portionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.item.scaledCalories.toStringAsFixed(0)} kcal · '
                    'P${widget.item.scaledProtein.toStringAsFixed(1)}g · '
                    'C${widget.item.scaledCarbs.toStringAsFixed(1)}g · '
                    'F${widget.item.scaledFat.toStringAsFixed(1)}g',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 56,
              child: TextField(
                controller: _portionController,
                textAlign: TextAlign.right,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  suffixText: 'g',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  border: OutlineInputBorder(),
                ),
                style: Theme.of(context).textTheme.bodySmall,
                onChanged: (val) {
                  final grams = double.tryParse(val);
                  if (grams != null && grams > 0) {
                    widget.onPortionChanged(grams);
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close,
                  size: 18, color: AppColors.textSecondary),
              onPressed: widget.onRemove,
              tooltip: 'Remove',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Macro totals row ──────────────────────────────────────────────────────────

class _MacroTotalsRow extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const _MacroTotalsRow({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MacroCell(label: 'kcal', value: calories, emoji: '🔥'),
          _MacroCell(label: 'protein', value: protein, emoji: '💪'),
          _MacroCell(label: 'carbs', value: carbs, emoji: '🌾'),
          _MacroCell(label: 'fat', value: fat, emoji: '🥑'),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  final String label;
  final double value;
  final String emoji;

  const _MacroCell(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        Text(
          value.toStringAsFixed(0),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary, fontSize: 9),
        ),
      ],
    );
  }
}

// ── Existing private widgets (unchanged) ─────────────────────────────────────

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
