/// Hue and opacity sliders for the colour picker.
import 'package:flutter/material.dart';

const double _kTrackHeight = 24;
const double _kTouchHeight = 48;

/// Draws [background] as a 24dp track and overlays an invisible slider whose
/// touch area is 48dp tall.
class _SliderTrack extends StatelessWidget {
  const _SliderTrack({
    required this.background,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final Widget background;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kTouchHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: _kTrackHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF424242)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: background,
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: _kTrackHeight,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackShape: const RectangularSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              max: max,
              onChanged: onChanged,
              activeColor: Colors.transparent,
              inactiveColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

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
    return _SliderTrack(
      value: hue,
      max: 360,
      onChanged: onChanged,
      background: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              for (var h = 0; h <= 360; h += 60)
                HSVColor.fromAHSV(1.0, h.toDouble(), 1.0, 1.0).toColor(),
            ],
          ),
        ),
        child: const SizedBox.expand(),
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
    return _SliderTrack(
      value: opacity,
      max: 1,
      onChanged: onChanged,
      background: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: CheckerboardPainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0),
                  color.withValues(alpha: 1),
                ],
              ),
            ),
          ),
        ],
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
