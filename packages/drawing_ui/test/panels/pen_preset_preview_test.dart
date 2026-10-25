import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/panels/pen_preset_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PenPresetPreviewPainter _painter(
  PenType type, {
  int color = 0xFF000000,
  double? thickness,
}) =>
    PenPresetPreviewPainter(
      penType: type,
      style: type.toStrokeStyle(color: color, thickness: thickness),
      size: const Size(56, 40),
    );

void main() {
  test('shouldRepaint: false for equal style, true after colour change', () {
    final a = _painter(PenType.fountainPen);
    expect(a.shouldRepaint(_painter(PenType.fountainPen)), isFalse);
    expect(
      a.shouldRepaint(_painter(PenType.fountainPen, color: 0xFFFF0000)),
      isTrue,
    );
  });

  test('curve has 17 samples, highlighter uses a 9 sample line', () {
    expect(_painter(PenType.brushPen).stroke.points, hasLength(17));
    final hl = _painter(PenType.highlighter).stroke.points;
    expect(hl, hasLength(9));
    expect(hl.map((p) => p.y).toSet(), hasLength(1));
  });

  test('thickness maps into the preview range and taper stays bounded', () {
    for (final type in [
      PenType.fountainPen,
      PenType.ballpointPen,
      PenType.brushPen,
      PenType.highlighter,
      PenType.pencil,
    ]) {
      final cfg = type.config;
      final lo = _painter(type, thickness: cfg.minThickness).stroke.style;
      final hi = _painter(type, thickness: cfg.maxThickness).stroke.style;
      expect(lo.thickness, lessThan(hi.thickness), reason: '$type');
      expect(hi.thickness, lessThanOrEqualTo(14), reason: '$type');
      final d = hi.dynamics;
      expect(d.taperStart + d.taperEnd, lessThan(40), reason: '$type');
    }
  });

  test('preview keeps blend mode and tapers of the preset', () {
    expect(
      _painter(PenType.highlighter).stroke.style.blendMode,
      DrawingBlendMode.multiply,
    );
    final f = _painter(PenType.fountainPen).stroke.style.dynamics;
    expect(f.taperStart, greaterThan(0));
    expect(f.taperEnd, greaterThan(0));
    expect(
      _painter(PenType.ballpointPen).stroke.style.dynamics.taperEnd,
      0,
    );
  });

  testWidgets('widget renders without error in a small box', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 56,
          height: 40,
          child: PenPresetPreview(
            penType: PenType.pencil,
            style: PenType.pencil.toStrokeStyle(color: 0xFF000000),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PenPresetPreview), findsOneWidget);
  });
}
