import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/features/documents/documents.dart';

/// Runs the orphaned-file sweep once the UI is up: waits for [firstFrame] and
/// then [delay] so it never competes with startup work. Never throws; the
/// sweep itself is throttled by [SweepOrphanedFilesUseCase].
Future<void> sweepOrphanedFilesAfterFirstFrame(
  SweepOrphanedFilesUseCase sweep, {
  required Future<void> firstFrame,
  Duration delay = const Duration(seconds: 3),
  DateTime Function() clock = DateTime.now,
}) async {
  try {
    await firstFrame;
    await Future<void>.delayed(delay);
    final result = await sweep(clock());
    result.fold(
      (failure) => logger.w('Orphan file sweep failed: ${failure.message}'),
      (count) {
        if (count > 0) logger.i('Removed $count orphaned files');
      },
    );
  } catch (e) {
    logger.w('Orphan file sweep failed: $e');
  }
}
