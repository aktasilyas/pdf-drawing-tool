import 'dart:io';

import 'package:drawing_core/drawing_core.dart'
    show DrawingDocument, Page, PageBackground, PdfPathResolver;
import 'package:example_app/core/core.dart';

/// Whether [background] references an image file whose bytes are not loaded.
bool _needsImageBytes(PageBackground background) =>
    background.imageFilePath != null && background.pdfData == null;

/// Returns [background] with `pdfData` read from its `imageFilePath`.
///
/// Backgrounds without an image file reference, or that already carry bytes,
/// are returned unchanged. A missing or unreadable file is logged and leaves
/// `pdfData` null (the page shows a placeholder); this never throws.
Future<PageBackground> loadImageBackground(
  PageBackground background,
  PdfPathResolver paths,
) async {
  if (!_needsImageBytes(background)) return background;
  final stored = background.imageFilePath!;
  try {
    final bytes = await File(paths.resolve(stored)).readAsBytes();
    return background.copyWith(pdfData: bytes);
  } catch (e) {
    logger.w('Could not load image page file $stored: $e');
    return background;
  }
}

/// Fills `pdfData` of every image page of [doc] from its stored image file.
///
/// PDF pages and pages without a file reference are untouched. Returns [doc]
/// itself when nothing needed loading.
Future<DrawingDocument> loadImageBackgrounds(
  DrawingDocument doc,
  PdfPathResolver paths,
) async {
  if (!doc.pages.any((p) => _needsImageBytes(p.background))) return doc;
  final pages = [
    for (final page in doc.pages)
      if (_needsImageBytes(page.background))
        _withBackground(page, await loadImageBackground(page.background, paths))
      else
        page,
  ];
  return doc.copyWith(pages: pages);
}

/// Page.copyWith stamps updatedAt; keep the stored timestamp instead.
Page _withBackground(Page page, PageBackground background) =>
    page.copyWith(background: background, updatedAt: page.updatedAt);
