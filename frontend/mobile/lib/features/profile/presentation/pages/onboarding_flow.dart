import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;
  int _currentStep = 0;

  // Form data
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  TrainingGoal? _selectedGoal;
  ActivityLevel? _selectedActivityLevel;
  final Set<String> _selectedSports = {};
  int _trainingDaysPerWeek = 3;
  final Set<String> _selectedEquipment = {};
  final List<Injury> _injuries = [];
  bool _saving = false;

  static const _totalSteps = 6;

  static const _sportOptions = [
    'Running',
    'Climbing',
    'Swimming',
    'Cycling',
    'Yoga',
    'CrossFit',
    'Weightlifting',
    'Martial Arts',
    'Tennis',
    'Basketball',
    'Soccer',
    'Hiking',
    'Dance',
    'Gymnastics',
    'General Fitness',
  ];

  static const _equipmentOptions = [
    ('bodyweight', 'Bodyweight'),
    ('dumbbells', 'Dumbbells'),
    ('barbell', 'Barbell'),
    ('kettlebell', 'Kettlebell'),
    ('bands', 'Resistance Bands'),
    ('cable_machine', 'Cable Machine'),
    ('pull_up_bar', 'Pull-up Bar'),
    ('bench', 'Bench'),
    ('foam_roller', 'Foam Roller'),
    ('lacrosse_ball', 'Lacrosse Ball'),
    ('yoga_mat', 'Yoga Mat'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _updateProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    _progressController.animateTo((_currentStep + 1) / _totalSteps);
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _updateProgress();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      _updateProgress();
    }
  }

  Future<void> _complete() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _saving = true);

    final profile = UserProfile(
      id: userId,
      name: _nameController.text.trim().isEmpty
          ? 'Athlete'
          : _nameController.text.trim(),
      email: '', // preserved from existing Firestore doc via merge
      age: int.tryParse(_ageController.text),
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      activityLevel: _selectedActivityLevel,
      trainingGoal: _selectedGoal,
      sportsTags: _selectedSports.toList(),
      trainingDaysPerWeek: _trainingDaysPerWeek,
      availableEquipment: _selectedEquipment.toList(),
      injuries: _injuries,
      onboardingComplete: true,
      createdAt: DateTime.now(),
    );

    final result =
        await ref.read(profileNotifierProvider.notifier).completeOnboarding(
              profile,
            );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save profile')),
          );
        },
        (_) => context.go(Routes.home),
      );
    }
  }

  bool get _canAdvance {
    switch (_currentStep) {
      case 0:
        return true; // welcome — always can advance
      case 1:
        return true; // name/age/body — optional fields
      case 2:
        return _selectedGoal != null;
      case 3:
        return _selectedActivityLevel != null;
      case 4:
        return true; // sports — optional
      case 5:
        return true; // equipment — optional
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.onboardingFlow,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      key: AppKeys.onboardingBackButton,
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _back,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    key: AppKeys.onboardingSkipButton,
                    onPressed: _saving ? null : _complete,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildWelcomeStep(),
                  _buildBasicInfoStep(),
                  _buildGoalStep(),
                  _buildActivityLevelStep(),
                  _buildSportsStep(),
                  _buildEquipmentStep(),
                ],
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedOpacity(
                  opacity: _canAdvance ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: FilledButton(
                    key: _currentStep == _totalSteps - 1
                        ? AppKeys.onboardingDoneButton
                        : AppKeys.onboardingNextButton,
                    onPressed: (_canAdvance && !_saving)
                        ? (_currentStep == _totalSteps - 1 ? _complete : _next)
                        : null,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : Text(
                            _currentStep == 0
                                ? 'Begin'
                                : _currentStep == _totalSteps - 1
                                    ? 'Get Started'
                                    : 'Continue',
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _GroundedFigure(size: 160),
          const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
          Text(
            "Let's build\nthe foundation.",
            style: AppTypography.fraunces(
              size: 36,
              weight: FontWeight.w400,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              style: FontStyle.italic,
              letterSpacing: -0.5,
            ).copyWith(height: 1.15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Train from the ground up — pelvis, ribcage, gait. Two minutes to set you up.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'About You',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All fields are optional — fill in what you\'re comfortable with.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          TextField(
            key: AppKeys.onboardingNameField,
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'How should we call you?',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          TextField(
            key: AppKeys.onboardingAgeField,
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: 'Years',
              prefixIcon: Icon(Icons.cake_outlined),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: AppKeys.onboardingHeightField,
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    hintText: 'cm',
                    prefixIcon: Icon(Icons.height),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  key: AppKeys.onboardingWeightField,
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    hintText: 'kg',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'What\'s your main goal?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us tailor your program recommendations.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ..._goalOptions.map((entry) => _buildSelectionTile(
                icon: entry.$1,
                label: entry.$2,
                subtitle: entry.$3,
                isSelected: _selectedGoal == entry.$4,
                onTap: () => setState(() => _selectedGoal = entry.$4),
              )),
        ],
      ),
    );
  }

  static const _goalOptions = [
    (
      Icons.fitness_center,
      'General Fitness',
      'Move better, feel better',
      TrainingGoal.generalFitness
    ),
    (Icons.bolt, 'Strength', 'Build strength and power', TrainingGoal.strength),
    (
      Icons.self_improvement,
      'Mobility',
      'Improve flexibility and range',
      TrainingGoal.mobility
    ),
    (
      Icons.favorite_border,
      'Longevity',
      'Move well for life',
      TrainingGoal.longevity
    ),
    (
      Icons.sports,
      'Sport-Specific',
      'Improve performance in a sport',
      TrainingGoal.sportSpecific
    ),
    (Icons.healing, 'Rehab', 'Recover from injury', TrainingGoal.rehab),
  ];

  Widget _buildActivityLevelStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'How active are you currently?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          ..._activityOptions.map((entry) => _buildSelectionTile(
                icon: entry.$1,
                label: entry.$2,
                subtitle: entry.$3,
                isSelected: _selectedActivityLevel == entry.$4,
                onTap: () => setState(() => _selectedActivityLevel = entry.$4),
              )),
          const SizedBox(height: 24),
          Text(
            'Training days per week',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
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
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
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
        ],
      ),
    );
  }

  static const _activityOptions = [
    (
      Icons.weekend,
      'Sedentary',
      'Little to no exercise',
      ActivityLevel.sedentary
    ),
    (
      Icons.directions_walk,
      'Lightly Active',
      'Light exercise 1-2 days/week',
      ActivityLevel.lightlyActive
    ),
    (
      Icons.directions_run,
      'Moderately Active',
      'Moderate exercise 3-5 days/week',
      ActivityLevel.moderatelyActive
    ),
    (
      Icons.sports_martial_arts,
      'Very Active',
      'Hard exercise 6-7 days/week',
      ActivityLevel.veryActive
    ),
    (
      Icons.local_fire_department,
      'Extremely Active',
      'Intense daily training',
      ActivityLevel.extremelyActive
    ),
  ];

  Widget _buildSportsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'What sports or activities do you do?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply. This helps us suggest relevant exercises.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }

  Widget _buildEquipmentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'What equipment do you have access to?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll only recommend exercises you can actually do.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }

  Widget _buildSelectionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stylized standing figure on a terracotta ground line — echoes the logo
