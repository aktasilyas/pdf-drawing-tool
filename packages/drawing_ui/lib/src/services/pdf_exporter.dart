import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';

import 'pdf_background_rasterizer.dart';
import 'pdf_compressed_image.dart';
import 'pdf_content_painter.dart';
import 'pdf_export_bounds.dart';
import 'pdf_export_models.dart';
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

  /// Resolves stored PDF paths of lazy PDF backgrounds to files on disk.
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
    if (pages.isEmpty) return PDFExportResult.error('Sayfa bulunamadı');

    try {
      final doc = PdfDocument();
      final sources = PdfSourcePool(_openSource);
      // Per export, so concurrent exports never share or evict images.
      final backgrounds = PdfBackgroundRasterizer();
      try {
        for (int i = 0; i < pages.length; i++) {
          if (isCancelled?.call() == true) return PDFExportResult.cancelled();
          final page = pages[i];
          if (page.size.width <= 0 || page.size.height <= 0) continue;
          await _exportPage(doc, page, options, sources, backgrounds);
          onProgress?.call(i + 1, pages.length);
        }
      } finally {
        await sources.closeAll();
      }
      final bytes = await doc.save();
      return PDFExportResult.success(bytes);
    } catch (e) {
      return PDFExportResult.error(e.toString());
    }
  }

  Future<void> _exportPage(
    PdfDocument doc,
    Page page,
    PDFExportOptions options,
    PdfSourcePool sources,
    PdfBackgroundRasterizer backgrounds,
  ) async {
    double pdfW, pdfH;
    if (options.isInfiniteCanvas) {
      final bounds = infiniteCanvasExportBounds(page);
      pdfW = bounds.width;
      pdfH = bounds.height;
    } else {
      pdfW = page.size.width;
      pdfH = page.size.height;
    }

    final pdfPage = PdfPage(doc, pageFormat: PdfPageFormat(pdfW, pdfH));
    final g = pdfPage.getGraphics();

    if (options.includeBackground) {
      await _paintBackground(
          g, doc, page.background, pdfW, pdfH, options, backgrounds);
    }
    if (page.background.type == BackgroundType.pdf) {
      await _embedPdfBackground(g, doc, page, pdfW, pdfH, options, sources);
    }
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;
      await _renderLayer(g, doc, layer, pdfW, pdfH, options);
    }

    if (options.addWatermark) {
      _drawWatermark(g, doc, pdfW, pdfH);
    }
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
  ) async {
    final hasOpacity = layer.opacity < 1.0;
    if (hasOpacity) {
      g.saveContext();
      g.setGraphicState(PdfGraphicState(opacity: layer.opacity));
    }
    final scale = _scaleFromDpi(options.quality.dpi);
    if (_contentPainter.isLayerVectorizable(layer)) {
      await _contentPainter.paintLayerContent(g, doc, layer, w, h);
      // Sticky notes sit above the layer's elements, as on the canvas.
      if (layer.stickyNotes.isNotEmpty) {
        final notes = await _rasterRenderer.renderStickyNotes(
            layer.stickyNotes, w, h, scale);
        _drawRaw(g, doc, notes, w, h);
      }
    } else {
      final raw = await _rasterRenderer.renderLayer(layer, w, h, scale);
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

  Future<void> _embedPdfBackground(
    PdfGraphics g,
    PdfDocument doc,
    Page page,
    double w,
    double h,
    PDFExportOptions options,
    PdfSourcePool sources,
  ) async {
    if (page.background.pdfPageIndex == null) return;

    // Try rendering from file as JPEG — stores compressed (~200KB) instead
    // of uncompressed RGB+alpha (~8.7MB), preventing OOM on multi-page docs.
    if (page.background.pdfFilePath != null) {
      final jpegBytes = await _renderPdfPageAsJpeg(
        sources,
        pdfPaths.resolve(page.background.pdfFilePath!),
        page.background.pdfPageIndex!,
        _scaleFromDpi(options.quality.dpi),
      );
      if (jpegBytes != null) {
        final img = PdfImage.jpeg(doc, image: jpegBytes);
        g.drawImage(img, 0, 0, w, h);
        return;
      }
    }

    // Fallback: decode pre-rendered PNG data to raw RGBA.
    final pngData = page.background.pdfData;
    if (pngData == null) return;
    final raw = await _decodeToRawRgba(pngData);
    if (raw == null) return;
    g.drawImage(addCompressedRgbaImage(doc, raw), 0, 0, w, h);
  }

  Future<Uint8List?> _renderPdfPageAsJpeg(
    PdfSourcePool sources,
    String path,
    int index,
    double renderScale,
  ) async {
    final source = await sources.get(path);
    if (source == null) return null;
    return source.renderJpeg(index, renderScale);
  }

  /// Decodes PNG bytes to raw RGBA using Flutter's native image codec.
  Future<PdfRawImage?> _decodeToRawRgba(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      return (
        bytes: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
    } finally {
      image.dispose();
    }
  }
}
