import 'dart:math' as math;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/variable_width_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _StrokePainter extends CustomPainter {
  final VariableWidthStrokeRenderer renderer = VariableWidthStrokeRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    final style = StrokeStyle.pen(thickness: 10, color: 0xFF000000);
    final pressures = [0.15, 0.55, 1.0];
    for (var row = 0; row < pressures.length; row++) {
      final pts = [
        for (var i = 0; i < 60; i++)
          DrawingPoint(
            x: 20 + i * 4.6,
            y: 40 + row * 70 + 15 * math.sin(i / 60 * math.pi * 2),
            pressure: pressures[row],
            timestamp: i * 8,
          ),
      ];
      renderer.render(canvas, pts, style);
    }
    // Pressure ramp.
    renderer.render(
        canvas,
        [
          for (var i = 0; i < 60; i++)
            DrawingPoint(
                x: 20 + i * 4.6, y: 250, pressure: i / 59, timestamp: i * 8),
        ],
        style);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

void main() {
  testWidgets('outline renderer at three pressures and a ramp', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: 300,
              height: 280,
              child: CustomPaint(painter: _StrokePainter()),
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).first,
      matchesGoldenFile('goldens/variable_width_pressures.png'),
    );
  });
}
