import 'package:flutter/material.dart';
import 'package:drawing_ui/src/providers/drawing_providers.dart';

// ---------------------------------------------------------------------------
// Selection Preview
// ---------------------------------------------------------------------------

/// Visual preview of the selected lasso/selection mode.
///
/// - Freeform mode: dashed freeform lasso path enclosing sample objects
/// - Rectangle mode: dashed rectangle enclosing sample objects
class SelectionPreview extends StatelessWidget {
  const SelectionPreview({super.key, required this.mode});

  final LassoMode mode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 100,
      child: CustomPaint(
        size: const Size(double.infinity, 100),
        painter: _SelectionPreviewPainter(mode),
      ),
    );
  }
}

class _SelectionPreviewPainter extends CustomPainter {
  _SelectionPreviewPainter(this.mode);

  final LassoMode mode;

  static const _selectionBlue = Color(0xFF448AFF);
  static const _selectionFill = Color(0x10448AFF);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw sample objects first (behind selection)
    _drawSampleObjects(canvas, w, h);

    // Draw selection shape on top
    switch (mode) {
      case LassoMode.freeform:
        _drawFreeformSelection(canvas, w, h);
      case LassoMode.rectangle:
        _drawRectangleSelection(canvas, w, h);
    }
  }

  /// Draws small sample objects (lines/shapes) that appear "selected".
  void _drawSampleObjects(Canvas canvas, double w, double h) {
    final objectPaint = Paint()
      ..color = const Color(0xFF888888)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Small swoosh line
    final line1 = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..cubicTo(w * 0.32, h * 0.30, w * 0.42, h * 0.25, w * 0.50, h * 0.40);
    canvas.drawPath(line1, objectPaint);

    // Small circle
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.45),
      h * 0.12,
      objectPaint,
    );

    // Short zigzag
    final zigzag = Path()
      ..moveTo(w * 0.38, h * 0.65)
      ..lineTo(w * 0.44, h * 0.50)
      ..lineTo(w * 0.50, h * 0.68)
      ..lineTo(w * 0.56, h * 0.48);
    canvas.drawPath(zigzag, objectPaint);
  }

  /// Freeform mode: dashed organic lasso path.
  void _drawFreeformSelection(Canvas canvas, double w, double h) {
    final lassoPath = Path()
      ..moveTo(w * 0.18, h * 0.50)
      ..cubicTo(w * 0.14, h * 0.18, w * 0.38, h * 0.10, w * 0.55, h * 0.18)
      ..cubicTo(w * 0.72, h * 0.26, w * 0.82, h * 0.38, w * 0.76, h * 0.65)
      ..cubicTo(w * 0.70, h * 0.88, w * 0.32, h * 0.88, w * 0.18, h * 0.50)
      ..close();

    // Fill
    canvas.drawPath(
      lassoPath,
      Paint()
        ..color = _selectionFill
        ..style = PaintingStyle.fill,
    );

    // Dashed outline
    _drawDashedPath(canvas, lassoPath);
  }

  /// Rectangle mode: dashed rectangle.
  void _drawRectangleSelection(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTRB(w * 0.16, h * 0.15, w * 0.84, h * 0.85);
    final rectPath = Path()..addRect(rect);

    // Fill
    canvas.drawPath(
      rectPath,
      Paint()
        ..color = _selectionFill
        ..style = PaintingStyle.fill,
    );

    // Dashed outline
    _drawDashedPath(canvas, rectPath);
  }

  /// Draws a dashed outline along the given path.
  void _drawDashedPath(Canvas canvas, Path path) {
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    const dashLen = 6.0;
    const gapLen = 4.0;
    var d = 0.0;
    var draw = true;
    final dashPaint = Paint()
      ..color = _selectionBlue
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
  bool shouldRepaint(_SelectionPreviewPainter o) => mode != o.mode;
}
