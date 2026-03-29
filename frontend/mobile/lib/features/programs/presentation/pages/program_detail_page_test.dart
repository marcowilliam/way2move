import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/programs/domain/entities/program.dart';
import 'package:way2move/features/programs/presentation/pages/program_detail_page.dart';
import 'package:way2move/features/programs/presentation/providers/program_providers.dart';

void main() {
  final kProgram = Program(
    id: 'prog1',
    userId: 'user1',
    name: 'Corrective Movement Program',
    goal: 'Address 3 detected movement patterns',
    durationWeeks: 8,
    weekTemplate: WeekTemplate(days: {
      for (int i = 0; i < 7; i++) i: DayTemplate.rest,
    }),
    isActive: true,
    createdAt: DateTime(2026, 3, 1),
  );

  Widget wrap({required AsyncValue<Program?> programState}) {
    return ProviderScope(
      overrides: [
        activeProgramProvider.overrideWith(() {
          return _FakeActiveProgramNotifier(programState);
        }),
      ],
      child: const MaterialApp(home: ProgramDetailPage()),
    );
  }

  testWidgets('shows loading indicator while loading', (tester) async {
    await tester.pumpWidget(
      wrap(programState: const AsyncLoading()),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no active program', (tester) async {
    await tester.pumpWidget(wrap(programState: const AsyncData(null)));
    await tester.pump();
    expect(find.textContaining('No active program'), findsOneWidget);
  });

  testWidgets('shows program name and goal', (tester) async {
    await tester.pumpWidget(wrap(programState: AsyncData(kProgram)));
    await tester.pump();
    expect(find.byKey(AppKeys.programDetailPage), findsOneWidget);
    expect(find.text('Corrective Movement Program'), findsOneWidget);
    expect(find.textContaining('Address 3 detected'), findsOneWidget);
  });
}

class _FakeActiveProgramNotifier extends ActiveProgramNotifier {
  final AsyncValue<Program?> initial;
  _FakeActiveProgramNotifier(this.initial);

  @override
  Future<Program?> build() async {
    state = initial;
    return initial.valueOrNull;
  }
}
