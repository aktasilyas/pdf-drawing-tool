import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';

Widget _wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))));

void main() {
  group('parseHexColor', () {
    test('accepts #RRGGBB and RRGGBB', () {
      expect(parseHexColor('#FF0000'), const Color(0xFFFF0000));
      expect(parseHexColor('00ff00'), const Color(0xFF00FF00));
    });
    test('rejects invalid text', () {
      expect(parseHexColor(''), isNull);
      expect(parseHexColor('#12345'), isNull);
      expect(parseHexColor('GGGGGG'), isNull);
      expect(parseHexColor('##12345'), isNull);
    });
  });

  group('HexOpacityInput', () {
    Future<List<Color>> pump(WidgetTester t) async {
      final changes = <Color>[];
      await t.pumpWidget(_wrap(HexOpacityInput(
        color: const Color(0xFF112233),
        opacity: 1,
        showOpacity: true,
        onColorChanged: changes.add,
        onSave: () {},
      )));
      return changes;
    }

    testWidgets('submitting #RRGGBB reports the colour', (t) async {
      final changes = await pump(t);
      await t.enterText(find.byType(TextField).first, '#FF0000');
      await t.testTextInput.receiveAction(TextInputAction.done);
      expect(changes, [const Color(0xFFFF0000)]);
    });

    testWidgets('submitting RRGGBB reports the colour', (t) async {
      final changes = await pump(t);
      await t.enterText(find.byType(TextField).first, '00FF00');
      await t.testTextInput.receiveAction(TextInputAction.done);
      expect(changes, [const Color(0xFF00FF00)]);
    });

    testWidgets('invalid hex does not change the colour', (t) async {
      final changes = await pump(t);
      await t.enterText(find.byType(TextField).first, '12G');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.enterText(find.byType(TextField).first, '12345');
      await t.testTextInput.receiveAction(TextInputAction.done);
      expect(changes, isEmpty);
    });

    testWidgets('opacity above 100 clamps to fully opaque', (t) async {
      final changes = await pump(t);
      await t.enterText(find.byType(TextField).last, '250');
      await t.testTextInput.receiveAction(TextInputAction.done);
      expect(changes.single.a, 1.0);
    });

    testWidgets('opacity 50 reports half alpha', (t) async {
      final changes = await pump(t);
      await t.enterText(find.byType(TextField).last, '50');
      await t.testTextInput.receiveAction(TextInputAction.done);
      expect(changes.single.a, closeTo(0.5, 0.01));
    });
  });

  testWidgets('HSVPickerBox reports saturation/value from the drag', (t) async {
    final changes = <HSVColor>[];
    await t.pumpWidget(_wrap(HSVPickerBox(
      hsvColor: const HSVColor.fromAHSV(1, 120, 0, 0),
      onColorChanged: changes.add,
    )));
    final rect = t.getRect(find.byType(HSVPickerBox));
    await t.tapAt(rect.topRight - const Offset(1, -1));
    expect(changes.last.saturation, greaterThan(0.9));
    expect(changes.last.value, greaterThan(0.9));
    expect(changes.last.hue, 120);
    await t.tapAt(rect.bottomLeft + const Offset(1, -1));
    expect(changes.last.saturation, lessThan(0.1));
    expect(changes.last.value, lessThan(0.1));
  });

  testWidgets('HueSlider dragging reports a hue', (t) async {
    double? hue;
    await t.pumpWidget(_wrap(HueSlider(hue: 0, onChanged: (v) => hue = v)));
    await t.tapAt(t.getCenter(find.byType(HueSlider)));
    expect(hue, closeTo(180, 20));
  });

  testWidgets('OpacitySlider tap reports alpha', (t) async {
    double? v;
    await t.pumpWidget(_wrap(OpacitySlider(
      color: Colors.red,
      opacity: 0,
      onChanged: (x) => v = x,
    )));
    await t.tapAt(t.getCenter(find.byType(OpacitySlider)));
    expect(v, closeTo(0.5, 0.1));
  });

  testWidgets('sliders and text fields have >= 48dp touch targets', (t) async {
    await t.pumpWidget(_wrap(Column(children: [
      HueSlider(hue: 0, onChanged: (_) {}),
      OpacitySlider(color: Colors.red, opacity: 1, onChanged: (_) {}),
      HexOpacityInput(
        color: Colors.red,
        opacity: 1,
        showOpacity: true,
        onColorChanged: (_) {},
        onSave: () {},
      ),
    ])));
    expect(t.getSize(find.byType(HueSlider)).height, greaterThanOrEqualTo(48));
    expect(
        t.getSize(find.byType(OpacitySlider)).height, greaterThanOrEqualTo(48));
    for (final f in find.byType(TextField).evaluate()) {
      final box = find.ancestor(
          of: find.byWidget(f.widget), matching: find.byType(Container));
      expect(t.getSize(box.first).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('RecentColorsRow tap selects and targets are >= 48dp', (t) async {
    Color? picked;
    await t.pumpWidget(_wrap(RecentColorsRow(
      colors: const [Color(0xFFFF0000), Color(0xFF0000FF)],
      selectedColor: const Color(0xFFFF0000),
      onColorSelected: (c) => picked = c,
    )));
    final target = find.byType(GestureDetector).last;
    expect(t.getSize(target).width, greaterThanOrEqualTo(48));
    expect(t.getSize(target).height, greaterThanOrEqualTo(48));
    await t.tap(target);
    expect(picked, const Color(0xFF0000FF));
  });

  test('painters repaint only when fields change', () {
    const a = HSVBoxPainter(hue: 1, saturation: .5, value: .5);
    expect(
        a.shouldRepaint(const HSVBoxPainter(hue: 1, saturation: .5, value: .5)),
        isFalse);
    expect(
        a.shouldRepaint(const HSVBoxPainter(hue: 2, saturation: .5, value: .5)),
        isTrue);
    expect(
        const CheckerboardPainter().shouldRepaint(const CheckerboardPainter()),
        isFalse);
  });
}
