import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/assessment.dart';
import '../../domain/services/compensation_detection_service.dart';
import '../providers/assessment_providers.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// ── Local form state ──────────────────────────────────────────────────────────

class _FormState {
  final String? occupation;
  final String? sittingHours;
  final bool neckPain;
  final bool lowerBackPain;
  final bool kneePain;
  final bool isRunner;
  final bool anklePain;
  final bool shoulderPainOverhead;

  const _FormState({
    this.occupation,
    this.sittingHours,
    this.neckPain = false,
    this.lowerBackPain = false,
    this.kneePain = false,
    this.isRunner = false,
    this.anklePain = false,
    this.shoulderPainOverhead = false,
  });

  _FormState copyWith({
    String? occupation,
    String? sittingHours,
    bool? neckPain,
    bool? lowerBackPain,
    bool? kneePain,
    bool? isRunner,
    bool? anklePain,
    bool? shoulderPainOverhead,
  }) =>
      _FormState(
        occupation: occupation ?? this.occupation,
        sittingHours: sittingHours ?? this.sittingHours,
        neckPain: neckPain ?? this.neckPain,
        lowerBackPain: lowerBackPain ?? this.lowerBackPain,
        kneePain: kneePain ?? this.kneePain,
        isRunner: isRunner ?? this.isRunner,
        anklePain: anklePain ?? this.anklePain,
        shoulderPainOverhead: shoulderPainOverhead ?? this.shoulderPainOverhead,
      );

  Map<String, dynamic> toAnswersMap() => {
        'occupation': occupation,
        'sittingHours': sittingHours,
        'neckPain': neckPain,
        'lowerBackPain': lowerBackPain,
        'kneePain': kneePain,
        'isRunner': isRunner,
        'anklePain': anklePain,
        'shoulderPainOverhead': shoulderPainOverhead,
      };
}

// Total steps: 0=intro, 1=occupation, 2=sitting, 3=pain areas,
//              4=running, 5=processing, 6=results
const int _totalSteps = 7;

// ── Page ──────────────────────────────────────────────────────────────────────

class InitialAssessmentFlow extends ConsumerStatefulWidget {
  const InitialAssessmentFlow({super.key});

  @override
  ConsumerState<InitialAssessmentFlow> createState() =>
      _InitialAssessmentFlowState();
}

class _InitialAssessmentFlowState extends ConsumerState<InitialAssessmentFlow> {
  final _pageController = PageController();
  int _currentStep = 0;
  _FormState _form = const _FormState();
  List<CompensationPattern> _detectedPatterns = [];
  double _overallScore = 10.0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      if (_currentStep == 5) _runDetection();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _runDetection() {
    final answers = _form.toAnswersMap();
    final patterns = CompensationDetectionService.detectCompensations(answers);
    final score = CompensationDetectionService.calculateOverallScore(patterns);
    setState(() {
      _detectedPatterns = patterns;
      _overallScore = score;
    });
    // Auto-advance to results after brief delay
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _nextStep();
    });
  }

  Future<void> _saveAndFinish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.go(Routes.home);
      return;
    }

    final assessment = Assessment(
      id: '',
      userId: userId,
      date: DateTime.now(),
      answers: _form.toAnswersMap(),
      compensationResults: _detectedPatterns,
      movementScores: const [],
      overallScore: _overallScore,
    );

    await ref.read(createAssessmentProvider.notifier).submit(assessment);

    if (mounted) context.go(Routes.home);
  }

  Future<void> _saveAndRecordVideo() async {
    if (_saving) return;
    setState(() => _saving = true);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.go(Routes.home);
      return;
    }

    final assessment = Assessment(
      id: '',
      userId: userId,
      date: DateTime.now(),
      answers: _form.toAnswersMap(),
      compensationResults: _detectedPatterns,
      movementScores: const [],
      overallScore: _overallScore,
    );

    final saved =
        await ref.read(createAssessmentProvider.notifier).submit(assessment);

    if (mounted) {
      if (saved != null) {
        context.go(
          Routes.movementRecording,
          extra: {'assessmentId': saved.id, 'userId': userId},
        );
      } else {
        context.go(Routes.home);
      }
    }
  }

  Future<void> _saveAndBuildProgram() async {
    if (_saving) return;
    setState(() => _saving = true);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      context.go(Routes.home);
      return;
    }

    final assessment = Assessment(
      id: '',
      userId: userId,
      date: DateTime.now(),
      answers: _form.toAnswersMap(),
      compensationResults: _detectedPatterns,
      movementScores: const [],
      overallScore: _overallScore,
    );

    final saved =
        await ref.read(createAssessmentProvider.notifier).submit(assessment);

    if (mounted) {
      if (saved != null) {
        context.go('${Routes.programBuilder}?fromAssessment=${saved.id}');
      } else {
        context.go(Routes.home);
      }
    }
  }

  bool get _canAdvanceOccupation => _form.occupation != null;
  bool get _canAdvanceSitting => _form.sittingHours != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.assessmentFlow,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepIntro(onStart: _nextStep),
                  _StepOccupation(
                    selected: _form.occupation,
                    onSelected: (v) {
                      setState(() => _form = _form.copyWith(occupation: v));
                    },
                    onNext: _canAdvanceOccupation ? _nextStep : null,
                  ),
                  _StepSittingHours(
                    selected: _form.sittingHours,
                    onSelected: (v) {
                      setState(() => _form = _form.copyWith(sittingHours: v));
                    },
                    onNext: _canAdvanceSitting ? _nextStep : null,
                  ),
                  _StepPainAreas(
                    form: _form,
                    onChanged: (updated) => setState(() => _form = updated),
                    onNext: _nextStep,
                  ),
                  _StepRunning(
                    isRunner: _form.isRunner,
                    onChanged: (v) =>
                        setState(() => _form = _form.copyWith(isRunner: v)),
                    onNext: _nextStep,
                  ),
                  const _StepProcessing(),
                  _StepResults(
                    patterns: _detectedPatterns,
                    overallScore: _overallScore,
                    saving: _saving,
                    onBuildProgram: _saveAndBuildProgram,
                    onRecordVideo: _saveAndRecordVideo,
                    onSaveOnly: _saveAndFinish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final showBack = _currentStep > 0 && _currentStep < 5;
    final showDots = _currentStep > 0 && _currentStep < 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: _prevStep,
              color: theme.colorScheme.onSurface,
            )
          else
            const SizedBox(width: AppSpacing.minTapTarget),
          if (showDots)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: WayMotion.standard,
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
            )
          else
            const Spacer(),
          if (_currentStep == 0)
            TextButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Skip'),
            )
          else
            const SizedBox(width: AppSpacing.minTapTarget),
        ],
      ),
    );
  }
}

