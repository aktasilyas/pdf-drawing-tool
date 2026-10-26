import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';

import 'vector_pdf_renderer.dart';

/// Renders [Shape] elements as PDF vector primitives.
///
/// Line, arrow, rectangle and ellipse use PDF primitives; every other
/// [ShapeType] is built from [ShapeGeometry], the same vertices the screen
/// painter draws. Coordinates are flipped from Flutter's top-left origin to
/// PDF's bottom-left origin.
class PdfVectorShapeRenderer {
  final VectorPDFRenderer _vectorHelper;

  PdfVectorShapeRenderer(this._vectorHelper);

  void paintShape(PdfGraphics g, Shape shape, double w, double h) {
    final style = shape.style;
    final pdfColor = _vectorHelper.convertColor(style.color);
    final alpha = style.opacity * _vectorHelper.extractAlpha(style.color);

    final sx = shape.startPoint.x;
    final sy = shape.startPoint.y;
    final ex = shape.endPoint.x;
    final ey = shape.endPoint.y;

    g.saveContext();
    g.setLineCap(PdfLineCap.round);
    g.setLineJoin(PdfLineJoin.round);

    // Open paths (line, arrow, plus bars) have nothing to fill. Colours and
    // graphic state must be set before a path is started.
    if (shape.isFilled && _hasClosedPath(shape.type)) {
      final fillColor = _argbToPdfColor(shape.fillColor ?? style.color);
      g.setFillColor(fillColor);
      if (alpha < 1.0) {
        g.setGraphicState(PdfGraphicState(opacity: alpha));
      }
      _buildPath(g, shape, h, closedOnly: true);
      g.fillPath();
    } else if (alpha < 1.0) {
      g.setGraphicState(PdfGraphicState(strokeOpacity: alpha));
    }

    g.setStrokeColor(pdfColor);
    g.setLineWidth(style.thickness);
    _buildPath(g, shape, h);
    g.strokePath();

    if (shape.type == ShapeType.arrow) {
      _paintArrowHead(g, sx, sy, ex, ey, style.thickness, pdfColor, alpha, h);
    }

    g.restoreContext();
  }

  static bool _hasClosedPath(ShapeType type) =>
      type != ShapeType.line &&
      type != ShapeType.arrow &&
      type != ShapeType.plus;

  /// Adds [shape]'s outline to the current path. With [closedOnly], open
  /// sub-paths are skipped.
  void _buildPath(
    PdfGraphics g,
    Shape shape,
    double h, {
    bool closedOnly = false,
  }) {
    final sx = shape.startPoint.x;
    final sy = shape.startPoint.y;
    final ex = shape.endPoint.x;
    final ey = shape.endPoint.y;
    switch (shape.type) {
      case ShapeType.line:
      case ShapeType.arrow:
        if (closedOnly) return;
        g.drawLine(sx, _flipY(sy, h), ex, _flipY(ey, h));
      case ShapeType.rectangle:
        g.drawRect(
          shape.left,
          _flipY(shape.bottom, h),
          shape.width,
          shape.height,
        );
      case ShapeType.ellipse:
        g.drawEllipse(
          shape.centerX,
          _flipY(shape.centerY, h),
          shape.width / 2,
          shape.height / 2,
        );
      case ShapeType.triangle:
      case ShapeType.diamond:
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.plus:
        for (final p in ShapeGeometry.polygonPaths(shape)!) {
          if (p.points.length < 2 || (closedOnly && !p.closed)) continue;
          g.moveTo(p.points.first.x, _flipY(p.points.first.y, h));
          for (var i = 1; i < p.points.length; i++) {
            g.lineTo(p.points[i].x, _flipY(p.points[i].y, h));
          }
          if (p.closed) g.closePath();
        }
    }
  }

  void _paintArrowHead(
    PdfGraphics g,
    double sx,
    double sy,
    double ex,
    double ey,
    double thickness,
    PdfColor color,
    double alpha,
    double h,
  ) {
    final dx = ex - sx;
    final dy = ey - sy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 10) return;

    final ux = dx / len;
    final uy = dy / len;
    final sz = thickness * 4;
    final bx = ex - ux * sz;
    final by = ey - uy * sz;
    final px = -uy * sz * 0.5;
    final py = ux * sz * 0.5;

    g.setFillColor(color);
    if (alpha < 1.0) {
      g.setGraphicState(PdfGraphicState(fillOpacity: alpha));
    }
    g.moveTo(ex, _flipY(ey, h));
    g.lineTo(bx + px, _flipY(by + py, h));
    g.lineTo(bx - px, _flipY(by - py, h));
    g.closePath();
    g.fillPath();
  }

  double _flipY(double y, double h) => h - y;

  PdfColor _argbToPdfColor(int argb) => _vectorHelper.convertColor(argb);
}
