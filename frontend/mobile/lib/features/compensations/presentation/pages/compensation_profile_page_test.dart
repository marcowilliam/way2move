import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/compensations/domain/entities/compensation.dart';
import 'package:way2move/features/compensations/domain/repositories/compensation_repository.dart';
import 'package:way2move/features/compensations/data/repositories/compensation_repository_impl.dart';
import 'package:way2move/features/compensations/presentation/pages/compensation_profile_page.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

Widget _buildPage({
  CompensationRepository? repo,
  List<Compensation>? compensations,
}) {
  final mockRepo = repo ?? MockCompensationRepository();

  if (compensations != null) {
    when(() => mockRepo.watchByUser(any()))
        .thenAnswer((_) => Stream.value(compensations));
  } else {
    when(() => mockRepo.watchByUser(any()))
        .thenAnswer((_) => const Stream.empty());
  }

  return ProviderScope(
    overrides: [
      compensationRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/compensations',
        routes: [
          GoRoute(
            path: '/compensations',
            builder: (_, __) => const CompensationProfilePage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, __) =>
                    const Scaffold(body: Text('Add Compensation')),
              ),
              GoRoute(
                path: ':compensationId',
                builder: (_, state) => Scaffold(
                  body:
                      Text('Detail: ${state.pathParameters['compensationId']}'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final _tActive = Compensation(
  id: 'comp1',
  userId: 'test-uid',
  name: 'Anterior Pelvic Tilt',
  type: CompensationType.posturalPattern,
  region: CompensationRegion.pelvis,
  severity: CompensationSeverity.moderate,
  status: CompensationStatus.active,
  origin: CompensationOrigin.assessment,
  detectedAt: DateTime(2026, 1, 1),
);

final _tImproving = Compensation(
  id: 'comp2',
  userId: 'test-uid',
  name: 'Rounded Shoulders',
  type: CompensationType.posturalPattern,
  region: CompensationRegion.leftShoulder,
  severity: CompensationSeverity.mild,
  status: CompensationStatus.improving,
  origin: CompensationOrigin.journal,
  detectedAt: DateTime(2026, 1, 2),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_tActive);
  });

  testWidgets('shows empty state when no compensations', (tester) async {
    final mockRepo = MockCompensationRepository();
    when(() => mockRepo.watchByUser(any())).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(_buildPage(repo: mockRepo, compensations: []));
    await tester.pumpAndSettle();

    expect(find.text('No compensations tracked'), findsOneWidget);
    expect(find.byKey(AppKeys.compensationProfilePage), findsOneWidget);
  });

  testWidgets('shows active compensation in the list', (tester) async {
    await tester.pumpWidget(_buildPage(compensations: [_tActive]));
    await tester.pumpAndSettle();

    expect(find.text('Anterior Pelvic Tilt'), findsOneWidget);
  });

  testWidgets('shows Active section header when there are active compensations',
      (tester) async {
    await tester.pumpWidget(_buildPage(compensations: [_tActive]));
    await tester.pumpAndSettle();

    expect(find.text('Active (1)'), findsOneWidget);
  });

  testWidgets('shows Improving section header for improving compensations',
      (tester) async {
    await tester.pumpWidget(_buildPage(compensations: [_tActive, _tImproving]));
    await tester.pumpAndSettle();

    expect(find.text('Improving (1)'), findsOneWidget);
  });

  testWidgets('body map is rendered when compensations exist', (tester) async {
    await tester.pumpWidget(_buildPage(compensations: [_tActive]));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.compensationBodyMap), findsOneWidget);
  });

  testWidgets('tapping a compensation tile navigates to detail',
      (tester) async {
    await tester.pumpWidget(_buildPage(compensations: [_tActive]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Anterior Pelvic Tilt'));
    await tester.pumpAndSettle();

    expect(find.text('Detail: comp1'), findsOneWidget);
  });

  testWidgets('add button navigates to compensation add route', (tester) async {
    await tester.pumpWidget(_buildPage(compensations: [_tActive]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Compensation'), findsOneWidget);
  });
}
