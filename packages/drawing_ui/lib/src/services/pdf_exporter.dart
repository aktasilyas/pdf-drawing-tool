import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'package:drawing_ui/src/utils/drawing_log.dart';

import 'export_errors.dart';
import 'pdf_background_rasterizer.dart';
import 'pdf_compressed_image.dart';
import 'pdf_content_painter.dart';
import 'pdf_export_models.dart';
import 'pdf_export_page_geometry.dart';
import 'pdf_raster_layer_renderer.dart';
import 'pdf_source.dart';

// Re-export models so existing imports continue to work.
export 'pdf_export_models.dart';
export 'pdf_source.dart';

/// Hybrid vector+raster PDF exporter.
///
/// Vectorizable content (plain strokes, shapes, images) is rendered as PDF
/// vector operations for infinite-zoom sharpness. Non-vectorizable content
/// (textured/glow/eraser strokes, text) falls back to lossless PNG overlay.
class PDFExporter {
  PDFExporter({
    this.pdfPaths = PdfPathResolver.passthrough,
    PdfSourceOpener? sourceOpener,
  }) : _openSource = sourceOpener ?? openPdfxSource;

  /// Resolves stored PDF background and inserted image paths to files on disk.
  final PdfPathResolver pdfPaths;
  final PdfSourceOpener _openSource;

  final _contentPainter = PdfContentPainter();
  final _rasterRenderer = PdfRasterLayerRenderer();

  static double _scaleFromDpi(int dpi) => dpi / 72.0;

