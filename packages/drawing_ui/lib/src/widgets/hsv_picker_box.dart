/// HSV saturation/value box for the colour picker.
import 'package:flutter/material.dart';

/// HSV Picker Box - 160x160 gradient for color selection
class HSVPickerBox extends StatefulWidget {
  const HSVPickerBox({
    super.key,
    required this.hsvColor,
    required this.onColorChanged,
  });

  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onColorChanged;

  @override
  State<HSVPickerBox> createState() => _HSVPickerBoxState();
}

class _HSVPickerBoxState extends State<HSVPickerBox> {
  void _handlePositionUpdate(
      Offset globalPosition, BoxConstraints constraints) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(globalPosition);
    final saturation =
        (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
    final value =
        1.0 - (localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);

    widget.onColorChanged(
      widget.hsvColor.withSaturation(saturation).withValue(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) =>
                _handlePositionUpdate(details.globalPosition, constraints),
            onPanStart: (details) =>
                _handlePositionUpdate(details.globalPosition, constraints),
            onPanUpdate: (details) =>
                _handlePositionUpdate(details.globalPosition, constraints),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF424242)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CustomPaint(
                  painter: HSVBoxPainter(
                    hue: widget.hsvColor.hue,
                    saturation: widget.hsvColor.saturation,
                    value: widget.hsvColor.value,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Painter for HSV color box
class HSVBoxPainter extends CustomPainter {
  const HSVBoxPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  final double hue;
  final double saturation;
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    // Background with hue
    final hueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
    final huePaint = Paint()..color = hueColor;
    canvas.drawRect(Offset.zero & size, huePaint);

    // White gradient (left to right)
    final whiteGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.white, Colors.white.withValues(alpha: 0)],
    );
    final whiteShader = whiteGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = whiteShader);

    // Black gradient (top to bottom)
    final blackGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.black.withValues(alpha: 0), Colors.black],
    );
    final blackShader = blackGradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = blackShader);

    // Selector
    final selectorX = saturation * size.width;
    final selectorY = (1 - value) * size.height;
    final selectorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(selectorX, selectorY),
      8,
      selectorPaint,
    );
  }

  @override
  bool shouldRepaint(HSVBoxPainter oldDelegate) =>
      hue != oldDelegate.hue ||
      saturation != oldDelegate.saturation ||
      value != oldDelegate.value;
}
