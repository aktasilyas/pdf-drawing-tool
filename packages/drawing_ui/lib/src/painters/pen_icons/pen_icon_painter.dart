import 'package:flutter/material.dart';

/// Base class for all pen icon painters.
///
/// Provides common functionality for rendering premium pen icons
/// with soft shadows, gradients, and 3D depth effects.
abstract class PenIconPainter extends CustomPainter {
  final Color penColor;
  final bool isSelected;
  final double size;

  const PenIconPainter({
    required this.penColor,
    this.isSelected = false,
    this.size = 56.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Drop shadow
    paintShadow(canvas, rect);

    // 2. Pen body
    paintBody(canvas, rect);

    // 3. Pen tip
    paintTip(canvas, rect);

    // 4. Details (clips, bands, etc.)
    paintDetails(canvas, rect);

    // 5. Highlights
    paintHighlights(canvas, rect);

    // 6. Selection indicator
    if (isSelected) {
      paintSelection(canvas, rect);
    }
  }

  /// Override: Paint drop shadow under the pen.
  void paintShadow(Canvas canvas, Rect rect) {
    // Default soft shadow - can be overridden
    final shadowPath = buildBodyPath(rect);
    canvas.drawShadow(
      shadowPath.shift(const Offset(2, 2)),
      Colors.black.withAlpha(38), // 0.15 opacity
      4.0,
      false,
    );
  }

  /// Override: Paint the main pen body.
  void paintBody(Canvas canvas, Rect rect);

  /// Override: Paint the pen tip/nib.
  void paintTip(Canvas canvas, Rect rect);

  /// Override: Paint additional details.
  void paintDetails(Canvas canvas, Rect rect) {}

  /// Override: Paint highlights for 3D effect.
  void paintHighlights(Canvas canvas, Rect rect) {}

  /// Paint selection indicator.
  void paintSelection(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.blue.withAlpha(51) // 0.2 opacity
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);
  }

  /// Build the body path - used for shadow and body.
  Path buildBodyPath(Rect rect);

  /// Helper: Create gradient paint.
  Paint gradientPaint(Rect rect, Color light, Color dark,
      {Axis axis = Axis.vertical}) {
    return Paint()
      ..shader = LinearGradient(
        begin: axis == Axis.vertical
            ? Alignment.topCenter
            : Alignment.centerLeft,
        end: axis == Axis.vertical
            ? Alignment.bottomCenter
            : Alignment.centerRight,
        colors: [light, dark],
      ).createShader(rect);
  }

  /// Helper: Create highlight paint.
  Paint highlightPaint({double opacity = 0.4}) {
    return Paint()
      ..color = Colors.white.withAlpha((opacity * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
  }

  @override
  bool shouldRepaint(covariant PenIconPainter oldDelegate) {
    return oldDelegate.penColor != penColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.size != size;
  }
}
