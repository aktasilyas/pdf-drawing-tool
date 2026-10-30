import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:drawing_ui/src/rendering/element_paint_order.dart';
import 'package:drawing_ui/src/rendering/variable_width_renderer.dart';

import 'pdf_background_patterns.dart';
import 'pdf_vector_shapes.dart';
import 'vector_pdf_renderer.dart';

/// Paints drawing content directly onto [PdfGraphics] using vector operations.
///
/// Strokes become PDF bezier paths (infinitely sharp at any zoom),
/// shapes become PDF geometric primitives, and images are embedded directly.
/// Falls back to raster for non-vectorizable content (texture/glow/eraser).
class PdfContentPainter {
  final _vectorHelper = VectorPDFRenderer();
  late final _shapeRenderer = PdfVectorShapeRenderer(_vectorHelper);

  /// Whether a layer can be fully rendered as vectors.
  bool isLayerVectorizable(Layer layer) {
    for (final stroke in layer.strokes) {
      if (!_isStrokeVectorizable(stroke.style)) return false;
    }
    if (layer.texts.isNotEmpty) return false;
    return true;
  }

  bool _isStrokeVectorizable(StrokeStyle style) =>
      style.texture == StrokeTexture.none &&
      style.glowRadius == 0.0 &&
      !style.isEraser;

  /// Paints the background color and legacy vector pattern (grid, lined,
  /// dotted) onto the PDF page. Templates and covers are rasterized with the
  /// canvas painters by `PdfBackgroundRasterizer`; here they only get their
  /// base color (fallback when that raster fails).
  void paintBackground(PdfGraphics g, PageBackground bg, double w, double h) {
    final color = _argbToPdfColor(bg.color);
    g.setFillColor(color);
    g.drawRect(0, 0, w, h);
    g.fillPath();

    final lineColor = bg.lineColor ?? 0xFFE0E0E0;
    final pdfLineColor = _argbToPdfColor(lineColor);
    final lineWidth = bg.templateLineWidth ?? 0.5;

    switch (bg.type) {
      case BackgroundType.blank:
      case BackgroundType.cover:
      case BackgroundType.pdf:
      case BackgroundType.template:
        break;
      case BackgroundType.grid:
        drawPdfGrid(g, w, h, pdfLineColor, bg.gridSpacing ?? 25.0, lineWidth);
      case BackgroundType.lined:
        drawPdfLines(g, w, h, pdfLineColor, bg.lineSpacing ?? 25.0, lineWidth);
      case BackgroundType.dotted:
        drawPdfDots(g, w, h, bg.gridSpacing ?? 20.0, pdfLineColor);
    }
  }

  /// Paints all layer content as vector operations in canvas z-order
  /// ([elementPaintOrder]).
  ///
  /// Images whose file is missing or unreadable are skipped and passed to
  /// [onMissingImage].
  Future<void> paintLayerContent(
    PdfGraphics g,
    PdfDocument doc,
    Layer layer,
    double w,
    double h, {
    PdfPathResolver paths = PdfPathResolver.passthrough,
    void Function(ImageElement image)? onMissingImage,
  }) async {
    Future<void> paintImage(ImageElement img) async {
      final drawn = await _paintImage(g, doc, img, w, h, paths);
      if (!drawn) onMissingImage?.call(img);
    }

    // Same z-order as the canvas, including elements missing from
    // elementOrder (#583). Vector layers never hold texts.
    final ordered = elementPaintOrder<Object>(
      elementOrder: layer.elementOrder,
      strokes: {for (final s in layer.strokes) s.id: s},
      shapes: {for (final s in layer.shapes) s.id: s},
      images: {for (final i in layer.images) i.id: i},
      entry: (_, element) => element,
    );
    for (final element in ordered) {
      switch (element) {
        case final Stroke s:
          _paintStroke(g, s, w, h);
        case final Shape s:
          _shapeRenderer.paintShape(g, s, w, h);
        case final ImageElement i:
          await paintImage(i);
      }
    }
  }

  void _paintStroke(PdfGraphics g, Stroke stroke, double w, double h) {
    if (stroke.points.isEmpty) return;
    final style = stroke.style;

    // Same routing predicate as the on-screen renderers.
    if (VariableWidthStrokeRenderer.usesOutline(style)) {
      _paintOutlineStroke(g, stroke, w, h);
      return;
    }
    if (stroke.points.length == 1) {
      _paintDot(g, stroke, h);
      return;
    }

    final points = _vectorHelper.prepareStroke(stroke);
    if (points.length < 2) return;

    g.saveContext();

    final pdfColor = _vectorHelper.convertColor(style.color);
    final alpha = style.opacity * _vectorHelper.extractAlpha(style.color);
    final blend = _pdfBlendMode(style.blendMode);
    if (alpha < 1.0 || blend != null) {
      g.setGraphicState(
        PdfGraphicState(strokeOpacity: alpha, blendMode: blend),
      );
    }
    g.setStrokeColor(pdfColor);
    g.setLineWidth(style.thickness);

    final penType = _penTypeFromStyle(style);
    g.setLineCap(
        PdfLineCap.values[_vectorHelper.getRecommendedLineCap(penType)]);
    g.setLineJoin(
      PdfLineJoin.values[_vectorHelper.getRecommendedLineJoin(penType)],
    );

    if (style.pattern != StrokePattern.solid && style.dashPattern != null) {
      g.setLineDashPattern(
        style.dashPattern!.map((d) => d as num).toList(),
      );
    }

    _buildStrokePath(g, points, h);
    g.strokePath();
    g.restoreContext();
  }

