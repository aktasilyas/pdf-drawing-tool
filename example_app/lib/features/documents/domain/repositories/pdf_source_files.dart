import 'package:dartz/dartz.dart';
import 'package:example_app/features/documents/domain/entities/pdf_relink_failure.dart';

/// Reads the page count of a PDF file on disk.
abstract interface class PdfPageCounter {
  /// Left(passwordProtected | openFailed | fileAccess) when [path] cannot be
  /// opened.
  Future<Either<PdfRelinkFailure, int>> pageCount(String path);
}

/// The managed copy of a notebook's source PDF.
abstract interface class PdfSourceFiles {
  /// Whether a file exists at the location [stored] resolves to.
  Future<bool> exists(String stored);

  /// Copies [sourcePath] to a temp file beside the resolved [stored] path,
  /// then renames it into place. Left(targetExists) if the target appeared;
  /// the temp file is always removed.
  Future<Either<PdfRelinkFailure, Unit>> install(
    String sourcePath,
    String stored,
  );
}
