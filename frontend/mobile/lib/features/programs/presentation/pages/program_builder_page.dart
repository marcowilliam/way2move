import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_keys.dart';
import '../../../assessments/domain/entities/assessment.dart';
import '../../../assessments/presentation/providers/assessment_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/program.dart';
import '../../domain/usecases/generate_program_from_assessment.dart';
import '../providers/program_providers.dart';
import '../widgets/week_template_editor.dart';

/// Full-screen page for reviewing and saving a training program.
///
/// When [fromAssessmentId] is non-null, the page auto-generates an initial
/// program from the user's latest assessment compensations.
class ProgramBuilderPage extends ConsumerStatefulWidget {
  final String? fromAssessmentId;

  const ProgramBuilderPage({super.key, this.fromAssessmentId});

  @override
  ConsumerState<ProgramBuilderPage> createState() => _ProgramBuilderPageState();
}

class _ProgramBuilderPageState extends ConsumerState<ProgramBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _goalCtrl;
  int _durationWeeks = 8;
  WeekTemplate _weekTemplate = WeekTemplate.empty();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'My Movement Program');
    _goalCtrl = TextEditingController(text: 'Improve movement quality');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  void _initFromAssessment(
      List<CompensationPattern> compensations, String userId) {
    if (_initialized) return;
    _initialized = true;
    final program = GenerateProgramFromAssessment.call(
      compensations: compensations,
      userId: userId,
    );
    _nameCtrl.text = program.name;
    _goalCtrl.text = program.goal;
    _durationWeeks = program.durationWeeks;
    _weekTemplate = program.weekTemplate;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = ref.read(currentUserIdProvider) ?? '';
    final program = Program(
      id: '',
      userId: userId,
      name: _nameCtrl.text.trim(),
      goal: _goalCtrl.text.trim(),
      durationWeeks: _durationWeeks,
      weekTemplate: _weekTemplate,
      isActive: true,
      createdAt: DateTime.now(),
    );
    final saved =
        await ref.read(createProgramProvider.notifier).submit(program);
    if (saved != null && mounted) {
      Navigator.of(context).pop(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-initialize when fromAssessmentId is set
    if (widget.fromAssessmentId != null && !_initialized) {
      final userId = ref.watch(currentUserIdProvider) ?? '';
      ref.watch(latestAssessmentProvider).whenData((assessment) {
        if (assessment != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _initFromAssessment(assessment.compensationResults, userId);
              });
            }
          });
        }
      });
    }

    final isSaving = ref.watch(createProgramProvider).isLoading;

    return Scaffold(
      key: AppKeys.programBuilderPage,
      appBar: AppBar(
        title: const Text('Build Program'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Program details ──────────────────────────────────────────
              Text(
                'Program Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('program_name_field'),
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Program Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('program_goal_field'),
                controller: _goalCtrl,
                decoration: const InputDecoration(
                  labelText: 'Goal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Goal required' : null,
              ),
              const SizedBox(height: 12),
              _DurationPicker(
                value: _durationWeeks,
                onChanged: (v) => setState(() => _durationWeeks = v),
              ),
              const SizedBox(height: 24),

              // ── Week template ────────────────────────────────────────────
              Text(
                'Weekly Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              WeekTemplateEditor(
                template: _weekTemplate,
                onDayToggled: (updated) =>
                    setState(() => _weekTemplate = updated),
              ),
              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('save_program_button'),
                  onPressed: isSaving ? null : _save,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Program'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _DurationPicker({required this.value, required this.onChanged});

  static const _options = [4, 6, 8, 12, 16];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _options.map((w) {
            final selected = w == value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${w}w'),
                selected: selected,
                onSelected: (_) => onChanged(w),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
