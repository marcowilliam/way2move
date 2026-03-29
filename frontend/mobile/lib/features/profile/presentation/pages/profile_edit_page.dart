import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  TrainingGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;
  int _trainingDaysPerWeek = 3;
  final Set<String> _selectedSports = {};
  final Set<String> _selectedEquipment = {};
  bool _initialized = false;
  bool _saving = false;

  static const _sportOptions = [
    'Running', 'Climbing', 'Swimming', 'Cycling', 'Yoga',
    'CrossFit', 'Weightlifting', 'Martial Arts', 'Tennis',
    'Basketball', 'Soccer', 'Hiking', 'Dance', 'Gymnastics',
    'General Fitness',
  ];

  static const _equipmentOptions = [
    ('bodyweight', 'Bodyweight'), ('dumbbells', 'Dumbbells'),
    ('barbell', 'Barbell'), ('kettlebell', 'Kettlebell'),
    ('bands', 'Resistance Bands'), ('cable_machine', 'Cable Machine'),
    ('pull_up_bar', 'Pull-up Bar'), ('bench', 'Bench'),
    ('foam_roller', 'Foam Roller'), ('lacrosse_ball', 'Lacrosse Ball'),
    ('yoga_mat', 'Yoga Mat'),
  ];

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _ageController.text = profile.age?.toString() ?? '';
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _selectedGoal = profile.trainingGoal;
    _selectedActivityLevel = profile.activityLevel;
    _trainingDaysPerWeek = profile.trainingDaysPerWeek ?? 3;
    _selectedSports.addAll(profile.sportsTags);
    _selectedEquipment.addAll(profile.availableEquipment);
  }

  Future<void> _save() async {
    final profile = ref.read(profileStreamProvider).valueOrNull;
    if (profile == null) return;

    setState(() => _saving = true);

    final updated = profile.copyWith(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text),
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      activityLevel: _selectedActivityLevel,
      trainingGoal: _selectedGoal,
      sportsTags: _selectedSports.toList(),
      trainingDaysPerWeek: _trainingDaysPerWeek,
      availableEquipment: _selectedEquipment.toList(),
    );

    final result =
        await ref.read(profileNotifierProvider.notifier).updateProfile(updated);

    if (mounted) {
      setState(() => _saving = false);
      result.fold(
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save profile')),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated'),
              duration: Duration(seconds: 1),
            ),
          );
          context.pop();
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileStreamProvider);

    return Scaffold(
      key: AppKeys.profileEditPage,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          _initFromProfile(profile);
          return _buildForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic info
          _sectionTitle('Basic Info'),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          _sectionTitle('Training Goal'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrainingGoal.values.map((goal) {
              final isSelected = _selectedGoal == goal;
              return ChoiceChip(
                label: Text(_goalLabel(goal)),
                selected: isSelected,
                onSelected: (s) =>
                    setState(() => _selectedGoal = s ? goal : null),
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          _sectionTitle('Activity Level'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ActivityLevel.values.map((level) {
              final isSelected = _selectedActivityLevel == level;
              return ChoiceChip(
                label: Text(_activityLabel(level)),
                selected: isSelected,
                onSelected: (s) =>
                    setState(() => _selectedActivityLevel = s ? level : null),
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          _sectionTitle('Training Days per Week'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isSelected = _trainingDaysPerWeek == day;
              return GestureDetector(
                onTap: () => setState(() => _trainingDaysPerWeek = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 32),
          _sectionTitle('Sports & Activities'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sportOptions.map((sport) {
              final tag = sport.toLowerCase().replaceAll(' ', '_');
              final isSelected = _selectedSports.contains(tag);
              return FilterChip(
                label: Text(sport),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSports.add(tag);
                    } else {
                      _selectedSports.remove(tag);
                    }
                  });
                },
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                checkmarkColor: AppColors.primaryDark,
              );
            }).toList(),
          ),

          const SizedBox(height: 32),
          _sectionTitle('Available Equipment'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentOptions.map((entry) {
              final isSelected = _selectedEquipment.contains(entry.$1);
              return FilterChip(
                label: Text(entry.$2),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEquipment.add(entry.$1);
                    } else {
                      _selectedEquipment.remove(entry.$1);
                    }
                  });
                },
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.3),
                checkmarkColor: AppColors.primaryDark,
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  String _goalLabel(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.generalFitness:
        return 'General Fitness';
      case TrainingGoal.strength:
        return 'Strength';
      case TrainingGoal.mobility:
        return 'Mobility';
      case TrainingGoal.longevity:
        return 'Longevity';
      case TrainingGoal.sportSpecific:
        return 'Sport-Specific';
      case TrainingGoal.rehab:
        return 'Rehab';
    }
  }

  String _activityLabel(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }
}
