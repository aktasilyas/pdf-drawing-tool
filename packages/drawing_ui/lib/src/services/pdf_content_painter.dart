import 'dart:io';
import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';
import 'package:vector_math/vector_math_64.dart';

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

  /// Paints background color and pattern onto the PDF page.
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
        break;
      case BackgroundType.grid:
        _drawGrid(g, w, h, pdfLineColor, bg.gridSpacing ?? 25.0, lineWidth);
      case BackgroundType.lined:
        _drawLines(g, w, h, pdfLineColor, bg.lineSpacing ?? 25.0, lineWidth);
      case BackgroundType.dotted:
        _drawDots(g, w, h, bg.gridSpacing ?? 20.0, pdfLineColor);
      case BackgroundType.template:
        if (bg.templatePattern != null) {
          final sp = (bg.templateSpacingMm ?? 8.0) * 3.78;
          _drawGrid(g, w, h, pdfLineColor, sp, lineWidth);
        }
    }
  }

  /// Paints all layer content as vector operations using [elementOrder].
  Future<void> paintLayerContent(
    PdfGraphics g, PdfDocument doc, Layer layer, double w, double h,
  ) async {
    final strokeMap = {for (final s in layer.strokes) s.id: s};
    final shapeMap = {for (final s in layer.shapes) s.id: s};
    final imageMap = {for (final i in layer.images) i.id: i};

    if (layer.elementOrder.isNotEmpty) {
      for (final id in layer.elementOrder) {
        if (strokeMap.containsKey(id)) {
          _paintStroke(g, strokeMap[id]!, w, h);
        } else if (shapeMap.containsKey(id)) {
          _shapeRenderer.paintShape(g, shapeMap[id]!, w, h);
        } else if (imageMap.containsKey(id)) {
          await _paintImage(g, doc, imageMap[id]!, w, h);
        }
      }
    } else {
      for (final stroke in layer.strokes) {
        _paintStroke(g, stroke, w, h);
      }
      for (final shape in layer.shapes) {
        _shapeRenderer.paintShape(g, shape, w, h);
      }
      for (final image in layer.images) {
        await _paintImage(g, doc, image, w, h);
      }
    }
  }

  void _paintStroke(PdfGraphics g, Stroke stroke, double w, double h) {
    if (stroke.points.length < 2) return;
    final style = stroke.style;

    if (style.pressureSensitive) {
      _paintPressureStroke(g, stroke, w, h);
      return;
    }

    final points = _vectorHelper.prepareStroke(stroke);
    if (points.length < 2) return;

    g.saveContext();

    final pdfColor = _vectorHelper.convertColor(style.color);
    final alpha = style.opacity * _vectorHelper.extractAlpha(style.color);
    if (alpha < 1.0) {
      g.setGraphicState(PdfGraphicState(strokeOpacity: alpha));
    }
    g.setStrokeColor(pdfColor);
    g.setLineWidth(style.thickness);

    final penType = _penTypeFromStyle(style);
    g.setLineCap(PdfLineCap.values[_vectorHelper.getRecommendedLineCap(penType)]);
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

  void _paintPressureStroke(PdfGraphics g, Stroke stroke, double w, double h) {
    final style = stroke.style;
    final points = stroke.points;
    if (points.length < 2) return;

    g.saveContext();
    final pdfColor = _vectorHelper.convertColor(style.color);
    final alpha = style.opacity * _vectorHelper.extractAlpha(style.color);
    if (alpha < 1.0) {
      g.setGraphicState(PdfGraphicState(fillOpacity: alpha));
    }
    g.setFillColor(pdfColor);

    final baseWidth = style.thickness;
    final sensitivity = style.pressureSensitivity;
    final leftEdge = <({double x, double y})>[];
    final rightEdge = <({double x, double y})>[];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final width = baseWidth * (1.0 - sensitivity + sensitivity * p.pressure);
      final halfW = width / 2;

      double dx, dy;
      if (i == 0) {
        dx = points[1].x - p.x;
        dy = points[1].y - p.y;
      } else if (i == points.length - 1) {
        dx = p.x - points[i - 1].x;
        dy = p.y - points[i - 1].y;
      } else {
        dx = points[i + 1].x - points[i - 1].x;
        dy = points[i + 1].y - points[i - 1].y;
      }

      final len = math.sqrt(dx * dx + dy * dy);
      if (len < 0.001) continue;
      final nx = -dy / len;
      final ny = dx / len;

      leftEdge.add((x: p.x + nx * halfW, y: _flipY(p.y + ny * halfW, h)));
      rightEdge.add((x: p.x - nx * halfW, y: _flipY(p.y - ny * halfW, h)));
    }

    if (leftEdge.length < 2) {
      g.restoreContext();
      return;
    }

    g.moveTo(leftEdge.first.x, leftEdge.first.y);
    for (int i = 1; i < leftEdge.length; i++) {
      g.lineTo(leftEdge[i].x, leftEdge[i].y);
    }
    for (int i = rightEdge.length - 1; i >= 0; i--) {
      g.lineTo(rightEdge[i].x, rightEdge[i].y);
    }
    g.closePath();
    g.fillPath();
    g.restoreContext();
  }

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

  Future<void> _paintImage(
    PdfGraphics g, PdfDocument doc, ImageElement img, double w, double h,
  ) async {
    try {
      final file = File(img.filePath);
      if (!await file.exists()) return;
      final bytes = await file.readAsBytes();
      final pdfImg = PdfImage.file(doc, bytes: bytes);

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
        pdfImg, img.x, _flipY(img.y + img.height, h), img.width, img.height,
      );
      g.restoreContext();
    } catch (_) {}
  }

  void _drawGrid(PdfGraphics g, double w, double h, PdfColor color,
      double spacing, double lineWidth) {
    g.setStrokeColor(color);
    g.setLineWidth(lineWidth);
    for (double x = spacing; x < w; x += spacing) {
      g.drawLine(x, 0, x, h);
    }
    for (double y = spacing; y < h; y += spacing) {
      g.drawLine(0, h - y, w, h - y);
    }
    g.strokePath();
  }

  void _drawLines(PdfGraphics g, double w, double h, PdfColor color,
      double spacing, double lineWidth) {
    g.setStrokeColor(color);
    g.setLineWidth(lineWidth);
    for (double y = spacing * 2; y < h; y += spacing) {
      g.drawLine(0, h - y, w, h - y);
    }
    g.strokePath();
  }

  void _drawDots(PdfGraphics g, double w, double h, double spacing,
      PdfColor color) {
    g.setFillColor(color);
    for (double x = spacing; x < w; x += spacing) {
      for (double y = spacing; y < h; y += spacing) {
        g.drawEllipse(x, h - y, 1.0, 1.0);
      }
    }
    g.fillPath();
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
