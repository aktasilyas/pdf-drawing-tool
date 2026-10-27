import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter/services.dart' show rootBundle;
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_painter.dart';
import 'package:drawing_ui/src/painters/cover/cover_texture_store.dart';
import 'package:drawing_ui/src/services/pdf_raster_layer_renderer.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

/// Generates thumbnail images for pages.
///
/// A thumbnail is a scaled-down render of the page with the same painters as
/// the canvas: [PageBackgroundPatternPainter] (and through it
/// `TemplatePatternPainter` / `CoverRenderer`) for the background, and
/// `ElementSceneRenderer` / `StickyNotePainter` (via
/// [PdfRasterLayerRenderer]) for the layer content. There is no second,
/// simplified renderer here.
class ThumbnailGenerator {
  /// Default thumbnail width in pixels.
  static const double defaultWidth = 150;

  /// Default thumbnail height in pixels.
  static const double defaultHeight = 200;

  /// Shared canvas element painter (stroke renderer, sticky notes).
  static final PdfRasterLayerRenderer _layerRenderer =
      PdfRasterLayerRenderer();

  /// Generates a cache key for a page.
  ///
  /// The key includes the page ID and last update timestamp,
  /// ensuring the cache is invalidated when content changes.
  static String getCacheKey(Page page) {
    return '${page.id}_${page.updatedAt.millisecondsSinceEpoch}';
  }

  /// Generates a thumbnail image for the given page.
  ///
  /// Returns a PNG image as [Uint8List], or null if generation fails.
  ///
  /// The thumbnail is scaled proportionally to fit within [width] x [height],
  /// maintaining the aspect ratio of the page.
  static Future<Uint8List?> generate(
    Page page, {
    double width = defaultWidth,
    double height = defaultHeight,
    Color backgroundColor = Colors.white,
    PdfPathResolver pdfPaths = PdfPathResolver.passthrough,
  }) async {
    final images = ImageCacheManager();
    ui.Image? pdfImage;
    ui.Image? coverImage;
    try {
      // Async work first, so the recording below is synchronous.
      if (page.background.type == BackgroundType.pdf) {
        pdfImage = await _loadPdfBackground(page, pdfPaths);
      }
      coverImage = await _loadCoverImage(page.background);
      if (_isMaterialCover(page.background)) {
        await CoverTextureStore.ensureLoaded();
      }
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
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = backgroundColor,
      );

      // Scale the page to fit and center it.
      final scaleX = width / page.size.width;
      final scaleY = height / page.size.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      final offsetX = (width - page.size.width * scale) / 2;
      final offsetY = (height - page.size.height * scale) / 2;

      canvas.save();
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale);

      final pageSize = Size(page.size.width, page.size.height);
      _paintBackground(canvas, page.background, pageSize, coverImage);
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
      final pageRect = Offset.zero & pageSize;
      for (final layer in visibleLayers) {
        canvas.saveLayer(pageRect, Paint());
        _layerRenderer.paintElements(canvas, layer, images);
        _layerRenderer.paintStickyNotes(canvas, layer.stickyNotes);
        canvas.restore();
      }

      canvas.restore();

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      picture.dispose();
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (_) {
      // Return null on any error (e.g., invalid dimensions, rendering issues)
      return null;
    } finally {
      images.dispose();
      pdfImage?.dispose();
      coverImage?.dispose();
    }
  }

  /// Base color, then the image cover (if any), then the canvas background
  /// painter (grid / lines / dots / templates / material and other covers).
  static void _paintBackground(
    Canvas canvas,
    PageBackground background,
    Size size,
    ui.Image? coverImage,
  ) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Color(background.color),
    );
    if (coverImage != null) {
      canvas.drawImageRect(
        coverImage,
        Rect.fromLTWH(
            0, 0, coverImage.width.toDouble(), coverImage.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    PageBackgroundPatternPainter(background: background).paint(canvas, size);
  }

  static bool _isMaterialCover(PageBackground background) {
    if (background.type != BackgroundType.cover) return false;
    final id = background.coverId;
    return id != null && CoverRegistry.byId(id)?.style == CoverStyle.material;
  }

  /// Loads the asset of an image cover; null for every other background or
  /// when the asset cannot be loaded (the base color stays visible).
  static Future<ui.Image?> _loadCoverImage(PageBackground background) async {
    if (background.type != BackgroundType.cover) return null;
    final id = background.coverId;
    final cover = id == null ? null : CoverRegistry.byId(id);
    if (cover?.style != CoverStyle.image || cover?.imagePath == null) {
      return null;
    }
    try {
      final data = await rootBundle.load(cover!.imagePath!);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  /// Decodes the PDF page behind [page], from in-memory `pdfData` or the
  /// lazy-loaded `pdfFilePath`. Null when missing or unreadable.
  static Future<ui.Image?> _loadPdfBackground(
    Page page,
    PdfPathResolver pdfPaths,
  ) async {
    final background = page.background;
    if (background.pdfPageIndex == null) return null;
    try {
      var bytes = background.pdfData;
      if (bytes == null && background.pdfFilePath != null) {
        bytes = await _renderPdfPageFromFile(
          pdfPaths.resolve(background.pdfFilePath!),
          background.pdfPageIndex!,
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
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    pdfx.PdfDocument? document;
    pdfx.PdfPage? pdfPage;
    try {
      document = await pdfx.PdfDocument.openFile(filePath);
      pdfPage = await document.getPage(pageIndex);

      final pageImage = await pdfPage.render(
        width: pdfPage.width * 0.5,
        height: pdfPage.height * 0.5,
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
