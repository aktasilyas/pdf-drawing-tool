import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart' hide Page;

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_raster.dart';
import 'package:drawing_ui/src/services/pdf_document_pool.dart';
import 'package:drawing_ui/src/services/pdf_raster_layer_renderer.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';

/// PNG bytes of a rendered page, and whether its PDF background was meant to
/// be drawn but could not be loaded.
typedef PageRasterPng = ({Uint8List bytes, bool pdfBackgroundMissing});

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
  /// to PDF points. With [pdfDocuments] (thumbnails) the PDF background is
  /// instead decoded at the output size of the page, through documents kept
  /// open by the pool. A PDF background that cannot be loaded is logged and
  /// left out. Throws if rendering fails.
  static Future<ui.Image> render(
    Page page, {
    required int width,
    required int height,
    Rect? region,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
    double pdfRenderScale = 0.5,
    PdfDocumentPool? pdfDocuments,
  }) async {
    final result = await _render(
      page,
      width: width,
      height: height,
      region: region,
      backgroundColor: backgroundColor,
      pdfPaths: pdfPaths,
      pdfRenderScale: pdfRenderScale,
      pdfDocuments: pdfDocuments,
    );
    return result.image;
  }

  static Future<({ui.Image image, bool pdfBackgroundMissing})> _render(
    Page page, {
    required int width,
    required int height,
    required Rect? region,
    required Color backgroundColor,
    required PdfPathResolver pdfPaths,
    required double pdfRenderScale,
    required PdfDocumentPool? pdfDocuments,
  }) async {
    final pageSize = Size(page.size.width, page.size.height);
    final area = region ?? Offset.zero & pageSize;
    final images = ImageCacheManager(
      paths: pdfPaths,
      byteBudget: ImageCacheManager.unboundedBudget,
    );
    // Fit the region and center it.
    final scaleX = width / area.width;
    final scaleY = height / area.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    ui.Image? pdfImage;
    ui.Image? coverImage;
    try {
      // Async work first, so the recording below is synchronous.
      if (page.background.type == BackgroundType.pdf) {
        pdfImage = await _loadPdfBackground(
          page,
          pdfPaths,
          pdfRenderScale,
          pdfDocuments,
          outputSize: pageSize * scale,
        );
      }
      coverImage = await PageBackgroundRaster.prepare(page.background);
      final visibleLayers = [
        for (final layer in page.layers)
          if (layer.isVisible && layer.opacity > 0) layer,
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

      canvas.save();
      canvas.translate(
        (width - area.width * scale) / 2,
        (height - area.height * scale) / 2,
      );
      canvas.scale(scale);

      // Paper fills the whole region (an infinite canvas grows past the page).
      // Its pattern starts at the region's corner, as in the PDF export of an
      // infinite canvas; on a paged document the region is the page rect.
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
      // on top. The layer's opacity applies to the composited layer, as on the
      // canvas and in the PDF export.
      for (final layer in visibleLayers) {
        canvas.saveLayer(
          area,
          Paint()..color = Color.fromRGBO(0, 0, 0, layer.opacity),
        );
        _layerRenderer.paintElements(canvas, layer, images);
        _layerRenderer.paintStickyNotes(canvas, layer.stickyNotes);
        canvas.restore();
      }
      canvas.restore();

      final picture = recorder.endRecording();
      try {
        final image = await picture.toImage(width, height);
        return (
          image: image,
          pdfBackgroundMissing: pdfImage == null && _expectsPdf(page),
        );
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
    PdfDocumentPool? pdfDocuments,
  }) async {
    final result = await renderPngWithStatus(
      page,
      width: width,
      height: height,
      region: region,
      backgroundColor: backgroundColor,
      pdfPaths: pdfPaths,
      pdfRenderScale: pdfRenderScale,
      pdfDocuments: pdfDocuments,
    );
    return result.bytes;
  }

  /// [renderPng] that also reports whether the page's PDF background could
  /// not be loaded, so an export can tell the user.
  static Future<PageRasterPng> renderPngWithStatus(
    Page page, {
    required int width,
    required int height,
    Rect? region,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
    double pdfRenderScale = 0.5,
    PdfDocumentPool? pdfDocuments,
  }) async {
    final result = await _render(
      page,
      width: width,
      height: height,
      region: region,
      backgroundColor: backgroundColor,
      pdfPaths: pdfPaths,
      pdfRenderScale: pdfRenderScale,
      pdfDocuments: pdfDocuments,
    );
    final image = result.image;
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('PNG encoding failed');
      return (
        bytes: byteData.buffer.asUint8List(),
        pdfBackgroundMissing: result.pdfBackgroundMissing,
      );
    } finally {
      image.dispose();
    }
  }

  /// Whether [page] has a PDF page behind it that should be drawn.
  static bool _expectsPdf(Page page) =>
      page.background.type == BackgroundType.pdf &&
      page.background.pdfPageIndex != null;

  /// Decodes the PDF page behind [page], from in-memory `pdfData` or the
  /// lazy-loaded `pdfFilePath`, or the image file behind `imageFilePath`.
  /// Null, and logged, when missing or unreadable.
  ///
  /// With [pdfDocuments] the file is rendered at [outputSize] (the page's
  /// size in the output image) through the pool's open document; otherwise
  /// it is opened for this render at [renderScale] x its PDF point size.
  static Future<ui.Image?> _loadPdfBackground(
    Page page,
    PdfPathResolver pdfPaths,
    double renderScale,
    PdfDocumentPool? pdfDocuments, {
    required Size outputSize,
  }) async {
    final background = page.background;
    if (background.pdfPageIndex == null) return null;
    try {
      var bytes = background.pdfData;
      if (bytes == null && background.pdfFilePath != null) {
        final path = pdfPaths.resolve(background.pdfFilePath!);
        bytes = pdfDocuments == null
            ? await renderPdfPageAtScale(
                path, background.pdfPageIndex!, renderScale)
            : await pdfDocuments.renderPage(
                path,
                background.pdfPageIndex!,
                width: thumbnailPdfPixels(outputSize.width),
                height: thumbnailPdfPixels(outputSize.height),
              );
      }
      if (bytes == null && background.imageFilePath != null) {
        final file = File(pdfPaths.resolve(background.imageFilePath!));
        if (await file.exists()) bytes = await file.readAsBytes();
      }
      if (bytes == null) {
        DrawingLog.w(
          'PDF background missing for page ${page.id} '
          '(PDF page ${background.pdfPageIndex}, ${background.pdfFilePath})',
        );
        return null;
      }
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    } catch (e, st) {
      DrawingLog.w(
        'PDF background unreadable for page ${page.id} '
        '(PDF page ${background.pdfPageIndex})',
        e,
        st,
      );
      return null;
    }
  }

  /// Longest side, in pixels, of a PDF background decoded for a thumbnail.
  static const int maxThumbnailPdfSide = 2048;

  /// Pixel length of a thumbnail's PDF background for [logical] output
  /// pixels: rounded up, at least 1 and at most [maxThumbnailPdfSide].
  static int thumbnailPdfPixels(double logical) =>
      math.min(maxThumbnailPdfSide, math.max(1, logical.ceil()));
}
