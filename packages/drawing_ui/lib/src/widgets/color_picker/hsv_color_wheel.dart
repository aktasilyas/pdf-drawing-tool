import 'dart:math' as math;
import 'package:flutter/material.dart';

/// HSV renk çemberi - dairesel renk seçici
class HSVColorWheel extends StatefulWidget {
  const HSVColorWheel({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.size = 200,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final double size;

  @override
  State<HSVColorWheel> createState() => _HSVColorWheelState();
}

class _HSVColorWheelState extends State<HSVColorWheel> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(HSVColorWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color != oldWidget.color) {
      _hsvColor = HSVColor.fromColor(widget.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size / 2;

    return GestureDetector(
      onPanStart: (details) => _updateColor(details.localPosition, radius),
      onPanUpdate: (details) => _updateColor(details.localPosition, radius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _ColorWheelPainter(
            hsvColor: _hsvColor,
            radius: radius,
          ),
        ),
      ),
    );
  }

  void _updateColor(Offset position, double radius) {
    final center = Offset(radius, radius);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Açıyı hesapla (hue)
    double hue = (math.atan2(dy, dx) * 180 / math.pi + 360) % 360;

    // Mesafeyi hesapla (saturation)
    double distance = math.sqrt(dx * dx + dy * dy);
    double saturation = (distance / radius).clamp(0.0, 1.0);

    setState(() {
      _hsvColor = HSVColor.fromAHSV(
        _hsvColor.alpha,
        hue,
        saturation,
        _hsvColor.value,
      );
    });

    widget.onColorChanged(_hsvColor.toColor());
  }
}

class _ColorWheelPainter extends CustomPainter {
  _ColorWheelPainter({
    required this.hsvColor,
    required this.radius,
  });

  final HSVColor hsvColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(radius, radius);

    // Renk çemberi çiz - daha akıcı render için sweep gradient
    for (double angle = 0; angle < 360; angle += 1) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            HSVColor.fromAHSV(1.0, angle, 1.0, hsvColor.value).toColor(),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final startAngle = (angle - 0.5) * math.pi / 180;
      final sweepAngle = 1.5 * math.pi / 180;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }

    // Seçili nokta göstergesi
    final hueRad = hsvColor.hue * math.pi / 180;
    final markerDistance = hsvColor.saturation * radius;
    final markerPos = Offset(
      center.dx + markerDistance * math.cos(hueRad),
      center.dy + markerDistance * math.sin(hueRad),
    );

    // Dış çember (beyaz gölge)
    canvas.drawCircle(
      markerPos,
      12,
      Paint()
        ..color = Colors.black.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Dış çember (beyaz)
    canvas.drawCircle(
      markerPos,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // İç çember (seçili renk)
    canvas.drawCircle(
      markerPos,
      7,
      Paint()..color = hsvColor.toColor(),
    );
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) {
    return hsvColor != oldDelegate.hsvColor;
  }
}
