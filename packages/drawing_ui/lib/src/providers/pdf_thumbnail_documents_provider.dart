import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/services/pdf_document_pool.dart';

/// Opens PDF documents for page thumbnails (overridable in tests).
final pdfDocumentOpenerProvider =
    Provider<PdfDocumentOpener>((ref) => openPdfxDocument);

/// PDF documents kept open for the page thumbnails of the open editor.
///
/// The editor screen watches it, so it lives while the editor is open; when
/// the editor closes the provider is disposed and every document is closed.
final pdfThumbnailDocumentsProvider =
    Provider.autoDispose<PdfDocumentPool>((ref) {
  final pool = PdfDocumentPool(opener: ref.watch(pdfDocumentOpenerProvider));
  ref.onDispose(() => unawaited(pool.close()));
  return pool;
});
