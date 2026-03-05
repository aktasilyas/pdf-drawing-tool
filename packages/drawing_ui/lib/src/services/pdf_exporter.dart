import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';
import 'pdf_content_painter.dart';
import 'pdf_export_models.dart';
import 'pdf_raster_layer_renderer.dart';

// Re-export models so existing imports continue to work.
export 'pdf_export_models.dart';

/// Hybrid vector+raster PDF exporter.
///
/// Vectorizable content (plain strokes, shapes, images) is rendered as PDF
/// vector operations for infinite-zoom sharpness. Non-vectorizable content
/// (textured/glow/eraser strokes, text) falls back to lossless PNG overlay.
class PDFExporter {
  final _contentPainter = PdfContentPainter();
  final _strokeRenderer = FlutterStrokeRenderer();
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
      for (int i = 0; i < pages.length; i++) {
        if (isCancelled?.call() == true) return PDFExportResult.cancelled();
        final page = pages[i];
        if (page.size.width <= 0 || page.size.height <= 0) continue;
        await _exportPage(doc, page, options);
        onProgress?.call(i + 1, pages.length);
      }
      final bytes = await doc.save();
      return PDFExportResult.success(bytes);
    } catch (e) {
      return PDFExportResult.error(e.toString());
    }
  }

  Future<void> _exportPage(
    PdfDocument doc, Page page, PDFExportOptions options,
  ) async {
    double pdfW, pdfH;
    if (options.isInfiniteCanvas) {
      final bounds = _calculateInfiniteCanvasBounds(page);
      pdfW = bounds.width;
      pdfH = bounds.height;
    } else {
      pdfW = page.size.width;
      pdfH = page.size.height;
    }

    final pdfPage = PdfPage(doc, pageFormat: PdfPageFormat(pdfW, pdfH));
    final g = pdfPage.getGraphics();

    if (options.includeBackground) {
      _contentPainter.paintBackground(g, page.background, pdfW, pdfH);
    }
    if (page.background.type == BackgroundType.pdf) {
      await _embedPdfBackground(g, doc, page, pdfW, pdfH, options);
    }
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;
      await _renderLayer(g, doc, layer, pdfW, pdfH, options);
    }

    if (options.addWatermark) {
      _drawWatermark(g, doc, pdfW, pdfH);
    }
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
    PdfGraphics g, PdfDocument doc, Layer layer,
    double w, double h, PDFExportOptions options,
  ) async {
    final hasOpacity = layer.opacity < 1.0;
    if (hasOpacity) {
      g.saveContext();
      g.setGraphicState(PdfGraphicState(opacity: layer.opacity));
    }
    if (_contentPainter.isLayerVectorizable(layer)) {
      await _contentPainter.paintLayerContent(g, doc, layer, w, h);
    } else {
      await _renderRasterOverlay(g, doc, layer, w, h, options);
    }
    if (hasOpacity) g.restoreContext();
  }

  Future<void> _renderRasterOverlay(
    PdfGraphics g, PdfDocument doc, Layer layer,
    double w, double h, PDFExportOptions options,
  ) async {
    final raw = await _renderLayerToRaw(layer, w, h, options);
    if (raw == null) return;
    final img = PdfImage(doc,
        image: raw.bytes, width: raw.width, height: raw.height);
    g.drawImage(img, 0, 0, w, h);
  }

  /// Max pixel count for raster overlays to prevent OOM.
  /// ~3M pixels ≈ 1457×2060 (A4 at ~175 DPI). RGBA = ~12MB per layer.
  static const _maxRasterPixels = 3000000;

  /// Renders layer content to raw RGBA pixels via Flutter Canvas.
  Future<_RawImageData?> _renderLayerToRaw(
    Layer layer, double w, double h, PDFExportOptions options,
  ) async {
    final scale = _scaleFromDpi(options.quality.dpi);
    var renderW = (w * scale).toInt();
    var renderH = (h * scale).toInt();
    // Cap resolution to prevent OOM on large/high-DPI pages.
    final pixels = renderW * renderH;
    if (pixels > _maxRasterPixels) {
      final ratio = sqrt(_maxRasterPixels / pixels);
      renderW = (renderW * ratio).toInt();
      renderH = (renderH * ratio).toInt();
    }
    if (renderW <= 0 || renderH <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Use actual scale based on (possibly capped) render dimensions.
    canvas.scale(renderW / w, renderH / h);

    _strokeRenderer.renderStrokes(canvas, layer.strokes);
    _rasterRenderer.renderShapes(canvas, layer.shapes);
    await _rasterRenderer.renderImages(canvas, layer.images);
    _rasterRenderer.renderTexts(canvas, layer.texts);

    final picture = recorder.endRecording();
    final image = await picture.toImage(renderW, renderH);
    picture.dispose();
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;
      return (
        bytes: byteData.buffer.asUint8List(),
        width: renderW,
        height: renderH,
      );
    } finally {
      image.dispose();
    }
  }

  Future<void> _embedPdfBackground(
    PdfGraphics g, PdfDocument doc, Page page,
    double w, double h, PDFExportOptions options,
  ) async {
    if (page.background.pdfPageIndex == null) return;

    // Try rendering from file as JPEG — stores compressed (~200KB) instead
    // of uncompressed RGB+alpha (~8.7MB), preventing OOM on multi-page docs.
    if (page.background.pdfFilePath != null) {
      final jpegBytes = await _renderPdfPageAsJpeg(
        page.background.pdfFilePath!,
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
    final img = PdfImage(doc,
        image: raw.bytes, width: raw.width, height: raw.height);
    g.drawImage(img, 0, 0, w, h);
  }

  Future<Uint8List?> _renderPdfPageAsJpeg(
    String path, int index, double renderScale,
  ) async {
    if (!await File(path).exists()) return null;
    pdfx.PdfDocument? pdfDoc;
    pdfx.PdfPage? pg;
    try {
      pdfDoc = await pdfx.PdfDocument.openFile(path);
      pg = await pdfDoc.getPage(index);
      final img = await pg.render(
        width: pg.width * renderScale,
        height: pg.height * renderScale,
        format: pdfx.PdfPageImageFormat.jpeg,
        quality: 90,
      );
      return img?.bytes;
    } finally {
      try { await pg?.close(); } catch (_) {}
      try { await pdfDoc?.close(); } catch (_) {}
    }
  }

  Rect? _calculateContentBounds(Page page) {
    double? minX, minY, maxX, maxY;
    void expand(BoundingBox b) {
      minX = minX == null ? b.left : min(minX!, b.left);
      minY = minY == null ? b.top : min(minY!, b.top);
      maxX = maxX == null ? b.right : max(maxX!, b.right);
      maxY = maxY == null ? b.bottom : max(maxY!, b.bottom);
    }
    for (final layer in page.layers) {
      if (!layer.isVisible) continue;
      for (final stroke in layer.strokes) {
        final b = stroke.bounds;
        if (b != null) expand(b);
      }
      for (final shape in layer.shapes) { expand(shape.bounds); }
      for (final img in layer.images) { expand(img.bounds); }
      for (final text in layer.texts) { expand(text.bounds); }
      for (final note in layer.stickyNotes) { expand(note.bounds); }
    }
    if (minX == null) return null;
    return Rect.fromLTRB(minX!, minY!, maxX!, maxY!);
  }

  ({double width, double height, double offsetX, double offsetY})
      _calculateInfiniteCanvasBounds(Page page) {
    final pageW = page.size.width;
    final pageH = page.size.height;
    final contentRect = _calculateContentBounds(page);
    const padding = 24.0;
    final double left, top, right, bottom;
    if (contentRect != null) {
      left = min(0.0, contentRect.left - padding);
      top = min(0.0, contentRect.top - padding);
      right = max(pageW, contentRect.right + padding);
      bottom = max(pageH, contentRect.bottom + padding);
    } else {
      left = 0; top = 0; right = pageW; bottom = pageH;
    }
    return (
      width: right - left,
      height: bottom - top,
      offsetX: -left,
      offsetY: -top,
    );
  }

  /// Decodes PNG bytes to raw RGBA using Flutter's native image codec.
  Future<_RawImageData?> _decodeToRawRgba(Uint8List pngBytes) async {
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

/// Raw RGBA image data with dimensions.
typedef _RawImageData = ({Uint8List bytes, int width, int height});
