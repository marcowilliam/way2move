import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../../core/router/routes.dart';
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
    final showBack = _currentStep > 0 && _currentStep < 5;
    final showProgress = _currentStep > 0 && _currentStep < 5;
    final progressValue = _currentStep / 4; // steps 1-4 out of 4

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: _prevStep,
            )
          else
            const SizedBox(width: 48),
          if (showProgress)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 4,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
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
            const SizedBox(width: 48),
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
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 52,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Movement Assessment',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Answer a few quick questions to identify your movement patterns and build a personalised corrective program.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Chip(
            avatar: Icon(Icons.timer_outlined, size: 16),
            label: Text('About 2 minutes'),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
  final VoidCallback onSaveOnly;

  const _StepResults({
    required this.patterns,
    required this.overallScore,
    required this.saving,
    required this.onBuildProgram,
    required this.onSaveOnly,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = overallScore >= 8
        ? Colors.green
        : overallScore >= 6
            ? Colors.orange
            : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'Your Movement Profile',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: overallScore / 10,
                        strokeWidth: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          overallScore.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '/ 10',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (patterns.isEmpty) ...[
            const _ResultBanner(
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green,
              title: 'No significant patterns found',
              subtitle:
                  'Your movement profile looks solid! Keep up the good work.',
            ),
          ] else ...[
            Text(
              'Detected patterns (${patterns.length})',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...patterns.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PatternTile(pattern: p),
                )),
            const SizedBox(height: 8),
            _ResultBanner(
              icon: Icons.lightbulb_outline_rounded,
              color: theme.colorScheme.primary,
              title: 'Corrective exercises are ready',
              subtitle:
                  'Build your personalised program to address these patterns.',
            ),
          ],
          const SizedBox(height: 32),
          if (saving)
            const Center(child: CircularProgressIndicator())
          else ...[
            FilledButton(
              onPressed: onBuildProgram,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Build My Program'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onSaveOnly,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save & Continue'),
            ),
          ],
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: onNext != null ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 200),
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: selected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.error.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              CompensationDetectionService.labelFor(pattern),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