  /// A single-point stroke (tap) as a filled circle of the stroke width.
  void _paintDot(PdfGraphics g, Stroke stroke, double h) {
    final style = stroke.style;
    final p = stroke.points.first;
    g.saveContext();
    final alpha = style.opacity * _vectorHelper.extractAlpha(style.color);
    final blend = _pdfBlendMode(style.blendMode);
    if (alpha < 1.0 || blend != null) {
      g.setGraphicState(PdfGraphicState(fillOpacity: alpha, blendMode: blend));
    }
    g.setFillColor(_vectorHelper.convertColor(style.color));
    g.drawEllipse(
        p.x, _flipY(p.y, h), style.thickness / 2, style.thickness / 2);
    g.fillPath();
    g.restoreContext();
  }

  /// Fills the same [StrokeOutline] polygon the screen renderers draw.
  void _paintOutlineStroke(PdfGraphics g, Stroke stroke, double w, double h) {
    final style = stroke.style;
    final outline = StrokeOutline.build(
      stroke.points,
      VariableWidthStrokeRenderer.optionsFor(style),
    );
    if (outline.length < 3) return;

    g.saveContext();
    final alpha = style.opacity * _vectorHelper.extractAlpha(style.color);
    final blend = _pdfBlendMode(style.blendMode);
    if (alpha < 1.0 || blend != null) {
      g.setGraphicState(PdfGraphicState(fillOpacity: alpha, blendMode: blend));
    }
    g.setFillColor(_vectorHelper.convertColor(style.color));

    g.moveTo(outline.first.x, _flipY(outline.first.y, h));
    for (var i = 1; i < outline.length; i++) {
      g.lineTo(outline[i].x, _flipY(outline[i].y, h));
    }
    g.closePath();
    g.fillPath();
    g.restoreContext();
  }

  /// PDF blend mode for [mode]; null for normal (no graphic state needed).
  PdfBlendMode? _pdfBlendMode(DrawingBlendMode mode) => switch (mode) {
        DrawingBlendMode.normal => null,
        DrawingBlendMode.multiply => PdfBlendMode.multiply,
        DrawingBlendMode.screen => PdfBlendMode.screen,
        DrawingBlendMode.overlay => PdfBlendMode.overlay,
        DrawingBlendMode.darken => PdfBlendMode.darken,
        DrawingBlendMode.lighten => PdfBlendMode.lighten,
      };

  void _buildStrokePath(PdfGraphics g, List<DrawingPoint> points, double h) {
    g.moveTo(points.first.x, _flipY(points.first.y, h));
    if (points.length == 2) {
      g.lineTo(points.last.x, _flipY(points.last.y, h));
      return;
    }
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      g.curveTo(
        p1.x + (p2.x - p0.x) / 6,
        _flipY(p1.y + (p2.y - p0.y) / 6, h),
        p2.x - (p3.x - p1.x) / 6,
        _flipY(p2.y - (p3.y - p1.y) / 6, h),
        p2.x,
        _flipY(p2.y, h),
      );
    }
  }

  /// Draws [img]; false when its file is missing or cannot be decoded.
  Future<bool> _paintImage(
    PdfGraphics g,
    PdfDocument doc,
    ImageElement img,
    double w,
    double h,
    PdfPathResolver paths,
  ) async {
    final PdfImage pdfImg;
    try {
      final file = File(paths.resolve(img.filePath));
      if (!await file.exists()) return false;
      pdfImg = PdfImage.file(doc, bytes: await file.readAsBytes());
    } catch (_) {
      return false;
    }

    g.saveContext();
    if (img.rotation != 0.0) {
      final cx = img.x + img.width / 2;
      final fcy = _flipY(img.y + img.height / 2, h);
      final m = Matrix4.identity()
        ..translateByDouble(cx, fcy, 0, 1)
        ..rotateZ(-img.rotation)
        ..translateByDouble(-cx, -fcy, 0, 1);
      g.setTransform(m);
    }
    g.drawImage(
      pdfImg,
      img.x,
      _flipY(img.y + img.height, h),
      img.width,
      img.height,
    );
    g.restoreContext();
    return true;
  }

  double _flipY(double y, double h) => h - y;

  PdfColor _argbToPdfColor(int argb) => _vectorHelper.convertColor(argb);

  PenType _penTypeFromStyle(StrokeStyle style) {
    if (style.isEraser) return PenType.ballpointPen;
    if (style.pattern == StrokePattern.dashed) return PenType.dashedPen;
    if (style.nibShape == NibShape.rectangle) return PenType.highlighter;
    if (style.pressureSensitive) return PenType.brushPen;
    return PenType.ballpointPen;
  }
}
