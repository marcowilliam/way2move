import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/app_failure.dart';
import '../entities/assessment.dart';
import '../entities/assessment_comparison_result.dart';
import '../entities/compensation_report.dart';
import '../entities/detected_compensation.dart';
import '../entities/video_analysis.dart';
import '../repositories/assessment_repository.dart';
import '../repositories/video_analysis_repository.dart';

/// Input parameters for [GetAssessmentComparison].
class GetAssessmentComparisonInput {
  final String firstAssessmentId;
  final String secondAssessmentId;

  const GetAssessmentComparisonInput({
    required this.firstAssessmentId,
    required this.secondAssessmentId,
  });
}

/// Fetches both assessments and their video analyses, then returns an
/// [AssessmentComparisonResult] pairing the two snapshots.
///
/// The assessment with the earlier date becomes [AssessmentComparisonResult.initial];
/// the later one becomes [AssessmentComparisonResult.reAssessment].
class GetAssessmentComparison {
  final AssessmentRepository _assessmentRepo;
  final VideoAnalysisRepository _videoRepo;

  const GetAssessmentComparison(this._assessmentRepo, this._videoRepo);

  Future<Either<AppFailure, AssessmentComparisonResult>> call(
    GetAssessmentComparisonInput input,
  ) async {
    // Fetch both assessments concurrently
    final firstResult =
        await _assessmentRepo.getAssessmentById(input.firstAssessmentId);
    final secondResult =
        await _assessmentRepo.getAssessmentById(input.secondAssessmentId);

    if (firstResult.isLeft()) return Left(firstResult.getLeft().toNullable()!);
    if (secondResult.isLeft()) {
      return Left(secondResult.getLeft().toNullable()!);
    }

    final first = firstResult.getRight().toNullable()!;
    final second = secondResult.getRight().toNullable()!;

    // Fetch video analyses for both assessments concurrently
    final firstVideosResult =
        await _videoRepo.getByAssessment(input.firstAssessmentId);
    final secondVideosResult =
        await _videoRepo.getByAssessment(input.secondAssessmentId);

    if (firstVideosResult.isLeft()) {
      return Left(firstVideosResult.getLeft().toNullable()!);
    }
    if (secondVideosResult.isLeft()) {
      return Left(secondVideosResult.getLeft().toNullable()!);
    }

    final firstVideos = firstVideosResult.getRight().toNullable()!;
    final secondVideos = secondVideosResult.getRight().toNullable()!;

    final firstReport = _buildReport(first, firstVideos);
    final secondReport = _buildReport(second, secondVideos);

    // The earlier-dated assessment is always "initial"
    final AssessmentSnapshot initialSnapshot;
    final AssessmentSnapshot reSnapshot;

    if (!first.date.isAfter(second.date)) {
      initialSnapshot = AssessmentSnapshot(
        assessmentId: first.id,
        assessmentDate: first.date,
        report: firstReport,
        videoAnalyses: firstVideos,
      );
      reSnapshot = AssessmentSnapshot(
        assessmentId: second.id,
        assessmentDate: second.date,
        report: secondReport,
        videoAnalyses: secondVideos,
      );
    } else {
      initialSnapshot = AssessmentSnapshot(
        assessmentId: second.id,
        assessmentDate: second.date,
        report: secondReport,
        videoAnalyses: secondVideos,
      );
      reSnapshot = AssessmentSnapshot(
        assessmentId: first.id,
        assessmentDate: first.date,
        report: firstReport,
        videoAnalyses: firstVideos,
      );
    }

    return Right(
      AssessmentComparisonResult(
        initial: initialSnapshot,
        reAssessment: reSnapshot,
      ),
    );
  }

  CompensationReport _buildReport(
    Assessment assessment,
    List<VideoAnalysis> analyses,
  ) {
    final videoDetections = <DetectedCompensation>[];

    for (final va in analyses) {
      for (final pattern in va.detectedCompensations) {
        // Sum up affected frames across analyses for the same pattern.
        final existing = videoDetections.where((d) => d.pattern == pattern);
        if (existing.isEmpty) {
          videoDetections.add(DetectedCompensation(
            pattern: pattern,
            affectedFrameCount: va.frames.length,
            totalFrameCount: va.frames.length,
          ));
        }
      }
    }

    return CompensationReport.merge(
      assessmentId: assessment.id,
      userId: assessment.userId,
      questionnairePatterns: assessment.compensationResults,
      videoDetections: videoDetections,
      generatedAt: assessment.date,
    );
  }
}
