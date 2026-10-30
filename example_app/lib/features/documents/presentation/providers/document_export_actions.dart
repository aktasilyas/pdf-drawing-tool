import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      (failure) {
        reportLibraryFailure(_ref, failure, LibraryAction.exportDocument);
        return false;
      },
      (document) {
        _ref.read(pdfExportRunnerProvider).run(
              _ref.read(exportProgressProvider.notifier),
              document,
              strings: strings,
              share: true,
            );
        return true;
      },
    );
  }
}

final documentExportActionsProvider = Provider<DocumentExportActions>(
  DocumentExportActions.new,
);
