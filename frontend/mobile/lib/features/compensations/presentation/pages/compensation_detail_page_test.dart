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
import 'package:way2move/features/compensations/presentation/pages/compensation_detail_page.dart';

class MockCompensationRepository extends Mock
    implements CompensationRepository {}

final _tComp = Compensation(
  id: 'comp1',
  userId: 'test-uid',
  name: 'Anterior Pelvic Tilt',
  type: CompensationType.posturalPattern,
  region: CompensationRegion.pelvis,
  severity: CompensationSeverity.moderate,
  status: CompensationStatus.active,
  origin: CompensationOrigin.assessment,
  detectedAt: DateTime(2026, 1, 1),
  history: [
    CompensationHistoryEntry(
      date: DateTime(2026, 2, 1),
      severity: CompensationSeverity.moderate,
      status: CompensationStatus.active,
      note: 'Detected via assessment',
    ),
  ],
);

Widget _buildPage({
  required String compensationId,
  required List<Compensation> compensations,
  CompensationRepository? repo,
}) {
  final mockRepo = repo ?? MockCompensationRepository();
  when(() => mockRepo.watchByUser(any()))
      .thenAnswer((_) => Stream.value(compensations));

  return ProviderScope(
    overrides: [
      compensationRepositoryProvider.overrideWithValue(mockRepo),
      currentUserIdProvider.overrideWithValue('test-uid'),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/compensations/$compensationId',
        routes: [
          GoRoute(
            path: '/compensations/:compensationId',
            builder: (_, state) => CompensationDetailPage(
              compensationId: state.pathParameters['compensationId']!,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_tComp);
  });

  testWidgets('shows compensation name in AppBar', (tester) async {
    await tester.pumpWidget(
        _buildPage(compensationId: 'comp1', compensations: [_tComp]));
    await tester.pumpAndSettle();

    expect(find.text('Anterior Pelvic Tilt'), findsWidgets);
    expect(find.byKey(AppKeys.compensationDetailPage), findsOneWidget);
  });

  testWidgets('shows status card with region and type info', (tester) async {
    await tester.pumpWidget(
        _buildPage(compensationId: 'comp1', compensations: [_tComp]));
    await tester.pumpAndSettle();

    expect(find.text('Pelvis'), findsOneWidget);
    expect(find.text('Postural Pattern'), findsOneWidget);
    expect(find.text('Assessment'), findsOneWidget);
  });

  testWidgets('shows Active status badge', (tester) async {
    await tester.pumpWidget(
        _buildPage(compensationId: 'comp1', compensations: [_tComp]));
    await tester.pumpAndSettle();

    // Status badge appears at least once (also in history timeline)
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets('shows history timeline when history is not empty',
      (tester) async {
    await tester.pumpWidget(
        _buildPage(compensationId: 'comp1', compensations: [_tComp]));
    await tester.pumpAndSettle();

    expect(find.text('Progress History'), findsOneWidget);
    expect(find.text('Detected via assessment'), findsOneWidget);
  });

  testWidgets('shows not found message for unknown id', (tester) async {
    await tester.pumpWidget(
        _buildPage(compensationId: 'unknown', compensations: [_tComp]));
    await tester.pumpAndSettle();

    expect(find.text('Compensation not found'), findsOneWidget);
  });

  testWidgets('popup menu shows mark improving and resolved options',
      (tester) async {
    await tester.pumpWidget(
        _buildPage(compensationId: 'comp1', compensations: [_tComp]));
    await tester.pumpAndSettle();

    // Open popup menu
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Mark as Improving'), findsOneWidget);
    expect(find.text('Mark as Resolved'), findsOneWidget);
  });
}
