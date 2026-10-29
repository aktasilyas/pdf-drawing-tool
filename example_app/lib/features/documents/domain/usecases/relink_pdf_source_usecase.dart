import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show Page;
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/pdf_relink_failure.dart';
import 'package:example_app/features/documents/domain/repositories/pdf_source_files.dart';

/// Puts a user-picked PDF back at the stored path of a notebook whose source
/// file went missing (backup restore, device move), keeping all annotations.
class RelinkPdfSourceUseCase {
  RelinkPdfSourceUseCase(this._counter, this._files);

  final PdfPageCounter _counter;
  final PdfSourceFiles _files;

  /// [requiredPages] is the highest 1-based page index the notebook
  /// references (see [requiredPagesFor]). Nothing is written unless the picked
  /// file opens and has at least that many pages; an existing file at
  /// [storedPath] is never replaced.
  Future<Either<Failure, Unit>> call({
    required String storedPath,
    required String pickedPath,
    required int requiredPages,
  }) async {
    if (await _files.exists(storedPath)) {
      return const Left(PdfRelinkFailure(PdfRelinkError.targetExists));
    }
    final counted = await _counter.pageCount(pickedPath);
    final found = counted.fold<int?>((_) => null, (count) => count);
    if (found == null) {
      return counted.map((_) => unit);
    }
    if (found < requiredPages) {
      return Left(
        PdfRelinkFailure(
          PdfRelinkError.pageCountMismatch,
          found: found,
          required: requiredPages,
        ),
      );
    }
    return _files.install(pickedPath, storedPath);
  }

  /// Highest `pdfPageIndex` (1-based) of [pages] referencing [stored];
  /// 0 when none do.
  static int requiredPagesFor(Iterable<Page> pages, String stored) {
    var highest = 0;
    for (final page in pages) {
      final background = page.background;
      final index = background.pdfPageIndex;
      if (background.pdfFilePath != stored || index == null) continue;
      if (index > highest) highest = index;
    }
    return highest;
  }
}