  Future<PDFExportResult> exportPages({
    required List<Page> pages,
    PDFDocumentMetadata? metadata,
    PDFExportOptions options = const PDFExportOptions(),
    void Function(int current, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (pages.isEmpty) return PDFExportResult.error(ExportFailure.noPages);

    try {
      final doc = PdfDocument();
      final sources = PdfSourcePool(_openSource);
      // Per export, so concurrent exports never share or evict images.
      final backgrounds = PdfBackgroundRasterizer();
      final missing = <int>[];
      final missingImages = <int>[];
      try {
        for (int i = 0; i < pages.length; i++) {
          if (isCancelled?.call() == true) return PDFExportResult.cancelled();
          final page = pages[i];
          if (page.size.width <= 0 || page.size.height <= 0) continue;
          final drawn =
              await _exportPage(doc, page, options, sources, backgrounds);
          if (!drawn.pdf) missing.add(i + 1);
          if (!drawn.images) missingImages.add(i + 1);
          onProgress?.call(i + 1, pages.length);
        }
      } finally {
        await sources.closeAll();
      }
      if (missing.isNotEmpty) {
        DrawingLog.w('PDF export: pages $missing without their PDF background');
      }
      if (missingImages.isNotEmpty) {
        DrawingLog.w('PDF export: pages $missingImages without some images');
      }
      // Cancel tapped after the last page was drawn (a one-page export
      // never reaches the next per-page check) or while saving (#490).
      if (isCancelled?.call() == true) return PDFExportResult.cancelled();
      final bytes = await doc.save();
      if (isCancelled?.call() == true) return PDFExportResult.cancelled();
      return PDFExportResult.success(
        bytes,
        missingBackgroundPages: missing,
        missingImagePages: missingImages,
      );
    } catch (e) {
      DrawingLog.e('PDF export failed', e);
      return PDFExportResult.error(exportFailureFor(e));
    }
  }

  /// Draws [page] into [doc]. `pdf` is false when the page has a PDF
  /// background that could not be loaded; `images` is false when an image
  /// element in a visible layer could not be read. Both are left out.
  Future<({bool pdf, bool images})> _exportPage(
    PdfDocument doc,
    Page page,
    PDFExportOptions options,
    PdfSourcePool sources,
    PdfBackgroundRasterizer backgrounds,
  ) async {
    // Infinite canvas: page rect grown to its content, content shifted by
    // the bounds offset (as in `PagePngExporter`). Paper pages: page units
    // scaled to the notebook's paper size (#454).
    final geo = pdfPageGeometry(page, options);
    final pdfW = geo.contentW, pdfH = geo.contentH;
    final origin = geo.origin;

    final pdfPage =
        PdfPage(doc, pageFormat: PdfPageFormat(geo.mediaW, geo.mediaH));
    final g = pdfPage.getGraphics();
    final scaled = geo.scale != 1.0;
    if (scaled) {
      // One page-level scale: vector ops (y flipped against pdfH) and the
      // full-page images below all land inside the media box.
      final s = geo.scale;
      g.saveContext();
      g.setTransform(Matrix4(s, 0, 0, 0, 0, s, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1));
    }

    if (options.includeBackground) {
      await _paintBackground(
          g, doc, page.background, pdfW, pdfH, options, backgrounds);
    }
    var pdfDrawn = true;
    if (page.background.type == BackgroundType.pdf) {
      pdfDrawn =
          await _embedPdfBackground(g, doc, page, pdfW, pdfH, options, sources);
    }
    var imagesDrawn = true;
    void onMissingImage(ImageElement _) => imagesDrawn = false;
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;
      await _renderLayer(g, doc, layer, pdfW, pdfH, options, origin,
          onMissingImage: onMissingImage);
    }
    if (scaled) g.restoreContext();

    if (options.addWatermark) {
      _drawWatermark(g, doc, geo.mediaW, geo.mediaH);
    }
    return (pdf: pdfDrawn, images: imagesDrawn);
  }

  /// Templates and covers go through the canvas painters as one cached
  /// full-page image; legacy patterns stay vector.
  Future<void> _paintBackground(
    PdfGraphics g,
    PdfDocument doc,
    PageBackground bg,
    double w,
    double h,
    PDFExportOptions options,
    PdfBackgroundRasterizer backgrounds,
  ) async {
    if (PdfBackgroundRasterizer.handles(bg)) {
      final img =
          await backgrounds.imageFor(doc, bg, w, h, options.quality.dpi);
      if (img != null) {
        g.drawImage(img, 0, 0, w, h);
        return;
      }
    }
    _contentPainter.paintBackground(g, bg, w, h);
  }

  /// Draws a small, semi-transparent "ElyaNotes" watermark at the
  /// bottom-right corner of the page. Subtle enough not to obstruct content.
  void _drawWatermark(PdfGraphics g, PdfDocument doc, double w, double h) {
    const text = 'ElyaNotes';
    const fontSize = 10.0;
    const margin = 12.0;

    g.saveContext();
    g.setGraphicState(PdfGraphicState(opacity: 0.3));
    g.setColor(PdfColor.fromInt(0xFF9E9E9E)); // grey
    g.drawString(
      PdfFont.helvetica(doc),
      fontSize,
      text,
      w - margin - (fontSize * text.length * 0.55),
      margin,
    );
    g.restoreContext();
  }

  Future<void> _renderLayer(
    PdfGraphics g,
    PdfDocument doc,
    Layer layer,
    double w,
    double h,
    PDFExportOptions options,
    ui.Offset origin, {
    void Function(ImageElement image)? onMissingImage,
  }) async {
    final hasOpacity = layer.opacity < 1.0;
    if (hasOpacity) {
      g.saveContext();
      g.setGraphicState(PdfGraphicState(opacity: layer.opacity));
    }
    final scale = _scaleFromDpi(options.quality.dpi);
    if (_contentPainter.isLayerVectorizable(layer)) {
      // Vector ops are written in page coordinates (y flipped against [h]);
      // shift them by the origin in PDF space (y up).
      final shifted = origin != ui.Offset.zero;
      if (shifted) {
        g.saveContext();
        g.setTransform(Matrix4.translationValues(origin.dx, -origin.dy, 0));
      }
      await _contentPainter.paintLayerContent(g, doc, layer, w, h,
          paths: pdfPaths, onMissingImage: onMissingImage);
      if (shifted) g.restoreContext();
      // Sticky notes sit above the layer's elements, as on the canvas.
      if (layer.stickyNotes.isNotEmpty) {
        final notes = await _rasterRenderer
            .renderStickyNotes(layer.stickyNotes, w, h, scale, origin: origin);
        _drawRaw(g, doc, notes, w, h);
      }
    } else {
      final raw = await _rasterRenderer.renderLayer(layer, w, h, scale,
          paths: pdfPaths, origin: origin, onMissingImage: onMissingImage);
      _drawRaw(g, doc, raw, w, h);
    }
    if (hasOpacity) g.restoreContext();
  }

  void _drawRaw(
    PdfGraphics g,
    PdfDocument doc,
    PdfRawImage? raw,
    double w,
    double h,
  ) {
    if (raw == null) return;
    g.drawImage(addCompressedRgbaImage(doc, raw), 0, 0, w, h);
  }

  /// Embeds the PDF page behind [page]. False when it should be there but
  /// could not be loaded.
  Future<bool> _embedPdfBackground(
    PdfGraphics g,
    PdfDocument doc,
    Page page,
    double w,
    double h,
    PDFExportOptions options,
    PdfSourcePool sources,
  ) async {
    if (page.background.pdfPageIndex == null) return true;

    // Try rendering from file as JPEG — stores compressed (~200KB) instead
    // of uncompressed RGB+alpha (~8.7MB), preventing OOM on multi-page docs.
    if (page.background.pdfFilePath != null) {
      final jpegBytes = await sources.renderJpeg(
        pdfPaths.resolve(page.background.pdfFilePath!),
        page.background.pdfPageIndex!,
        _scaleFromDpi(options.quality.dpi),
      );
      if (jpegBytes != null) {
        final img = PdfImage.jpeg(doc, image: jpegBytes);
        g.drawImage(img, 0, 0, w, h);
        return true;
      }
    }

    // Fallback: decode pre-rendered PNG data to raw RGBA.
    final pngData = page.background.pdfData;
    if (pngData == null) return false;
    final raw = await decodePngToRawRgba(pngData);
    if (raw == null) return false;
    g.drawImage(addCompressedRgbaImage(doc, raw), 0, 0, w, h);
    return true;
  }
}
