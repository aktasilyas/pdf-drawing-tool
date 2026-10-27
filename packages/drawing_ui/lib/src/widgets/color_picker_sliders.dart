/// Hue and opacity sliders for the colour picker.
import 'package:flutter/material.dart';

/// Hue Slider - Rainbow gradient
class HueSlider extends StatelessWidget {
  const HueSlider({
    super.key,
    required this.hue,
    required this.onChanged,
  });

  final double hue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Rainbow gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const HSVColor.fromAHSV(1.0, 0, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 60, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 120, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 180, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 240, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 300, 1.0, 1.0).toColor(),
                    const HSVColor.fromAHSV(1.0, 360, 1.0, 1.0).toColor(),
                  ],
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: hue,
                min: 0,
                max: 360,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opacity Slider - Checkerboard + color gradient
class OpacitySlider extends StatelessWidget {
  const OpacitySlider({
    super.key,
    required this.color,
    required this.opacity,
    required this.onChanged,
  });

  final Color color;
  final double opacity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF424242)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            // Checkerboard
            CustomPaint(
              size: const Size(double.infinity, 24),
              painter: const CheckerboardPainter(),
            ),
            // Color gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0),
                    color.withValues(alpha: 1),
                  ],
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 24,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: opacity,
                onChanged: onChanged,
                activeColor: Colors.transparent,
                inactiveColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkerboard pattern painter
class CheckerboardPainter extends CustomPainter {
  const CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 8.0;
    final paint = Paint();

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        paint.color =
            isEven ? const Color(0xFFCCCCCC) : const Color(0xFFFFFFFF);
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
