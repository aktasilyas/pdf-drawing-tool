import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart' show PdfPathResolver;
import 'package:drawing_ui/drawing_ui.dart'
    show PdfImportError, pdfImportFailureFor;
import 'package:example_app/features/documents/domain/entities/pdf_relink_failure.dart';
import 'package:example_app/features/documents/domain/repositories/pdf_source_files.dart';

/// [PdfSourceFiles] on the local file system, rooted by [PdfPathResolver].
class LocalPdfSourceFiles implements PdfSourceFiles {
  LocalPdfSourceFiles(this._paths);

  final PdfPathResolver _paths;

  @override
  Future<bool> exists(String stored) => File(_paths.resolve(stored)).exists();

  @override
  Future<Either<PdfRelinkFailure, Unit>> install(
    String sourcePath,
    String stored,
  ) async {
    final target = _paths.resolve(stored);
    final temp = File('$target.relink-${DateTime.now().microsecondsSinceEpoch}'
        '.tmp');
    try {
      await File(target).parent.create(recursive: true);
      await File(sourcePath).copy(temp.path);
      // `rename` replaces an existing file on POSIX, so check right before it.
      // A file appearing in between is a tiny race that is acceptable on a
      // single-user device.
      if (await File(target).exists()) {
        return const Left(PdfRelinkFailure(PdfRelinkError.targetExists));
      }
      await temp.rename(target);
      return const Right(unit);
    } on FileSystemException catch (e) {
      final storageFull =
          pdfImportFailureFor(e).error == PdfImportError.storageFull;
      return Left(
        PdfRelinkFailure(
          storageFull ? PdfRelinkError.storageFull : PdfRelinkError.fileAccess,
        ),
      );
    } finally {
      try {
        if (await temp.exists()) await temp.delete();
      } on FileSystemException {
        // Best effort: a leftover temp file is harmless.
      }
    }
  }
}
