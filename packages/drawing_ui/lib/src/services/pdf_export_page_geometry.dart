import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';

import 'pdf_export_bounds.dart';
import 'pdf_export_models.dart';

/// Where one page lands in the exported PDF.
///
/// Content is drawn in page units over a [contentW] x [contentH] area,
/// shifted by [origin], then scaled by [scale] into the [mediaW] x [mediaH]
/// media box (points).
class PdfPageGeometry {
  const PdfPageGeometry({
    required this.mediaW,
    required this.mediaH,
    required this.contentW,
    required this.contentH,
    this.origin = ui.Offset.zero,
    this.scale = 1.0,
  });

  final double mediaW;
  final double mediaH;
  final double contentW;
  final double contentH;
  final ui.Offset origin;
  final double scale;
}

/// Media box and content transform of [page] for [options].
///
/// - Infinite canvas: the page rect grown to its content, unscaled.
/// - Paper pages with [PDFExportOptions.pageFormat]: page units are scaled
///   uniformly so the width matches the paper; the height follows the page,
///   so a page whose shape differs from the paper is never clipped (#454).
/// - PDF-backed and image pages, or no paper size: page units are points.
PdfPageGeometry pdfPageGeometry(Page page, PDFExportOptions options) {
  final w = page.size.width, h = page.size.height;
  if (options.isInfiniteCanvas) {
    final b = infiniteCanvasExportBounds(page);
    return PdfPageGeometry(
      mediaW: b.width,
      mediaH: b.height,
      contentW: b.width,
      contentH: b.height,
      origin: ui.Offset(b.offsetX, b.offsetY),
    );
  }
  final paper = options.pageFormat;
  final bg = page.background;
  if (paper != null &&
      paper.width > 0 &&
      bg.type != BackgroundType.pdf &&
      !bg.isImage) {
    final s = paper.width / w;
    return PdfPageGeometry(
      mediaW: paper.width,
      mediaH: h * s,
      contentW: w,
      contentH: h,
      scale: s,
    );
  }
  return PdfPageGeometry(mediaW: w, mediaH: h, contentW: w, contentH: h);
}
