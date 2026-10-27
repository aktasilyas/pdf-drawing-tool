import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/widgets/color_picker_logic.dart';

void main() {
  group('ColorPickerLogic', () {
    test('rgb returns 8-bit channels', () {
      final c = ColorPickerLogic.rgb(const Color(0xFF0A80FF));
      expect((c.r, c.g, c.b), (10, 128, 255));
    });

    test('hex is upper-case RRGGBB and ignores alpha', () {
      expect(ColorPickerLogic.hex(const Color(0x330a0bff)), '0A0BFF');
      expect(ColorPickerLogic.hex(const Color(0xFF000000)), '000000');
    });

    test('compose keeps opacity only when the slider is shown', () {
      final hsv = HSVColor.fromColor(const Color(0xFFFF0000));
      final withAlpha = ColorPickerLogic.compose(hsv, 0.5, showOpacity: true);
      final opaque = ColorPickerLogic.compose(hsv, 0.5, showOpacity: false);

      expect(withAlpha.a, closeTo(0.5, 0.001));
      expect(opaque.a, 1.0);
      expect(ColorPickerLogic.hex(withAlpha), 'FF0000');
    });

    test('opacityOf clamps to a visible minimum', () {
      expect(ColorPickerLogic.opacityOf(const Color(0x00FF0000)),
          ColorPickerLogic.minOpacity);
      expect(ColorPickerLogic.opacityOf(const Color(0xFFFF0000)), 1.0);
    });

    test('recentSlots keeps order and pads with null', () {
      const a = Color(0xFF111111);
      const b = Color(0xFF222222);
      expect(ColorPickerLogic.recentSlots([a, b]), [a, b, null, null, null]);
    });

    test('recentSlots truncates to the slot count', () {
      final many = List.generate(7, (i) => Color(0xFF000000 + i));
      expect(ColorPickerLogic.recentSlots(many), many.take(5).toList());
    });
  });
}
