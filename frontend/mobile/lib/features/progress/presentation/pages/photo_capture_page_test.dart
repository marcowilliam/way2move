import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/progress/domain/repositories/progress_photo_repository.dart';
import 'package:way2move/features/progress/data/repositories/progress_photo_repository_impl.dart';
import 'package:way2move/features/progress/presentation/pages/photo_capture_page.dart';

class MockProgressPhotoRepository extends Mock
    implements ProgressPhotoRepository {}

void main() {
  late MockProgressPhotoRepository mockRepo;

  setUp(() {
    mockRepo = MockProgressPhotoRepository();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        progressPhotoRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(home: PhotoCapturePage()),
    );
  }

  group('PhotoCapturePage', () {
    testWidgets('renders 4 angle buttons in a 2×2 grid', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byKey(const Key('angle_button_front')), findsOneWidget);
      expect(find.byKey(const Key('angle_button_sideLeft')), findsOneWidget);
      expect(find.byKey(const Key('angle_button_sideRight')), findsOneWidget);
      expect(find.byKey(const Key('angle_button_back')), findsOneWidget);
    });

    testWidgets('shows AppBar with correct title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Progress Photos'), findsOneWidget);
    });

    testWidgets('shows angle labels on buttons', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Front'), findsOneWidget);
      expect(find.text('Side L'), findsOneWidget);
      expect(find.text('Side R'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('shows instruction text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Select angle to capture'), findsOneWidget);
    });
  });
}
