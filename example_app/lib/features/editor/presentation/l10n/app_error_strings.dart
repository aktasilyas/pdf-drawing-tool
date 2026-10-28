import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// [ErrorStrings] backed by the generated [AppLocalizations].
class AppErrorStrings extends ErrorStrings {
  const AppErrorStrings(this._l10n);

  final AppLocalizations _l10n;

  @override
  String get exportStorageFull => _l10n.editorErrorExportStorageFull;

  @override
  String get exportCannotWrite => _l10n.editorErrorExportCannotWrite;

  @override
  String get exportFailed => _l10n.editorErrorExportFailed;

  @override
  String get exportNoPages => _l10n.editorErrorExportNoPages;

  @override
  String get pdfPasswordProtected => _l10n.editorErrorPdfPasswordProtected;

  @override
  String get pdfFileAccess => _l10n.editorErrorPdfFileAccess;

  @override
  String get pdfOpenFailed => _l10n.editorErrorPdfOpenFailed;

  @override
  String get pdfPagesUnreadable => _l10n.editorErrorPdfPagesUnreadable;

  @override
  String pdfTooManyPages(int count, int max) =>
      _l10n.editorErrorPdfTooManyPages(count, max);

  @override
  String get pdfPagePlaceholder => _l10n.editorErrorPdfPagePlaceholder;

  @override
  String get pdfSourceMissing => _l10n.editorErrorPdfSourceMissing;

  @override
  String get pdfLoadFailed => _l10n.editorErrorPdfLoadFailed;

  @override
  String pdfPagesSkipped(int count) => _l10n.editorErrorPdfPagesSkipped(count);
}
