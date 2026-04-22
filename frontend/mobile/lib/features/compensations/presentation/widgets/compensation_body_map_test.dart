import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:way2move/core/constants/app_keys.dart';
import 'package:way2move/features/compensations/domain/entities/compensation.dart';
import 'package:way2move/features/compensations/presentation/widgets/compensation_body_map.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 300, height: 600, child: child),
      ),
    );

final _tActive = Compensation(
  id: 'comp1',
  userId: 'u1',
  name: 'APT',
  type: CompensationType.posturalPattern,
  region: CompensationRegion.pelvis,
  severity: CompensationSeverity.moderate,
  status: CompensationStatus.active,
  origin: CompensationOrigin.assessment,
  detectedAt: DateTime(2026, 1, 1),
);

final _tResolved = Compensation(
  id: 'comp2',
  userId: 'u1',
  name: 'Rounded Shoulders',
  type: CompensationType.posturalPattern,
  region: CompensationRegion.leftShoulder,
  severity: CompensationSeverity.mild,
  status: CompensationStatus.resolved,
  origin: CompensationOrigin.manual,
  detectedAt: DateTime(2026, 1, 2),
  resolvedAt: DateTime(2026, 2, 1),
);

void main() {
  testWidgets('renders body map container', (tester) async {
    await tester.pumpWidget(_wrap(
      const CompensationBodyMap(compensations: []),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.compensationBodyMap), findsOneWidget);
  });

  testWidgets('renders one dot per compensation', (tester) async {
    await tester.pumpWidget(_wrap(
      CompensationBodyMap(compensations: [_tActive, _tResolved]),
    ));
    await tester.pumpAndSettle();

    // Each dot is a GestureDetector wrapping an AnimatedContainer
    expect(find.byType(AnimatedContainer), findsNWidgets(2));
  });

  testWidgets('tapping a dot calls onRegionTap', (tester) async {
    Compensation? tapped;

    await tester.pumpWidget(_wrap(
      CompensationBodyMap(
        compensations: [_tActive],
        onRegionTap: (c) => tapped = c,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap the first GestureDetector (the dot)
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();

    expect(tapped, isNotNull);
    expect(tapped!.id, 'comp1');
  });

  testWidgets('body map with no compensations renders silhouette only',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const CompensationBodyMap(compensations: []),
    ));
    await tester.pumpAndSettle();

    // No animated containers (no dots)
    expect(find.byType(AnimatedContainer), findsNothing);
    // Silhouette is painted — at least one CustomPaint is present
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });
}
