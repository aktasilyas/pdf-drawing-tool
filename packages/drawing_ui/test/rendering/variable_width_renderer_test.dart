import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/rendering/variable_width_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tapered = StrokeDynamics(
    taperStart: 6,
    taperEnd: 12,
    streamline: 0.4,
    velocityThinning: 0.3,
  );

  group('VariableWidthStrokeRenderer.optionsFor', () {
    test('maps every field of the style', () {
      final o = VariableWidthStrokeRenderer.optionsFor(StrokeStyle(
        color: 0xFF000000,
        thickness: 4,
        pressureSensitive: true,
        pressureSensitivity: 0.6,
        dynamics: tapered,
      ));
      expect(o.size, 4);
      expect(o.thinning, 0.6);
      expect(o.velocityThinning, 0.3);
      expect(o.streamline, 0.4);
      expect(o.taperStart, 6);
      expect(o.taperEnd, 12);
    });

    test('thinning is 0 without pressure sensitivity', () {
      final o = VariableWidthStrokeRenderer.optionsFor(StrokeStyle(
        color: 0xFF000000,
        thickness: 4,
        pressureSensitive: false,
        pressureSensitivity: 0.9,
        dynamics: tapered,
      ));
      expect(o.thinning, 0);
    });

    test('legacy style keeps legacy defaults', () {
      final o = VariableWidthStrokeRenderer.optionsFor(StrokeStyle.brush());
      expect(o.taperStart, 0);
      expect(o.taperEnd, 0);
      expect(o.streamline, 0.5);
      expect(o.velocityThinning, 0.2);
    });
  });

  group('VariableWidthStrokeRenderer.usesOutline', () {
    final table = <String, (StrokeStyle, bool)>{
      'plain pen': (StrokeStyle(color: 0xFF000000, thickness: 4), false),
      'pressure': (
        StrokeStyle(color: 0xFF000000, thickness: 4, pressureSensitive: true),
        true
      ),
      'tapered, no pressure': (
        StrokeStyle(color: 0xFF000000, thickness: 4, dynamics: tapered),
        true
      ),
      'pencil texture': (
        StrokeStyle(
            color: 0xFF000000,
            thickness: 4,
            texture: StrokeTexture.pencil,
            pressureSensitive: true),
        false
      ),
      'pencil texture, tapered': (
        StrokeStyle(
            color: 0xFF000000,
            thickness: 4,
            texture: StrokeTexture.pencil,
            dynamics: tapered),
        false
      ),
    };
    table.forEach((name, row) {
      test(name, () {
        expect(VariableWidthStrokeRenderer.usesOutline(row.$1), row.$2);
      });
    });
  });
}
