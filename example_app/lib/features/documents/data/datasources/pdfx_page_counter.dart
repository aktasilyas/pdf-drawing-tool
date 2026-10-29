import 'package:dartz/dartz.dart';
import 'package:drawing_ui/drawing_ui.dart'
    show PDFLoader, PdfImportError, pdfFileLooksEncrypted, pdfImportFailureFor;
import 'package:example_app/features/documents/domain/entities/pdf_relink_failure.dart';
import 'package:example_app/features/documents/domain/repositories/pdf_source_files.dart';

/// [PdfPageCounter] backed by pdfx through drawing_ui's [PDFLoader].
class PdfxPageCounter implements PdfPageCounter {
  /// [loader] defaults to the platform pdfx implementation; tests inject one.
  PdfxPageCounter({PDFLoader? loader}) : _loader = loader ?? PDFLoader();

  final PDFLoader _loader;

  @override
  Future<Either<PdfRelinkFailure, int>> pageCount(String path) async {
    try {
      final document = await _loader.loadFromFile(path);
      try {
        return Right(document.pagesCount);
      } finally {
        await _loader.disposeDocument(document);
      }
    } catch (e) {
      var error = _relinkErrorFor(pdfImportFailureFor(e).error);
      // Android's renderer reports a locked file with a generic open error.
      if (error == PdfRelinkError.openFailed &&
          await pdfFileLooksEncrypted(path)) {
        error = PdfRelinkError.passwordProtected;
      }
      return Left(PdfRelinkFailure(error));
    }
  }

  static PdfRelinkError _relinkErrorFor(PdfImportError error) {
    switch (error) {
      case PdfImportError.passwordProtected:
        return PdfRelinkError.passwordProtected;
      case PdfImportError.fileAccess:
        return PdfRelinkError.fileAccess;
      case PdfImportError.storageFull:
        return PdfRelinkError.storageFull;
      case PdfImportError.openFailed:
      case PdfImportError.pagesUnreadable:
      case PdfImportError.tooManyPages:
        return PdfRelinkError.openFailed;
    }
  }
}
