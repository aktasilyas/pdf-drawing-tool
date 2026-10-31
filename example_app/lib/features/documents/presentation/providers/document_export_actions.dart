import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/library_error.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';

/// Exports a library document as PDF without opening the editor.
///
/// Loads the full document, then reuses the editor's export path
/// ([PDFExportRunner]: progress overlay, share sheet, all pages with their
/// templates). A failed load is published to `LibraryErrorListener`.
class DocumentExportActions {
  DocumentExportActions(this._ref);

  final Ref _ref;

  /// Returns false when the document could not be loaded (nothing exported).
  Future<bool> exportAsPdf(
    String documentId, {
    required ExportStrings strings,
  }) async {
    final result = await _ref.read(loadDocumentUseCaseProvider)(documentId);
    return result.fold(
      (failure) async {
        reportLibraryFailure(_ref, failure, LibraryAction.exportDocument);
        return false;
      },
      (document) async {
        // The editor's global format belongs to whichever notebook was opened
        // last; a library export uses the exported notebook's own size.
        final pageFormat = await _paperFormat(documentId);
        _ref.read(pdfExportRunnerProvider).run(
              _ref.read(exportProgressProvider.notifier),
              document,
              strings: strings,
              share: true,
              isInfiniteCanvas: document.isInfiniteCanvas,
              pageFormat: pageFormat,
            );
        return true;
      },
    );
  }

  /// The notebook's stored paper size (orientation already applied); A4 when
  /// it cannot be read, matching the stored default.
  Future<PDFPageFormat> _paperFormat(String documentId) async {
    final info =
        await _ref.read(documentRepositoryProvider).getDocument(documentId);
    return info.fold(
      (_) => PDFPageFormat.millimeters(210, 297),
      (i) => PDFPageFormat.millimeters(i.paperWidthMm, i.paperHeightMm),
    );
  }
}

final documentExportActionsProvider = Provider<DocumentExportActions>(
  DocumentExportActions.new,
);
