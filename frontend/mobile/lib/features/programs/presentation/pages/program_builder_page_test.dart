import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/programs/domain/entities/program.dart';
import 'package:way2move/features/programs/presentation/pages/program_builder_page.dart';
import 'package:way2move/features/programs/presentation/providers/program_providers.dart';
import 'package:way2move/features/programs/presentation/widgets/week_template_editor.dart';

void main() {
  Widget wrap() {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => 'user1'),
        createProgramProvider.overrideWith(
          () => _FakeCreateProgramNotifier(),
        ),
      ],
      child: const MaterialApp(home: ProgramBuilderPage()),
    );
  }

  testWidgets('renders program builder page with key', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.byKey(AppKeys.programBuilderPage), findsOneWidget);
  });

  testWidgets('shows name and goal text fields', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.byKey(const Key('program_name_field')), findsOneWidget);
    expect(find.byKey(const Key('program_goal_field')), findsOneWidget);
  });

  testWidgets('shows save program button', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.byKey(const Key('save_program_button')), findsOneWidget);
  });

  testWidgets('shows week template editor', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();
    expect(find.byType(WeekTemplateEditor), findsOneWidget);
  });
}

class _FakeCreateProgramNotifier extends CreateProgramNotifier {
  @override
  Future<Program?> build() async => null;

  @override
  Future<Program?> submit(Program program) async => null;
}
