import 'package:dartz/dartz.dart';
import 'package:drawing_ui/drawing_ui.dart'
    show PdfSourceRelinkHandler, documentProvider;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/documents.dart'
    show PdfRelinkError, PdfRelinkFailure, RelinkPdfSourceUseCase;
import 'package:example_app/features/editor/presentation/providers/editor_session.dart';
import 'package:example_app/l10n/l10n.dart';

/// Lets the user pick a PDF; resolves to its path, or `null` on cancel.
typedef PdfFilePicker = Future<String?> Function();

Future<String?> _pickPdf() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    withData: false,
  );
  final path = result?.files.firstOrNull?.path;
  return (path == null || path.isEmpty) ? null : path;
}

/// The "Locate PDF…" action of the missing-source placeholder (#449).
///
/// Picks a PDF, puts it back at the stored path of the open notebook and
/// reports the outcome on [context]. Resolves to true when the file is back
/// in place, so the caller can drop the stale renders.
PdfSourceRelinkHandler pdfRelinkHandlerFor(
  ProviderReader read,
  BuildContext context, {
  PdfFilePicker pickPdf = _pickPdf,
  RelinkPdfSourceUseCase? relink,
}) {
  var busy = false;
  return (storedPath) async {
    if (busy) return false;
    busy = true;
    try {
      final picked = await pickPdf();
      if (picked == null) return false;
      final useCase = relink ?? getIt<RelinkPdfSourceUseCase>();
      final result = await useCase(
        storedPath: storedPath,
        pickedPath: picked,
        requiredPages: RelinkPdfSourceUseCase.requiredPagesFor(
          read(documentProvider).pages,
          storedPath,
        ),
      );
      final relinked = pdfRelinkSucceeded(result);
      if (context.mounted) {
        final l10n = context.l10n;
        result.fold(
          (failure) {
            if (relinked) return;
            AppToast.error(context, pdfRelinkFailureMessage(l10n, failure));
          },
          (_) => AppToast.success(context, l10n.editorPdfRelinkDone),
        );
      }
      return relinked;
    } finally {
      busy = false;
    }
  };
}

/// Whether the source file is in place after [result]. A target that already
/// exists counts: the file is back, so the pages can render again.
bool pdfRelinkSucceeded(Either<Failure, Unit> result) => result.fold(
      (failure) =>
          failure is PdfRelinkFailure &&
          failure.error == PdfRelinkError.targetExists,
      (_) => true,
    );

/// User-facing copy for a failed re-link.
String pdfRelinkFailureMessage(AppLocalizations l10n, Failure failure) {
  if (failure is! PdfRelinkFailure) return l10n.editorPdfRelinkFailed;
  switch (failure.error) {
    case PdfRelinkError.passwordProtected:
      return l10n.editorErrorPdfPasswordProtected;
    case PdfRelinkError.fileAccess:
      return l10n.editorErrorPdfFileAccess;
    case PdfRelinkError.storageFull:
      return l10n.editorErrorPdfStorageFull;
    case PdfRelinkError.openFailed:
      return l10n.editorErrorPdfOpenFailed;
    case PdfRelinkError.pageCountMismatch:
      return l10n.editorPdfRelinkPageCountMismatch(
        failure.found,
        failure.required,
      );
    case PdfRelinkError.targetExists:
      return l10n.editorPdfRelinkFailed;
  }
}
