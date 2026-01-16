import 'package:flutter/material.dart';

/// Brightness (Value) slider
class BrightnessSlider extends StatelessWidget {
  const BrightnessSlider({
    super.key,
    required this.hsvColor,
    required this.onChanged,
  });

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Parlaklık',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              '${(hsvColor.value * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _GradientSlider(
          value: hsvColor.value,
          gradient: LinearGradient(
            colors: [
              Colors.black,
              HSVColor.fromAHSV(1.0, hsvColor.hue, hsvColor.saturation, 1.0)
                  .toColor(),
            ],
          ),
          onChanged: (value) {
            onChanged(hsvColor.withValue(value));
          },
        ),
      ],
    );
  }
}

/// Opacity (Alpha) slider
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Opaklık',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              '${(opacity * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            // Checkerboard background for transparency
            Container(
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.grey.shade200,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(
                  painter: _CheckerboardPainter(),
                  size: const Size(double.infinity, 28),
                ),
              ),
            ),
            // Gradient overlay
            _GradientSlider(
              value: opacity,
              gradient: LinearGradient(
                colors: [
                  color.withAlpha(0),
                  color.withAlpha(255),
                ],
              ),
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }
}

/// Generic gradient slider
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.gradient,
    required this.onChanged,
  });

  final double value;
  final Gradient gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 28,
          thumbShape: const _CustomThumbShape(),
          overlayShape: SliderComponentShape.noOverlay,
          trackShape: const _TransparentTrackShape(),
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
          thumbColor: Colors.white,
        ),
        child: Slider(
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Custom thumb shape for sliders
class _CustomThumbShape extends SliderComponentShape {
  const _CustomThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(20, 20);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Shadow
    canvas.drawCircle(
      center + const Offset(0, 1),
      10,
      Paint()
        ..color = Colors.black.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // White circle
    canvas.drawCircle(
      center,
      9,
      Paint()..color = Colors.white,
    );

    // Border
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// Transparent track shape
class _TransparentTrackShape extends RoundedRectSliderTrackShape {
  const _TransparentTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    // Don't paint anything - we have gradient background
  }
}

/// Checkerboard pattern painter for transparency preview
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 6.0;
    final paint1 = Paint()..color = Colors.grey.shade300;
    final paint2 = Paint()..color = Colors.white;

    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        final isEven = ((x / squareSize) + (y / squareSize)).toInt() % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
