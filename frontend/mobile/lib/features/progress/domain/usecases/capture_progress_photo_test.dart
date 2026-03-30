import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:way2move/core/errors/app_failure.dart';
import 'package:way2move/features/progress/domain/entities/progress_photo.dart';
import 'package:way2move/features/progress/domain/repositories/progress_photo_repository.dart';
import 'package:way2move/features/progress/domain/usecases/capture_progress_photo.dart';

class MockProgressPhotoRepository extends Mock
    implements ProgressPhotoRepository {}

void main() {
  late MockProgressPhotoRepository mockRepo;
  late CaptureProgressPhoto captureProgressPhoto;

  final tPhoto = ProgressPhoto(
    id: 'photo1',
    userId: 'user1',
    date: DateTime(2026, 3, 29),
    photoUrl: 'https://example.com/photo.jpg',
    angle: PhotoAngle.front,
    notes: 'Week 4',
  );

  setUp(() {
    mockRepo = MockProgressPhotoRepository();
    captureProgressPhoto = CaptureProgressPhoto(mockRepo);
    registerFallbackValue(tPhoto);
  });

  group('CaptureProgressPhoto', () {
    test('returns ProgressPhoto on success', () async {
      when(() => mockRepo.capturePhoto(any()))
          .thenAnswer((_) async => Right(tPhoto));

      final result = await captureProgressPhoto(tPhoto);

      expect(result, Right(tPhoto));
      verify(() => mockRepo.capturePhoto(tPhoto)).called(1);
    });

    test('returns ServerFailure when repository fails', () async {
      when(() => mockRepo.capturePhoto(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      final result = await captureProgressPhoto(tPhoto);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('passes through all photo angles', () async {
      for (final angle in PhotoAngle.values) {
        final photo = tPhoto.copyWith(angle: angle);
        when(() => mockRepo.capturePhoto(any()))
            .thenAnswer((_) async => Right(photo));

        final result = await captureProgressPhoto(photo);

        expect(result.isRight(), true);
      }
    });
  });
}
