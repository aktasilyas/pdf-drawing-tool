import 'package:flutter/material.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:example_app/l10n/l10n.dart';

/// Tells the user that the document imported from a PDF is opening. When some
/// PDF pages could not be read, it warns with their count instead, so a
/// shorter notebook is never a surprise.
void showPdfImportOpened(
  ScaffoldMessengerState messenger, {
  required String title,
  required PDFImportServiceResult result,
  required AppLocalizations l10n,
  required ErrorStrings errors,
}) {
  final skipped = result.skippedPages.length;
  final message = skipped > 0
      ? errors.pdfPagesSkipped(skipped)
      : l10n.libraryOpeningWithPages(
          title,
          l10n.libraryPageCount(result.pages.length),
        );
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: skipped > 0 ? 4 : 2),
    ),
  );
}
