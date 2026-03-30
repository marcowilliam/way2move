import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/progress_photo_repository_impl.dart';
import '../../data/repositories/weight_log_repository_impl.dart';
import '../../domain/entities/progress_photo.dart';
import '../../domain/entities/weight_log.dart';
import '../../domain/usecases/capture_progress_photo.dart';
import '../../domain/usecases/get_photo_timeline.dart';
import '../../domain/usecases/get_weight_trend.dart';
import '../../domain/usecases/log_weight.dart';

// ── Photo Timeline ────────────────────────────────────────────────────────────

class PhotoTimelineNotifier extends AsyncNotifier<List<ProgressPhoto>> {
  @override
  Future<List<ProgressPhoto>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    final result = await GetPhotoTimeline(
      ref.read(progressPhotoRepositoryProvider),
    )(userId);
    return result.fold((_) => [], (photos) => photos);
  }

  /// Add a photo already uploaded (URL provided — used in tests or URL-based flow).
  Future<void> addPhoto(ProgressPhoto photo) async {
    final result = await CaptureProgressPhoto(
      ref.read(progressPhotoRepositoryProvider),
    )(photo);
    result.fold(
      (_) {},
      (_) => ref.invalidateSelf(),
    );
  }

  /// Upload a local file and save metadata.
  Future<void> addPhotoFromFile(
    File imageFile,
    PhotoAngle angle,
    String userId, {
    String? notes,
  }) async {
    final repo = ref.read(progressPhotoRepositoryProvider);
    if (repo is! ProgressPhotoRepositoryImpl) return;
    final result = await repo.capturePhotoFromFile(
      imageFile: imageFile,
      userId: userId,
      date: DateTime.now(),
      angle: angle,
      notes: notes,
    );
    result.fold((_) {}, (_) => ref.invalidateSelf());
  }
}

final photoTimelineNotifierProvider =
    AsyncNotifierProvider<PhotoTimelineNotifier, List<ProgressPhoto>>(
  PhotoTimelineNotifier.new,
);

// ── Weight Logs ───────────────────────────────────────────────────────────────

class WeightLogsNotifier extends AsyncNotifier<List<WeightLog>> {
  @override
  Future<List<WeightLog>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];
    final result = await GetWeightTrend(
      ref.read(weightLogRepositoryProvider),
    )(userId, 30);
    return result.fold((_) => [], (logs) => logs);
  }

  Future<void> addWeight(
    double weight,
    WeightUnit unit,
    String userId, {
    String? notes,
  }) async {
    final log = WeightLog(
      id: '',
      userId: userId,
      date: DateTime.now(),
      weight: weight,
      unit: unit,
      notes: notes,
    );
    final result = await LogWeight(
      ref.read(weightLogRepositoryProvider),
    )(log);
    result.fold((_) {}, (_) => ref.invalidateSelf());
  }
}

final weightLogsNotifierProvider =
    AsyncNotifierProvider<WeightLogsNotifier, List<WeightLog>>(
  WeightLogsNotifier.new,
);
