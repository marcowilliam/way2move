import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/nutrition_target.dart';
import '../providers/nutrition_target_provider.dart';

class NutritionTargetSettingsPage extends ConsumerStatefulWidget {
  const NutritionTargetSettingsPage({super.key});

  @override
  ConsumerState<NutritionTargetSettingsPage> createState() =>
      _NutritionTargetSettingsPageState();
}

class _NutritionTargetSettingsPageState
    extends ConsumerState<NutritionTargetSettingsPage>
    with SingleTickerProviderStateMixin {
  MacroPreset? _selectedPreset;
  bool _saving = false;
  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetAsync = ref.watch(nutritionTargetNotifierProvider);
    final profile = ref.watch(profileStreamProvider).valueOrNull;

    // Initialise selected preset from saved target (once)
    targetAsync.whenData((target) {
      if (_selectedPreset == null && target != null) {
        _selectedPreset = target.preset;
      }
    });

    final hasProfileData = profile?.age != null &&
        profile?.weight != null &&
        profile?.height != null &&
        profile?.activityLevel != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nutrition Targets'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: targetAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (target) => _buildContent(
              context, target, hasProfileData, profile?.activityLevel),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NutritionTarget? target,
    bool hasProfileData,
    dynamic activityLevel,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasProfileData) _buildProfileWarning(context),
          if (hasProfileData) ...[
            _buildSectionHeader('Choose your goal'),
            const SizedBox(height: 12),
            ...MacroPreset.values.map(
              (preset) => _buildPresetCard(preset),
            ),
            const SizedBox(height: 28),
          ],
          if (target != null) ...[
            _buildSectionHeader('Current targets'),
            const SizedBox(height: 12),
            _buildTargetSummary(target),
            const SizedBox(height: 8),
            _buildDayVariationRow(target),
          ],
          if (hasProfileData) ...[
            const SizedBox(height: 28),
            _buildApplyButton(hasProfileData),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete your profile (age, weight, height, activity level) '
              'to get personalised targets.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPresetCard(MacroPreset preset) {
    final isSelected = _selectedPreset == preset;
    final (proteinR, carbsR, fatR) = preset.macroRatios;

    return GestureDetector(
      onTap: () => setState(() => _selectedPreset = preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withAlpha(15) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMacroRatioBar(proteinR, carbsR, fatR),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _macroLabel('P', '${(proteinR * 100).round()}%',
                          AppColors.accentGreen),
                      const SizedBox(width: 12),
                      _macroLabel(
                          'C', '${(carbsR * 100).round()}%', AppColors.accent),
                      const SizedBox(width: 12),
                      _macroLabel(
                          'F', '${(fatR * 100).round()}%', AppColors.secondary),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRatioBar(double protein, double carbs, double fat) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: [
          Expanded(
            flex: (protein * 100).round(),
            child: Container(height: 6, color: AppColors.accentGreen),
          ),
          Expanded(
            flex: (carbs * 100).round(),
            child: Container(height: 6, color: AppColors.accent),
          ),
          Expanded(
            flex: (fat * 100).round(),
            child: Container(height: 6, color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _macroLabel(String letter, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 4),
        Text(
          '$letter $value',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTargetSummary(NutritionTarget target) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTargetRow(
              'Daily calories',
              '${target.baseCalories.round()} kcal',
              Icons.local_fire_department),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMacroBox(
                  'Protein',
                  '${target.proteinGrams.round()}g',
                  AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBox(
                  'Carbs',
                  '${target.carbsGrams.round()}g',
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroBox(
                  'Fat',
                  '${target.fatGrams.round()}g',
                  AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayVariationRow(NutritionTarget target) {
    return Row(
      children: [
        Expanded(
          child: _buildVariationCard(
            'Training day',
            '${target.trainingDayCalories.round()} kcal',
            AppColors.primary,
            Icons.fitness_center,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildVariationCard(
            'Rest day',
            '${target.restDayCalories.round()} kcal',
            AppColors.textSecondary,
            Icons.bedtime_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildVariationCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildMacroBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton(bool hasProfileData) {
    final canApply = hasProfileData && _selectedPreset != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('applyTargetButton'),
        onPressed: canApply && !_saving ? _applyPreset : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Calculate & save targets',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _applyPreset() async {
    if (_selectedPreset == null) return;
    setState(() => _saving = true);
    final success = await ref
        .read(nutritionTargetNotifierProvider.notifier)
        .applyPreset(_selectedPreset!);
    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Targets updated'),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save targets — check your profile'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
