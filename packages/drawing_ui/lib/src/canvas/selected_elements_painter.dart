import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/rendering.dart';
import 'package:drawing_ui/src/canvas/shape_painter.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';

/// Renders only the selected strokes, shapes, and images with a live transform.
///
/// During drag/rotate, the committed painters exclude these elements,
/// and this painter draws them with the live delta/rotation applied
/// via canvas.translate/rotate.
class SelectedElementsPainter extends CustomPainter {
  /// Selected strokes to render.
  final List<Stroke> selectedStrokes;

  /// Selected shapes to render.
  final List<Shape> selectedShapes;

  /// Selected images to render.
  final List<ImageElement> selectedImages;

  /// Selected texts to render.
  final List<TextElement> selectedTexts;

  /// Image cache manager for rendering images.
  final ImageCacheManager? imageCacheManager;

  /// Live drag offset.
  final Offset moveDelta;

  /// Live rotation angle in radians.
  final double rotation;

  /// Live horizontal scale factor.
  final double scaleX;

  /// Live vertical scale factor.
  final double scaleY;

  /// Center X of the selection (for rotation/scale pivot).
  final double centerX;

  /// Center Y of the selection (for rotation/scale pivot).
  final double centerY;

  final FlutterStrokeRenderer _renderer;

  SelectedElementsPainter({
    required this.selectedStrokes,
    required this.selectedShapes,
    this.selectedImages = const [],
    this.selectedTexts = const [],
    this.imageCacheManager,
    required this.moveDelta,
    required this.rotation,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    required this.centerX,
    required this.centerY,
    FlutterStrokeRenderer? renderer,
  }) : _renderer = renderer ?? FlutterStrokeRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedStrokes.isEmpty &&
        selectedShapes.isEmpty &&
        selectedImages.isEmpty &&
        selectedTexts.isEmpty) {
      return;
    }

    canvas.save();

    // Apply live transform: translate to center, rotate, scale, translate back + delta
    canvas.translate(centerX + moveDelta.dx, centerY + moveDelta.dy);
    if (rotation != 0) {
      canvas.rotate(rotation);
    }
    if (scaleX != 1.0 || scaleY != 1.0) {
      canvas.scale(scaleX, scaleY);
    }
    canvas.translate(-centerX, -centerY);

    // Render strokes
    _renderer.renderStrokes(canvas, selectedStrokes);

    // Render shapes using a temporary ShapePainter's draw logic
    if (selectedShapes.isNotEmpty) {
      final shapePainter = ShapePainter(shapes: selectedShapes);
      shapePainter.paint(canvas, size);
    }

    // Render images
    if (selectedImages.isNotEmpty && imageCacheManager != null) {
      for (final image in selectedImages) {
        _drawImage(canvas, image, imageCacheManager!);
      }
    }

    // Render texts
    if (selectedTexts.isNotEmpty) {
      for (final text in selectedTexts) {
        _drawText(canvas, text);
      }
    }

    canvas.restore();
  }

  void _drawImage(
    Canvas canvas,
    ImageElement element,
    ImageCacheManager cacheManager,
  ) {
    final cachedImage = cacheManager.get(element.filePath);
    if (cachedImage == null) return;

    canvas.save();
    if (element.rotation != 0.0) {
      final cx = element.x + element.width / 2;
      final cy = element.y + element.height / 2;
      canvas.translate(cx, cy);
      canvas.rotate(element.rotation);
      canvas.translate(-cx, -cy);
    }

    final src = Rect.fromLTWH(
      0, 0,
      cachedImage.width.toDouble(),
      cachedImage.height.toDouble(),
    );
    final dst = Rect.fromLTWH(
      element.x, element.y, element.width, element.height,
    );
    canvas.drawImageRect(cachedImage, src, dst, Paint());
    canvas.restore();
  }

  void _drawText(Canvas canvas, TextElement text) {
    if (text.text.isEmpty) return;

    final textStyle = ui.TextStyle(
      color: Color(text.color),
      fontSize: text.fontSize,
      fontFamily: text.fontFamily,
      fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration:
          text.isUnderline ? TextDecoration.underline : TextDecoration.none,
    );

    final paragraphStyle = ui.ParagraphStyle(maxLines: null);
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(text.text);

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: text.width ?? 1000.0));
    canvas.drawParagraph(paragraph, Offset(text.x, text.y));
  }

  @override
  bool shouldRepaint(covariant SelectedElementsPainter oldDelegate) {
    return oldDelegate.moveDelta != moveDelta ||
        oldDelegate.rotation != rotation ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.centerX != centerX ||
        oldDelegate.centerY != centerY ||
        !identical(oldDelegate.selectedStrokes, selectedStrokes) ||
        !identical(oldDelegate.selectedShapes, selectedShapes) ||
        !identical(oldDelegate.selectedImages, selectedImages) ||
        !identical(oldDelegate.selectedTexts, selectedTexts);
  }
}
