import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/painting.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/sticky_note_painter.dart';
import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';

/// Raw RGBA pixels with their dimensions.
typedef PdfRawImage = ({Uint8List bytes, int width, int height});

/// Renders layer content to raw pixels for the PDF raster fallback.
///
/// Used by `PDFExporter` when a layer cannot be vectorized (textured, glow or
/// eraser strokes, text), and for sticky notes. It paints with the same
/// renderers as the canvas ([ElementSceneRenderer], [StickyNotePainter]), so
/// shapes, text, z-order ([Layer.elementOrder]) and sticky notes match the
/// screen.
class PdfRasterLayerRenderer {
  PdfRasterLayerRenderer({FlutterStrokeRenderer? strokeRenderer})
      : _strokeRenderer = strokeRenderer ?? FlutterStrokeRenderer();

  final FlutterStrokeRenderer _strokeRenderer;

  /// Max pixel count for raster overlays to prevent OOM.
  /// ~3M pixels ≈ 1457×2060 (A4 at ~175 DPI). RGBA = ~12MB per layer.
  static const maxRasterPixels = 3000000;

  /// Rasterizes all of [layer]: elements in z-order, sticky notes on top.
  ///
  /// Content is translated by [origin] (page units) before painting, so an
  /// infinite canvas can export content at negative coordinates.
  Future<PdfRawImage?> renderLayer(
    Layer layer,
    double w,
    double h,
    double scale, {
    PdfPathResolver paths = PdfPathResolver.passthrough,
    Offset origin = Offset.zero,
  }) async {
    final cache = ImageCacheManager(
      paths: paths,
      byteBudget: ImageCacheManager.unboundedBudget,
    );
    try {
      await Future.wait([
        for (final img in layer.images) cache.loadImage(img.filePath),
      ]);
      return await _rasterize(w, h, scale, origin, (canvas) {
        paintElements(canvas, layer, cache);
        paintStickyNotes(canvas, layer.stickyNotes);
      });
    } finally {
      cache.dispose();
    }
  }

  /// Rasterizes only [notes] (for layers whose elements export as vectors),
  /// translated by [origin] like [renderLayer].
  Future<PdfRawImage?> renderStickyNotes(
    List<StickyNote> notes,
    double w,
    double h,
    double scale, {
    Offset origin = Offset.zero,
  }) {
    return _rasterize(w, h, scale, origin, (c) => paintStickyNotes(c, notes));
  }

  /// Paints [layer]'s strokes, shapes, images and texts in screen z-order.
  /// Images missing from [cache] (unreadable files) are skipped.
  void paintElements(Canvas canvas, Layer layer, ImageCacheManager cache) {
    ElementSceneRenderer(
      strokes: layer.strokes,
      shapes: layer.shapes,
      images: [
        for (final img in layer.images)
          if (cache.get(img.filePath) != null) img,
      ],
      texts: layer.texts,
      elementOrder: layer.elementOrder,
      renderer: _strokeRenderer,
      cacheManager: cache,
    ).paint(canvas);
  }

  /// Paints [notes] exactly as the canvas does.
  void paintStickyNotes(Canvas canvas, List<StickyNote> notes) {
    if (notes.isEmpty) return;
    StickyNotePainter(stickyNotes: notes, renderer: _strokeRenderer)
        .paint(canvas, Size.zero);
  }

  Future<PdfRawImage?> _rasterize(
    double w,
    double h,
    double scale,
    Offset origin,
    void Function(Canvas canvas) draw,
  ) async {
    var renderW = (w * scale).toInt();
    var renderH = (h * scale).toInt();
    // Cap resolution to prevent OOM on large/high-DPI pages.
    final pixels = renderW * renderH;
    if (pixels > maxRasterPixels) {
      final ratio = sqrt(maxRasterPixels / pixels);
      renderW = (renderW * ratio).toInt();
      renderH = (renderH * ratio).toInt();
    }
    if (renderW <= 0 || renderH <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Use actual scale based on (possibly capped) render dimensions.
    canvas.scale(renderW / w, renderH / h);
    canvas.translate(origin.dx, origin.dy);
    draw(canvas);

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
}
