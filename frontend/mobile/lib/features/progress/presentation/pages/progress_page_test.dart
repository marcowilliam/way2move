import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/features/auth/presentation/providers/auth_provider.dart';
import 'package:way2move/features/progress/data/repositories/progress_photo_repository_impl.dart';
import 'package:way2move/features/progress/data/repositories/weight_log_repository_impl.dart';
import 'package:way2move/features/progress/domain/entities/progress_photo.dart';
import 'package:way2move/features/progress/domain/entities/weight_log.dart';
import 'package:way2move/features/progress/domain/repositories/progress_photo_repository.dart';
import 'package:way2move/features/progress/domain/repositories/weight_log_repository.dart';
import 'package:way2move/features/progress/presentation/pages/progress_page.dart';
import 'package:way2move/features/progress/presentation/providers/progress_providers.dart';

class MockProgressPhotoRepository extends Mock
    implements ProgressPhotoRepository {}

class MockWeightLogRepository extends Mock implements WeightLogRepository {}

void main() {
  late MockProgressPhotoRepository mockPhotoRepo;
  late MockWeightLogRepository mockWeightRepo;

  setUp(() {
    mockPhotoRepo = MockProgressPhotoRepository();
    mockWeightRepo = MockWeightLogRepository();
  });

  Widget buildSubject({
    List<ProgressPhoto> photos = const [],
    List<WeightLog> weightLogs = const [],
  }) {
    return ProviderScope(
      overrides: [
        progressPhotoRepositoryProvider.overrideWithValue(mockPhotoRepo),
        weightLogRepositoryProvider.overrideWithValue(mockWeightRepo),
        currentUserIdProvider.overrideWith((ref) => 'user1'),
        photoTimelineNotifierProvider.overrideWith(
          () => _FakePhotoNotifier(photos),
        ),
        weightLogsNotifierProvider.overrideWith(
          () => _FakeWeightNotifier(weightLogs),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const ProgressPage())
          ],
        ),
      ),
    );
  }

  group('ProgressPage', () {
    testWidgets('renders Photos section heading', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Photos'), findsOneWidget);
    });

    testWidgets('renders 4 angle placeholder tiles when no photos',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('progress_photo_angle_front')), findsOneWidget);
      expect(find.byKey(const Key('progress_photo_angle_sideLeft')),
          findsOneWidget);
      expect(find.byKey(const Key('progress_photo_angle_sideRight')),
          findsOneWidget);
      expect(
          find.byKey(const Key('progress_photo_angle_back')), findsOneWidget);
    });

    testWidgets('renders View Timeline link', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('View Timeline'), findsOneWidget);
    });

    testWidgets('renders sections header and weight entry area',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Scroll to bottom to reveal Weight section content
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('log_weight_button')),
        100,
        scrollable: scrollable,
      );

      expect(find.byKey(const Key('log_weight_button')), findsOneWidget);
    });

    testWidgets('renders weight trend chart empty state when no logs',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('weight_trend_chart_empty')),
        100,
        scrollable: scrollable,
      );

      expect(find.byKey(const Key('weight_trend_chart_empty')), findsOneWidget);
    });
  });
}

class _FakePhotoNotifier extends PhotoTimelineNotifier {
  final List<ProgressPhoto> _photos;
  _FakePhotoNotifier(this._photos);

  @override
  Future<List<ProgressPhoto>> build() async => _photos;
}

class _FakeWeightNotifier extends WeightLogsNotifier {
  final List<WeightLog> _logs;
  _FakeWeightNotifier(this._logs);

  @override
  Future<List<WeightLog>> build() async => _logs;
}