/// mark's "rooted" construction. Used on the onboarding welcome and the
/// home-dashboard empty state (§4 of the discovery plan).
class _GroundedFigure extends StatelessWidget {
  const _GroundedFigure({this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GroundedFigurePainter()),
    );
  }
}

class _GroundedFigurePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head.
    canvas.drawCircle(Offset(w / 2, h * 0.24), w * 0.08, bodyPaint);

    // Torso.
    final torso = Path()
      ..moveTo(w / 2, h * 0.32)
      ..lineTo(w / 2, h * 0.60);
    canvas.drawPath(torso, bodyPaint);

    // Arms — slight outward curve.
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.38)
        ..quadraticBezierTo(w * 0.30, h * 0.48, w * 0.28, h * 0.60),
      bodyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.38)
        ..quadraticBezierTo(w * 0.70, h * 0.48, w * 0.72, h * 0.60),
      bodyPaint,
    );

    // Legs — standing, shoulder-width apart.
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.60)
        ..lineTo(w * 0.40, h * 0.86),
      bodyPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.60)
        ..lineTo(w * 0.60, h * 0.86),
      bodyPaint,
    );

    // Terracotta ground line — "foundation".
    final groundPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.14, h * 0.88),
      Offset(w * 0.86, h * 0.88),
      groundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GroundedFigurePainter old) => false;
}
