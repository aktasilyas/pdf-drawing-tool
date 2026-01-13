import 'package:flutter/material.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// A visual preview of a pen nib.
///
/// Renders the nib shape (circle, ellipse, or rectangle) with the appropriate
/// color and size for display in pen preset slots and settings panels.
class NibPreview extends StatelessWidget {
  const NibPreview({
    super.key,
    required this.nibShape,
    required this.color,
    required this.thickness,
    this.size = 24.0,
    this.maxThickness = 20.0,
    this.angle = 0.0,
  });

  /// The shape of the nib to display.
  final NibShapeType nibShape;

  /// The color of the nib.
  final Color color;

  /// The thickness/size of the nib stroke.
  final double thickness;

  /// The size of the preview container.
  final double size;

  /// Maximum thickness for scaling purposes.
  final double maxThickness;

  /// Rotation angle for ellipse nibs (in radians).
  final double angle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NibPreviewPainter(
          nibShape: nibShape,
          color: color,
          thickness: thickness,
          maxThickness: maxThickness,
          angle: angle,
        ),
      ),
    );
  }
}

class _NibPreviewPainter extends CustomPainter {
  _NibPreviewPainter({
    required this.nibShape,
    required this.color,
    required this.thickness,
    required this.maxThickness,
    required this.angle,
  });

  final NibShapeType nibShape;
  final Color color;
  final double thickness;
  final double maxThickness;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Scale thickness to fit preview
    final scaleFactor = (size.width * 0.4) / maxThickness;
    final scaledThickness = (thickness * scaleFactor).clamp(2.0, size.width * 0.8);

    switch (nibShape) {
      case NibShapeType.circle:
        canvas.drawCircle(center, scaledThickness / 2, paint);
        break;

      case NibShapeType.ellipse:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: scaledThickness,
            height: scaledThickness * 0.4, // Elongated
          ),
          paint,
        );
        canvas.restore();
        break;

      case NibShapeType.rectangle:
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: scaledThickness,
              height: scaledThickness * 0.3,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
        break;
    }
  }

  @override
  bool shouldRepaint(_NibPreviewPainter oldDelegate) {
    return nibShape != oldDelegate.nibShape ||
        color != oldDelegate.color ||
        thickness != oldDelegate.thickness ||
        angle != oldDelegate.angle;
  }
}

/// A larger nib preview for settings panels.
class LargeNibPreview extends StatelessWidget {
  const LargeNibPreview({
    super.key,
    required this.nibShape,
    required this.color,
    required this.thickness,
    this.angle = 0.0,
  });

  final NibShapeType nibShape;
  final Color color;
  final double thickness;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: NibPreview(
          nibShape: nibShape,
          color: color,
          thickness: thickness,
          size: 60,
          maxThickness: 50,
          angle: angle,
        ),
      ),
    );
  }
}
