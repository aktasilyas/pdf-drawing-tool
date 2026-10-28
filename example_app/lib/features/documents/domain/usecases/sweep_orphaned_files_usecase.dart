import 'package:dartz/dartz.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/documents/domain/repositories/maintenance_schedule.dart';

/// Reclaims disk space of managed files no notebook references any more.
/// Throttled to one run per [minInterval]; files changed within [grace] are
/// never touched (an import or placement may not be saved yet).
class SweepOrphanedFilesUseCase {
  SweepOrphanedFilesUseCase(this._documents, this._schedule);

  static const Duration minInterval = Duration(hours: 24);
  static const Duration grace = Duration(minutes: 10);

  final DocumentRepository _documents;
  final MaintenanceSchedule _schedule;

  /// Returns the number of deleted files; `Right(0)` when throttled. The run
  /// time is stored only after a successful sweep.
  Future<Either<Failure, int>> call(DateTime now) async {
    final last = await _schedule.lastOrphanSweep();
    // A stored time in the future (clock went back) must not block the sweep.
    if (last != null &&
        !last.isAfter(now) &&
        now.difference(last) < minInterval) {
      return const Right(0);
    }
    final result = await _documents.sweepOrphanedFiles(
      olderThan: now.subtract(grace),
    );
    if (result.isRight()) await _schedule.setLastOrphanSweep(now);
    return result;
  }
}
