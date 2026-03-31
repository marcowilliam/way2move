import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:way2move/features/assessments/domain/entities/assessment.dart'
    show CompensationPattern;
import 'package:way2move/features/assessments/domain/entities/detected_compensation.dart';
import 'package:way2move/features/assessments/domain/entities/pose_landmark.dart';
import 'pose_landmark_overlay.dart';

void main() {
  group('PoseLandmarkOverlay', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PoseLandmarkOverlay(
              landmarks: [],
              compensations: [],
              child: SizedBox(
                key: Key('child'),
                width: 200,
                height: 200,
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets('renders CustomPaint on top of child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PoseLandmarkOverlay(
              landmarks: [],
              compensations: [],
              child: SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('accepts landmarks and compensations without error',
        (tester) async {
      const landmarks = [
        PoseLandmark(
          joint: JointLandmark.leftKnee,
          x: 0.4,
          y: 0.7,
          z: 0.0,
          visibility: 0.9,
        ),
        PoseLandmark(
          joint: JointLandmark.rightKnee,
          x: 0.6,
          y: 0.7,
          z: 0.0,
          visibility: 0.9,
        ),
      ];

      const compensations = [
        DetectedCompensation(
          pattern: CompensationPattern.kneeValgus,
          affectedFrameCount: 8,
          totalFrameCount: 10,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: PoseLandmarkOverlay(
                landmarks: landmarks,
                compensations: compensations,
                child: ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('hides landmarks with low visibility without error',
        (tester) async {
      const landmarks = [
        PoseLandmark(
          joint: JointLandmark.nose,
          x: 0.5,
          y: 0.1,
          z: 0.0,
          visibility: 0.1, // below threshold → not rendered
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: PoseLandmarkOverlay(
                landmarks: landmarks,
                compensations: [],
                child: ColoredBox(color: Colors.black),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
