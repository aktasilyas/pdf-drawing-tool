import 'package:flutter/material.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';

// ---------------------------------------------------------------------------
// Eraser Preview
// ---------------------------------------------------------------------------

/// Visual preview of the selected eraser mode.
///
/// - Pixel eraser: a swoosh stroke with a gap where eraser passed
/// - Stroke eraser: a dimmed stroke with a cross-out mark
/// - Lasso eraser: a dashed lasso selection area
class EraserPreview extends StatelessWidget {
  const EraserPreview({super.key, required this.mode, required this.size});

  final EraserMode mode;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _EraserPreviewPainter(mode, size),
      ),
    );
  }
}

class _EraserPreviewPainter extends CustomPainter {
  _EraserPreviewPainter(this.mode, this.eraserSize);

  final EraserMode mode;
  final double eraserSize;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (mode) {
      case EraserMode.pixel:
        _drawPixelEraser(canvas, w, h);
      case EraserMode.stroke:
        _drawStrokeEraser(canvas, w, h);
      case EraserMode.lasso:
        _drawLassoEraser(canvas, w, h);
    }
  }

  /// Pixel eraser: a swoosh stroke with a gap where eraser passed.
  void _drawPixelEraser(Canvas canvas, double w, double h) {
    final strokePaint = Paint()
      ..color = const Color(0xFF888888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(w * 0.08, h * 0.70)
      ..cubicTo(w * 0.22, h * 0.15, w * 0.38, h * 0.10, w * 0.52, h * 0.35)
      ..cubicTo(w * 0.66, h * 0.60, w * 0.78, h * 0.80, w * 0.92, h * 0.30);

    final metrics = path.computeMetrics().first;
    final total = metrics.length;

    // Draw left part (before gap)
    canvas.drawPath(metrics.extractPath(0, total * 0.35), strokePaint);
    // Draw right part (after gap)
    canvas.drawPath(metrics.extractPath(total * 0.55, total), strokePaint);

    // Eraser circle at gap center
    final tangent = metrics.getTangentForOffset(total * 0.45);
    if (tangent != null) {
      final eraserR = (eraserSize * 0.2).clamp(6.0, 18.0);
      canvas.drawCircle(
        tangent.position,
        eraserR,
        Paint()
          ..color = const Color(0x30FF5252)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        tangent.position,
        eraserR,
        Paint()
          ..color = const Color(0xFFFF5252)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  /// Stroke eraser: full stroke with a cross-out mark.
  void _drawStrokeEraser(Canvas canvas, double w, double h) {
    final strokePaint = Paint()
      ..color = const Color(0x60888888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(w * 0.08, h * 0.70)
      ..cubicTo(w * 0.22, h * 0.15, w * 0.38, h * 0.10, w * 0.52, h * 0.35)
      ..cubicTo(w * 0.66, h * 0.60, w * 0.78, h * 0.80, w * 0.92, h * 0.30);

    canvas.drawPath(path, strokePaint);

    // Cross-out X over the stroke center
    final crossPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final cx = w * 0.50;
    final cy = h * 0.38;
    const r = 12.0;
    canvas.drawLine(
      Offset(cx - r, cy - r), Offset(cx + r, cy + r), crossPaint);
    canvas.drawLine(
      Offset(cx + r, cy - r), Offset(cx - r, cy + r), crossPaint);
  }

  /// Lasso eraser: dashed lasso selection area.
  void _drawLassoEraser(Canvas canvas, double w, double h) {
    final lassoPath = Path()
      ..moveTo(w * 0.20, h * 0.55)
      ..cubicTo(w * 0.15, h * 0.20, w * 0.40, h * 0.10, w * 0.55, h * 0.20)
      ..cubicTo(w * 0.70, h * 0.30, w * 0.85, h * 0.40, w * 0.75, h * 0.65)
      ..cubicTo(w * 0.65, h * 0.85, w * 0.35, h * 0.85, w * 0.20, h * 0.55)
      ..close();

    // Fill area
    canvas.drawPath(
      lassoPath,
      Paint()
        ..color = const Color(0x10448AFF)
        ..style = PaintingStyle.fill,
    );

    // Dashed outline
    final metrics = lassoPath.computeMetrics().first;
    final total = metrics.length;
    const dashLen = 6.0;
    const gapLen = 4.0;
    var d = 0.0;
    var draw = true;
    final dashPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    while (d < total) {
      final len = draw ? dashLen : gapLen;
      final end = (d + len).clamp(0.0, total);
      if (draw) {
        canvas.drawPath(metrics.extractPath(d, end), dashPaint);
      }
      d = end;
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(_EraserPreviewPainter o) =>
      mode != o.mode || eraserSize != o.eraserSize;
}