// ── Step widgets ──────────────────────────────────────────────────────────────

class _StepIntro extends StatelessWidget {
  final VoidCallback onStart;
  const _StepIntro({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.accessibility_new_rounded,
              size: 48,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Movement Assessment',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A few quiet questions to find your movement patterns.',
            style: AppTypography.fraunces(
              size: 18,
              weight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
              style: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'About 2 minutes',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('Start Assessment'),
          ),
        ],
      ),
    );
  }
}

class _StepOccupation extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback? onNext;
  const _StepOccupation({
    required this.selected,
    required this.onSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionScaffold(
      question: 'What best describes your main occupation?',
      onNext: onNext,
      child: Column(
        children: [
          _OptionCard(
            label: 'Desk / Office Work',
            icon: Icons.laptop_outlined,
            selected: selected == 'desk',
            onTap: () => onSelected('desk'),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            label: 'Active / Physical Work',
            icon: Icons.directions_run_rounded,
            selected: selected == 'active',
            onTap: () => onSelected('active'),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            label: 'Mixed / Varies',
            icon: Icons.swap_horiz_rounded,
            selected: selected == 'mixed',
            onTap: () => onSelected('mixed'),
          ),
        ],
      ),
    );
  }
}

class _StepSittingHours extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback? onNext;
  const _StepSittingHours({
    required this.selected,
    required this.onSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionScaffold(
      question: 'How many hours per day do you typically sit?',
      onNext: onNext,
      child: Column(
        children: [
          _OptionCard(
            label: 'Less than 2 hours',
            icon: Icons.chair_alt_outlined,
            selected: selected == 'lt2',
            onTap: () => onSelected('lt2'),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            label: '2 – 4 hours',
            icon: Icons.chair_alt_outlined,
            selected: selected == '2to4',
            onTap: () => onSelected('2to4'),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            label: '4 – 6 hours',
            icon: Icons.chair_alt_outlined,
            selected: selected == '4to6',
            onTap: () => onSelected('4to6'),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            label: 'More than 6 hours',
            icon: Icons.chair_alt_outlined,
            selected: selected == 'gt6',
            onTap: () => onSelected('gt6'),
          ),
        ],
      ),
    );
  }
}

