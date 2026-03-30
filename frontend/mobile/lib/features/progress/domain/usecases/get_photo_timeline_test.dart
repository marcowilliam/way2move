import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progress/domain/entities/progress_photo.dart';
import 'package:way2move/features/progress/domain/repositories/progress_photo_repository.dart';
import 'package:way2move/features/progress/domain/usecases/get_photo_timeline.dart';

class MockProgressPhotoRepository extends Mock
    implements ProgressPhotoRepository {}

void main() {
  late MockProgressPhotoRepository mockRepo;
  late GetPhotoTimeline getPhotoTimeline;

  final tPhotos = [
    ProgressPhoto(
      id: 'photo1',
      userId: 'user1',
      date: DateTime(2026, 3, 29),
      photoUrl: 'https://example.com/photo1.jpg',
      angle: PhotoAngle.front,
    ),
    ProgressPhoto(
      id: 'photo2',
      userId: 'user1',
      date: DateTime(2026, 3, 22),
      photoUrl: 'https://example.com/photo2.jpg',
      angle: PhotoAngle.back,
    ),
  ];

  setUp(() {
    mockRepo = MockProgressPhotoRepository();
    getPhotoTimeline = GetPhotoTimeline(mockRepo);
  });

  group('GetPhotoTimeline', () {
    test('returns list of photos on success', () async {
      when(() => mockRepo.getTimeline(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tPhotos));

      final result = await getPhotoTimeline('user1');

      expect(result, Right(tPhotos));
      verify(() => mockRepo.getTimeline('user1', limit: 50)).called(1);
    });

    test('returns empty list when no photos exist', () async {
      when(() => mockRepo.getTimeline(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Right([]));

      final result = await getPhotoTimeline('user1');

      expect(result, const Right(<ProgressPhoto>[]));
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.getTimeline(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await getPhotoTimeline('user1');

      expect(result.isLeft(), true);
    });

    test('passes custom limit to repository', () async {
      when(() => mockRepo.getTimeline(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => Right(tPhotos));

      await getPhotoTimeline('user1', limit: 10);

      verify(() => mockRepo.getTimeline('user1', limit: 10)).called(1);
    });
  });
}
