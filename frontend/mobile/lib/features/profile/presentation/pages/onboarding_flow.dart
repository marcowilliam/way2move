import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: WayMotion.standard,
        curve: WayMotion.easeStandard,
      );
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: WayMotion.standard,
        curve: WayMotion.easeStandard,
      );
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
        return true; // body info — optional fields
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
            _buildHeader(),
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
            // Bottom button — pinned, theme-defaulted to terracotta.
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedOpacity(
                  opacity: _canAdvance ? 1.0 : 0.4,
                  duration: WayMotion.micro,
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

  // ── Header — back · stretching dots · skip ────────────────────────────────

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              key: AppKeys.onboardingBackButton,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: _back,
              color: theme.colorScheme.onSurface,
            )
          else
            const SizedBox(width: AppSpacing.minTapTarget),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _totalSteps; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: WayMotion.standard,
                      curve: WayMotion.easeStandard,
                      width: i <= _currentStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? AppColors.primary
                            : theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            key: AppKeys.onboardingSkipButton,
            onPressed: _saving ? null : _complete,
            child: Text(
              'Skip',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0 — Welcome (already revamped in v1.0; left untouched) ───────────

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
            'Pelvis, ribcage, gait. Two minutes to set you up.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Basic info (revamped) ────────────────────────────────────────

  Widget _buildBasicInfoStep() {
    return _StepShell(
      prompt: 'A little about your body.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: AppKeys.onboardingNameField,
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'How should we call you?',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: AppKeys.onboardingAgeField,
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: 'Years',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: AppKeys.onboardingHeightField,
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  key: AppKeys.onboardingWeightField,
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight',
                    suffixText: 'kg',
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

  // ── Step 2 — Goal (revamped) ─────────────────────────────────────────────

  Widget _buildGoalStep() {
    return _StepShell(
      prompt: "What's your main goal?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _goalOptions
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                child: _OnboardingOptionCard(
                  icon: entry.$1,
                  label: entry.$2,
                  subtitle: entry.$3,
                  selected: _selectedGoal == entry.$4,
                  onTap: () => setState(() => _selectedGoal = entry.$4),
                ),
              ),
            )
            .toList(),
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

  // ── Step 3 — Activity level (revamped) ───────────────────────────────────

  Widget _buildActivityLevelStep() {
    final theme = Theme.of(context);
    return _StepShell(
      prompt: 'How active are you right now?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._activityOptions.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
              child: _OnboardingOptionCard(
                icon: entry.$1,
                label: entry.$2,
                subtitle: entry.$3,
                selected: _selectedActivityLevel == entry.$4,
                onTap: () =>
                    setState(() => _selectedActivityLevel = entry.$4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Training days per week',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final day = i + 1;
              final isSelected = _trainingDaysPerWeek == day;
              return GestureDetector(
                onTap: () => setState(() => _trainingDaysPerWeek = day),
                child: AnimatedContainer(
                  duration: WayMotion.micro,
                  curve: WayMotion.easeMicro,
                  width: AppSpacing.minTapTarget - 8,
                  height: AppSpacing.minTapTarget - 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : theme.colorScheme.onSurface,
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

  // ── Step 4 — Sports (revamped) ───────────────────────────────────────────

  Widget _buildSportsStep() {
    return _StepShell(
      prompt: 'What movement do you do?',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _sportOptions.map((sport) {
          final tag = sport.toLowerCase().replaceAll(' ', '_');
          final isSelected = _selectedSports.contains(tag);
          return _OnboardingTagPill(
            label: sport,
            selected: isSelected,
            onTap: () => setState(() {
              if (isSelected) {
                _selectedSports.remove(tag);
              } else {
                _selectedSports.add(tag);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 5 — Equipment (revamped) ────────────────────────────────────────

  Widget _buildEquipmentStep() {
    return _StepShell(
      prompt: 'What do you have access to?',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: _equipmentOptions.map((entry) {
          final isSelected = _selectedEquipment.contains(entry.$1);
          return _OnboardingTagPill(
            label: entry.$2,
            selected: isSelected,
            onTap: () => setState(() {
              if (isSelected) {
                _selectedEquipment.remove(entry.$1);
              } else {
                _selectedEquipment.add(entry.$1);
              }
            }),
          );
        }).toList(),
      ),
    );
  }
}

// ── Shared step shell — Fraunces italic prompt + scrollable content ─────────

class _StepShell extends StatelessWidget {
  const _StepShell({required this.prompt, required this.child});

  final String prompt;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt,
            style: AppTypography.fraunces(
              size: 24,
              weight: FontWeight.w400,
              color: theme.colorScheme.onSurface,
              style: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// ── Option card — terracotta 4px left strip on selected ─────────────────────

class _OnboardingOptionCard extends StatelessWidget {
  const _OnboardingOptionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: WayMotion.standard,
            curve: WayMotion.easeStandard,
            padding: EdgeInsets.fromLTRB(
              selected ? AppSpacing.md + 4 : AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color:
                    selected ? AppColors.primary : theme.colorScheme.outline,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: selected
                              ? AppColors.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tag pill — sage outlined chip, terracotta text on selected ─────────────

class _OnboardingTagPill extends StatelessWidget {
  const _OnboardingTagPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: WayMotion.micro,
        curve: WayMotion.easeMicro,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: selected ? 0.9 : 0.45),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.accent,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ── Welcome step illustration (kept from v1.0) ──────────────────────────────

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
