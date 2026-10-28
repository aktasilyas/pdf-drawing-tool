import 'package:drawing_ui/src/l10n/drawing_strings.dart';
import 'package:drawing_ui/src/services/export_errors.dart';
import 'package:drawing_ui/src/services/pdf_import_failure.dart';

/// Localized text of an [ExportFailure].
extension ExportFailureLabel on ExportFailure {
  /// The user-facing message of this failure in the given strings.
  String message(DrawingStrings s) {
    final e = s.errors;
    switch (this) {
      case ExportFailure.storageFull:
        return e.exportStorageFull;
      case ExportFailure.cannotWrite:
        return e.exportCannotWrite;
      case ExportFailure.failed:
        return e.exportFailed;
      case ExportFailure.noPages:
        return e.exportNoPages;
    }
  }
}

/// Localized text of a [PdfImportFailure].
extension PdfImportFailureLabel on PdfImportFailure {
  /// The user-facing message of this failure in the given strings.
  String message(DrawingStrings s) {
    final e = s.errors;
    switch (error) {
      case PdfImportError.passwordProtected:
        return e.pdfPasswordProtected;
      case PdfImportError.fileAccess:
        return e.pdfFileAccess;
      case PdfImportError.openFailed:
        return e.pdfOpenFailed;
      case PdfImportError.pagesUnreadable:
        return e.pdfPagesUnreadable;
      case PdfImportError.tooManyPages:
        return e.pdfTooManyPages(pageCount, maxPages);
    }
  }
}