class _StepPainAreas extends StatelessWidget {
  final _FormState form;
  final ValueChanged<_FormState> onChanged;
  final VoidCallback onNext;
  const _StepPainAreas({
    required this.form,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionScaffold(
      question: 'Do you experience pain or discomfort in any of these areas?',
      subtitle: 'Select all that apply',
      onNext: onNext,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ToggleChip(
            label: 'Neck / Upper Back',
            selected: form.neckPain,
            onToggled: (v) => onChanged(form.copyWith(neckPain: v)),
          ),
          _ToggleChip(
            label: 'Lower Back',
            selected: form.lowerBackPain,
            onToggled: (v) => onChanged(form.copyWith(lowerBackPain: v)),
          ),
          _ToggleChip(
            label: 'Knees',
            selected: form.kneePain,
            onToggled: (v) => onChanged(form.copyWith(kneePain: v)),
          ),
          _ToggleChip(
            label: 'Ankles / Feet',
            selected: form.anklePain,
            onToggled: (v) => onChanged(form.copyWith(anklePain: v)),
          ),
          _ToggleChip(
            label: 'Shoulders / Overhead',
            selected: form.shoulderPainOverhead,
            onToggled: (v) => onChanged(form.copyWith(shoulderPainOverhead: v)),
          ),
        ],
      ),
    );
  }
}

class _StepRunning extends StatelessWidget {
  final bool isRunner;
  final ValueChanged<bool> onChanged;
  final VoidCallback onNext;
  const _StepRunning({
    required this.isRunner,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _QuestionScaffold(
      question: 'Are you a regular runner or runner-in-training?',
      onNext: onNext,
      child: Column(
        children: [
          _OptionCard(
            label: 'Yes, I run regularly',
            icon: Icons.directions_run_rounded,
            selected: isRunner,
            onTap: () => onChanged(true),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            label: "No, running isn't my thing",
            icon: Icons.do_not_disturb_alt_outlined,
            selected: !isRunner,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _StepProcessing extends StatefulWidget {
  const _StepProcessing();

  @override
  State<_StepProcessing> createState() => _StepProcessingState();
}

class _StepProcessingState extends State<_StepProcessing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Analysing your movement profile…',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepResults extends StatelessWidget {
  final List<CompensationPattern> patterns;
  final double overallScore;
  final bool saving;
  final VoidCallback onBuildProgram;
  final VoidCallback onRecordVideo;
  final VoidCallback onSaveOnly;

  const _StepResults({
    required this.patterns,
    required this.overallScore,
    required this.saving,
    required this.onBuildProgram,
    required this.onRecordVideo,
    required this.onSaveOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Your movement profile',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(value: overallScore / 10),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            overallScore.toStringAsFixed(1),
                            style: AppTypography.fraunces(
                              size: 52,
                              weight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -1.5,
                            ),
                          ),
                          Text(
                            'out of 10',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (patterns.isEmpty)
            const _ResultBanner(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.accent,
              title: 'No significant patterns found',
              subtitle:
                  'Your movement profile looks solid. Keep up the good work.',
            )
          else ...[
            Text(
              'Detected patterns',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            ...patterns.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PatternTile(pattern: p),
                )),
            const SizedBox(height: AppSpacing.sm),
            const _ResultBanner(
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.primary,
              title: 'Corrective exercises are ready',
              subtitle:
                  'Build your personalised program to address these patterns.',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (saving)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton(
              onPressed: onBuildProgram,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Build my program'),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            OutlinedButton.icon(
              onPressed: onRecordVideo,
              icon: const Icon(Icons.videocam_outlined),
              label: const Text('Record movement video'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            TextButton(
              onPressed: onSaveOnly,
              style: TextButton.styleFrom(
                minimumSize:
                    const Size(double.infinity, AppSpacing.minTapTarget),
              ),
              child: const Text('Save & continue'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double value;
  _ScoreRingPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bg = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bg);

    final sweep = value.clamp(0.0, 1.0) * 3.14159 * 2;
    final fg = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.primary, AppColors.accent],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -3.14159 / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.value != value;
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _QuestionScaffold extends StatelessWidget {
  final String question;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onNext;

  const _QuestionScaffold({
    required this.question,
    required this.child,
    this.subtitle,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
            question,
            style: AppTypography.fraunces(
              size: 24,
              weight: FontWeight.w400,
              color: theme.colorScheme.onSurface,
              style: FontStyle.italic,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: AppSpacing.md),
          AnimatedOpacity(
            opacity: onNext != null ? 1.0 : 0.4,
            duration: WayMotion.micro,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

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
                color: selected ? AppColors.primary : theme.colorScheme.outline,
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
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface,
                    ),
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

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onToggled;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onToggled,
      showCheckmark: true,
    );
  }
}

class _PatternTile extends StatelessWidget {
  final CompensationPattern pattern;
  const _PatternTile({required this.pattern});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CompensationDetectionService.labelFor(pattern),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                'Moderate',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.severityModerate,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: theme.colorScheme.outlineVariant,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.6,
                child: Container(color: AppColors.severityModerate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ResultBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
