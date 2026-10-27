import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:pasteboard/pasteboard.dart';

import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/canvas/page_background_raster.dart';
import 'package:drawing_ui/src/rendering/element_scene_renderer.dart';
import 'package:drawing_ui/src/rendering/flutter_stroke_renderer.dart';

/// Captures selected elements as a PNG, exactly as the canvas draws them.
///
/// It owns no drawing code: the page background goes through
/// [PageBackgroundRaster] (templates, covers, patterns) and the selected
/// elements through [ElementSceneRenderer] (real pen geometry, z-order), the
/// same painters thumbnails and export use. Also provides save-to-gallery and
/// copy-to-clipboard.
class SelectionCaptureService {
  const SelectionCaptureService._();

  /// High-resolution scale factor of the captured image.
  static const double exportScale = 3.0;

  /// Page size assumed when the caller does not know it.
  static const Size fallbackPageSize = Size(2000, 2000);

  /// Captures the selected elements of [layer] as PNG bytes, or null if
  /// rendering fails. See [renderSelection] for the parameters.
  static Future<Uint8List?> captureSelection({
    required Selection selection,
    required Layer layer,
    required ImageCacheManager cacheManager,
    PageBackground? background,
    Uint8List? pdfImageBytes,
    Size? pageSize,
    double padding = 16.0,
  }) async {
    try {
      final image = await renderSelection(
        selection: selection,
        layer: layer,
        cacheManager: cacheManager,
        background: background,
        pdfImageBytes: pdfImageBytes,
        pageSize: pageSize,
        padding: padding,
      );
      if (image == null) return null;
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data?.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    } catch (_) {
      // Callers report a null result to the user.
      return null;
    }
  }

  /// Renders the selection to an image of
  /// `(selection bounds + 2 × padding) × exportScale` pixels.
  ///
  /// The page [background] (white when null) is drawn behind the selected
  /// strokes, shapes, images and texts; unselected elements are left out. A
  /// lasso selection clips to its path, any other to the padded bounds. For a
  /// PDF page, [pdfImageBytes] is the encoded page image. Returns null for an
  /// empty selection with no area. The caller disposes the result.
  static Future<ui.Image?> renderSelection({
    required Selection selection,
    required Layer layer,
    required ImageCacheManager cacheManager,
    PageBackground? background,
    Uint8List? pdfImageBytes,
    Size? pageSize,
    double padding = 16.0,
  }) async {
    final bounds = selection.bounds;
    // Nothing selected and no area: nothing to capture (Selection.empty()).
    if (selection.isEmpty && (bounds.width <= 0 || bounds.height <= 0)) {
      return null;
    }
    final padded = Rect.fromLTRB(
      bounds.left - padding,
      bounds.top - padding,
      bounds.right + padding,
      bounds.bottom + padding,
    );
    if (padded.width <= 0 || padded.height <= 0) return null;

    final isPdf = background?.type == BackgroundType.pdf;
    final pdfImage =
        isPdf && pdfImageBytes != null ? await _decode(pdfImageBytes) : null;
    final coverImage = background != null && !isPdf
        ? await PageBackgroundRaster.prepare(background)
        : null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(exportScale)
      ..translate(-padded.left, -padded.top)
      ..clipPath(_clipPath(selection, padded));

    canvas.drawRect(
      padded,
      Paint()..color = Color(background?.color ?? 0xFFFFFFFF),
    );
    if (background != null) {
      final size = pageSize ?? fallbackPageSize;
      if (pdfImage != null) {
        canvas.drawImageRect(
          pdfImage,
          Rect.fromLTWH(
              0, 0, pdfImage.width.toDouble(), pdfImage.height.toDouble()),
          Offset.zero & size,
          Paint(),
        );
      } else if (!isPdf) {
        PageBackgroundRaster.paint(canvas, background, size, coverImage);
      }
    }
    _sceneFor(selection, layer, cacheManager).paint(canvas);

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        (padded.width * exportScale).ceil(),
        (padded.height * exportScale).ceil(),
      );
    } finally {
      picture.dispose();
      pdfImage?.dispose();
      coverImage?.dispose();
    }
  }

  /// Saves PNG bytes to the device gallery.
  static Future<bool> saveToGallery(Uint8List bytes) async {
    try {
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: 'elyanotes_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (result is Map) {
        return result['isSuccess'] == true;
      }
      return result != null;
    } catch (_) {
      return false;
    }
  }

  /// Copies PNG bytes to the system clipboard.
  static Future<bool> copyToClipboard(Uint8List bytes) async {
    try {
      await Pasteboard.writeImage(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The selected elements of [layer], in the layer's z-order. Images not in
  /// [cache] are skipped (no placeholder in an exported image).
  static ElementSceneRenderer _sceneFor(
    Selection selection,
    Layer layer,
    ImageCacheManager cache,
  ) {
    final strokeIds = selection.selectedStrokeIds.toSet();
    final shapeIds = selection.selectedShapeIds.toSet();
    final imageIds = selection.selectedImageIds.toSet();
    final textIds = selection.selectedTextIds.toSet();
    return ElementSceneRenderer(
      strokes: [
        for (final s in layer.strokes)
          if (strokeIds.contains(s.id)) s,
      ],
      shapes: [
        for (final s in layer.shapes)
          if (shapeIds.contains(s.id)) s,
      ],
      images: [
        for (final i in layer.images)
          if (imageIds.contains(i.id) && cache.get(i.filePath) != null) i,
      ],
      texts: [
        for (final t in layer.texts)
          if (textIds.contains(t.id)) t,
      ],
      elementOrder: layer.elementOrder,
      renderer: FlutterStrokeRenderer(),
      cacheManager: cache,
    );
  }

  static Path _clipPath(Selection selection, Rect padded) {
    final lasso = selection.lassoPath;
    if (selection.type != SelectionType.lasso ||
        lasso == null ||
        lasso.length < 3) {
      return Path()..addRect(padded);
    }
    final path = Path()..moveTo(lasso.first.x, lasso.first.y);
    for (var i = 1; i < lasso.length; i++) {
      path.lineTo(lasso[i].x, lasso[i].y);
    }
    return path..close();
  }

  static Future<ui.Image?> _decode(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }
}
