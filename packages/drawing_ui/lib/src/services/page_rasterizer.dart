import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:pdfx/pdfx.dart' as pdfx;

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_raster.dart';
import 'package:drawing_ui/src/services/pdf_raster_layer_renderer.dart';

/// Renders a page off-screen with the same painters as the canvas.
///
/// [PageBackgroundRaster] paints the background (`PageBackgroundPatternPainter`
/// and through it `TemplatePatternPainter` / `CoverRenderer`), the PDF page is
/// decoded from the document, and [PdfRasterLayerRenderer] paints the layer
/// content (`ElementSceneRenderer`, `StickyNotePainter`). Nothing is read from
/// the on-screen canvas, so zoom, pan and selection overlays never leak in.
///
/// Shared by thumbnails and PNG export.
abstract final class PageRasterizer {
  static final PdfRasterLayerRenderer _layerRenderer = PdfRasterLayerRenderer();

  /// Renders [region] of [page] (page coordinates; defaults to the page rect)
  /// into a `width` x `height` image, scaled to fit and centered on
  /// [backgroundColor]. The caller disposes the returned image.
  ///
  /// [pdfRenderScale] is the resolution of the decoded PDF background relative
  /// to PDF points. Throws if rendering fails.
  static Future<ui.Image> render(
    Page page, {
    required int width,
    required int height,
    Rect? region,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
    double pdfRenderScale = 0.5,
  }) async {
    final pageSize = Size(page.size.width, page.size.height);
    final area = region ?? Offset.zero & pageSize;
    final images = ImageCacheManager();
    ui.Image? pdfImage;
    ui.Image? coverImage;
    try {
      // Async work first, so the recording below is synchronous.
      if (page.background.type == BackgroundType.pdf) {
        pdfImage = await _loadPdfBackground(page, pdfPaths, pdfRenderScale);
      }
      coverImage = await PageBackgroundRaster.prepare(page.background);
      final visibleLayers = [
        for (final layer in page.layers)
          if (layer.isVisible) layer,
      ];
      await Future.wait([
        for (final layer in visibleLayers)
          for (final img in layer.images) images.loadImage(img.filePath),
      ]);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = backgroundColor,
      );

      // Fit the region and center it.
      final scaleX = width / area.width;
      final scaleY = height / area.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      canvas.save();
      canvas.translate(
        (width - area.width * scale) / 2,
        (height - area.height * scale) / 2,
      );
      canvas.scale(scale);
      canvas.clipRect(Offset.zero & area.size);

      // Paper fills the whole region (an infinite canvas grows past the page).
      PageBackgroundRaster.paint(
          canvas, page.background, area.size, coverImage);

      // From here on, page coordinates.
      canvas.translate(-area.left, -area.top);
      if (pdfImage != null) {
        canvas.drawImageRect(
          pdfImage,
          Rect.fromLTWH(
              0, 0, pdfImage.width.toDouble(), pdfImage.height.toDouble()),
          Offset.zero & pageSize,
          Paint()..filterQuality = FilterQuality.high,
        );
      }

      // Layer content exactly as the canvas paints it: each layer in its own
      // compositing layer (blend modes such as the highlighter's multiply
      // only mix with that layer's ink), elements in z-order, sticky notes
      // on top.
      for (final layer in visibleLayers) {
        canvas.saveLayer(area, Paint());
        _layerRenderer.paintElements(canvas, layer, images);
        _layerRenderer.paintStickyNotes(canvas, layer.stickyNotes);
        canvas.restore();
      }
      canvas.restore();

      final picture = recorder.endRecording();
      try {
        return await picture.toImage(width, height);
      } finally {
        picture.dispose();
      }
    } finally {
      images.dispose();
      pdfImage?.dispose();
      coverImage?.dispose();
    }
  }

  /// [render] encoded as PNG bytes. Throws if rendering or encoding fails.
  static Future<Uint8List> renderPng(
    Page page, {
    required int width,
    required int height,
    Rect? region,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
    double pdfRenderScale = 0.5,
  }) async {
    final image = await render(
      page,
      width: width,
      height: height,
      region: region,
      backgroundColor: backgroundColor,
      pdfPaths: pdfPaths,
      pdfRenderScale: pdfRenderScale,
    );
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('PNG encoding failed');
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Decodes the PDF page behind [page], from in-memory `pdfData` or the
  /// lazy-loaded `pdfFilePath`. Null when missing or unreadable.
  static Future<ui.Image?> _loadPdfBackground(
    Page page,
    PdfPathResolver pdfPaths,
    double renderScale,
  ) async {
    final background = page.background;
    if (background.pdfPageIndex == null) return null;
    try {
      var bytes = background.pdfData;
      if (bytes == null && background.pdfFilePath != null) {
        bytes = await _renderPdfPageFromFile(
          pdfPaths.resolve(background.pdfFilePath!),
          background.pdfPageIndex!,
          renderScale,
        );
      }
      if (bytes == null) return null;
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  /// Renders a single PDF page from file path, returning PNG bytes.
  static Future<Uint8List?> _renderPdfPageFromFile(
    String filePath,
    int pageIndex,
    double renderScale,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    pdfx.PdfDocument? document;
    pdfx.PdfPage? pdfPage;
    try {
      document = await pdfx.PdfDocument.openFile(filePath);
      pdfPage = await document.getPage(pageIndex);
      final pageImage = await pdfPage.render(
        width: pdfPage.width * renderScale,
        height: pdfPage.height * renderScale,
        format: pdfx.PdfPageImageFormat.png,
      );
      return pageImage?.bytes;
    } finally {
      try {
        await pdfPage?.close();
      } catch (_) {}
      try {
        await document?.close();
      } catch (_) {}
    }
  }
}
