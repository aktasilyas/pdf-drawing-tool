import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Orientation of the pen icon.
///
/// Controls the direction the pen tip points:
/// - [vertical]: Tip points UP (for popup/settings panels)
/// - [horizontal]: Tip points RIGHT (for PenBox, toward canvas)
enum PenOrientation {
  /// Tip points UP - used in popup/settings panels.
  vertical,

  /// Tip points RIGHT - used in PenBox (toward canvas).
  horizontal,
}

/// Base class for all pen icon painters.
///
/// Provides common functionality for rendering premium pen icons
/// with soft shadows, multi-stop gradients, and 3D depth effects.
///
/// All concrete painters should draw the pen with TIP POINTING UP
/// by default. The [orientation] parameter handles rotation:
/// - [PenOrientation.vertical]: No rotation (tip up)
/// - [PenOrientation.horizontal]: 90° clockwise rotation (tip right)
abstract class PenIconPainter extends CustomPainter {
  /// The color of the pen tip/ink.
  final Color penColor;

  /// Whether the pen is currently selected.
  final bool isSelected;

  /// The size of the icon (width and height).
  final double size;

  /// The orientation of the pen icon.
  final PenOrientation orientation;

  const PenIconPainter({
    required this.penColor,
    this.isSelected = false,
    this.size = 56.0,
    this.orientation = PenOrientation.vertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.save();

    // Apply orientation transform
    if (orientation == PenOrientation.horizontal) {
      // Rotate 90° clockwise - tip points right (toward canvas)
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(math.pi / 2);
      canvas.translate(-size.height / 2, -size.width / 2);
    }

    // 1. Drop shadow (soft blur)
    paintShadow(canvas, rect);

    // 2. Pen body
    paintBody(canvas, rect);

    // 3. Pen tip (at TOP of icon in default orientation)
    paintTip(canvas, rect);

    // 4. Details (clips, bands, eraser, etc. at BOTTOM)
    paintDetails(canvas, rect);

    // 5. Highlights
    paintHighlights(canvas, rect);

    // 6. Selection indicator
    if (isSelected) {
      paintSelection(canvas, rect);
    }

    canvas.restore();
  }

  /// Override: Paint soft drop shadow under the pen.
  ///
  /// Use [MaskFilter.blur] for soft shadows, NOT [canvas.drawShadow].
  void paintShadow(Canvas canvas, Rect rect) {
    // Default soft shadow with blur - can be overridden
    final shadowPath = buildBodyPath(rect);
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.save();
    canvas.translate(2.5, 3.0); // Shadow offset (light from top-left)
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  /// Override: Paint the main pen body.
  void paintBody(Canvas canvas, Rect rect);

  /// Override: Paint the pen tip/nib (at TOP in default orientation).
  void paintTip(Canvas canvas, Rect rect);

  /// Override: Paint additional details (at BOTTOM in default orientation).
  void paintDetails(Canvas canvas, Rect rect) {}

  /// Override: Paint highlights for 3D effect.
  void paintHighlights(Canvas canvas, Rect rect) {}

  /// Paint selection indicator.
  void paintSelection(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, paint);
  }

  /// Build the body path - used for shadow calculation.
  Path buildBodyPath(Rect rect);

  /// Helper: Create multi-stop gradient shader.
  ///
  /// Creates a 4-color gradient for realistic cylindrical appearance.
  /// Light source is from top-left.
  Shader createCylinderGradient(
    Rect rect,
    Color baseColor, {
    Axis axis = Axis.horizontal,
  }) {
    return LinearGradient(
      begin: axis == Axis.horizontal
          ? Alignment.centerLeft
          : Alignment.topCenter,
      end: axis == Axis.horizontal
          ? Alignment.centerRight
          : Alignment.bottomCenter,
      colors: [
        _adjustBrightness(baseColor, 0.3), // highlight edge
        _adjustBrightness(baseColor, 0.15), // light mid
        baseColor, // core
        _adjustBrightness(baseColor, -0.15), // shadow + reflected
      ],
      stops: const [0.0, 0.25, 0.6, 1.0],
    ).createShader(rect);
  }

  /// Helper: Create metal gradient with reflected light.
  Shader createMetalGradient(Rect rect, {Axis axis = Axis.horizontal}) {
    return LinearGradient(
      begin: axis == Axis.horizontal
          ? Alignment.centerLeft
          : Alignment.topCenter,
      end: axis == Axis.horizontal
          ? Alignment.centerRight
          : Alignment.bottomCenter,
      colors: const [
        Color(0xFFE0E0E0), // bright highlight
        Color(0xFFB8B8B8), // light metal
        Color(0xFF808080), // shadow
        Color(0xFFA0A0A0), // reflected light (critical!)
      ],
      stops: const [0.0, 0.3, 0.75, 1.0],
    ).createShader(rect);
  }

  /// Helper: Create highlight paint with blur.
  Paint createHighlightPaint({double opacity = 0.5, double width = 2.0}) {
    return Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
  }

  /// Helper: Adjust color brightness.
  Color _adjustBrightness(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant PenIconPainter oldDelegate) {
    return oldDelegate.penColor != penColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.size != size ||
        oldDelegate.orientation != orientation;
  }
}
