import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:pdf/pdf.dart';

import 'vector_pdf_renderer.dart';

/// Renders [Shape] elements as PDF vector primitives.
///
/// Handles rectangle, ellipse, line, arrow, triangle, diamond shapes
/// with fill and stroke support. Coordinates are flipped from Flutter's
/// top-left origin to PDF's bottom-left origin.
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

    if (shape.isFilled) {
      final fillColor = _argbToPdfColor(shape.fillColor ?? style.color);
      g.setFillColor(fillColor);
      if (alpha < 1.0) {
        g.setGraphicState(PdfGraphicState(opacity: alpha));
      }
      _buildPath(g, shape.type, sx, sy, ex, ey, h);
      g.fillPath();

      g.setStrokeColor(pdfColor);
      g.setLineWidth(style.thickness);
      _buildPath(g, shape.type, sx, sy, ex, ey, h);
      g.strokePath();
    } else {
      if (alpha < 1.0) {
        g.setGraphicState(PdfGraphicState(strokeOpacity: alpha));
      }
      g.setStrokeColor(pdfColor);
      g.setLineWidth(style.thickness);
      g.setLineCap(PdfLineCap.round);
      g.setLineJoin(PdfLineJoin.round);
      _buildPath(g, shape.type, sx, sy, ex, ey, h);
      g.strokePath();
    }

    if (shape.type == ShapeType.arrow) {
      _paintArrowHead(g, sx, sy, ex, ey, style.thickness, pdfColor, alpha, h);
    }

    g.restoreContext();
  }

  void _buildPath(
    PdfGraphics g,
    ShapeType type,
    double sx,
    double sy,
    double ex,
    double ey,
    double h,
  ) {
    switch (type) {
      case ShapeType.line:
      case ShapeType.arrow:
        g.drawLine(sx, _flipY(sy, h), ex, _flipY(ey, h));
      case ShapeType.rectangle:
        final l = math.min(sx, ex);
        final t = math.min(sy, ey);
        final rw = (ex - sx).abs();
        final rh = (ey - sy).abs();
        g.drawRect(l, _flipY(t + rh, h), rw, rh);
      case ShapeType.ellipse:
        final cx = (sx + ex) / 2;
        final cy = (sy + ey) / 2;
        final rx = (ex - sx).abs() / 2;
        final ry = (ey - sy).abs() / 2;
        g.drawEllipse(cx, _flipY(cy, h), rx, ry);
      case ShapeType.triangle:
        final l = math.min(sx, ex);
        final r = math.max(sx, ex);
        final t = math.min(sy, ey);
        final b = math.max(sy, ey);
        g.moveTo((l + r) / 2, _flipY(t, h));
        g.lineTo(l, _flipY(b, h));
        g.lineTo(r, _flipY(b, h));
        g.closePath();
      case ShapeType.diamond:
        final cx = (sx + ex) / 2;
        final cy = (sy + ey) / 2;
        final hw = (ex - sx).abs() / 2;
        final hh = (ey - sy).abs() / 2;
        g.moveTo(cx, _flipY(cy - hh, h));
        g.lineTo(cx + hw, _flipY(cy, h));
        g.lineTo(cx, _flipY(cy + hh, h));
        g.lineTo(cx - hw, _flipY(cy, h));
        g.closePath();
      case ShapeType.star:
      case ShapeType.pentagon:
      case ShapeType.hexagon:
      case ShapeType.plus:
        final l = math.min(sx, ex);
        final t = math.min(sy, ey);
        final rw = (ex - sx).abs();
        final rh = (ey - sy).abs();
        g.drawRect(l, _flipY(t + rh, h), rw, rh);
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
