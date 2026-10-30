import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';
import 'package:drawing_ui/src/widgets/color_picker_recent_row.dart';
import 'package:drawing_ui/src/widgets/color_swatch_target.dart';
import 'package:drawing_ui/src/widgets/recent_colors_row.dart';

const _strings = DrawingStringsTr();
const _red = Color(0xFFE53935);
const _blue = Color(0xFF1E88E5);

String _label(Color c) => _strings.toolbar.color(colorHex(c));

Future<void> _pump(WidgetTester t, Widget child,
    {ProviderContainer? container}) async {
  final app = MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 320, child: child)),
    ),
  );
  final scope = container ?? ProviderContainer();
  if (container == null) addTearDown(scope.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: app,
    ),
  );
}

Future<void> _expectGuidelines(WidgetTester t) async {
  await expectLater(t, meetsGuideline(androidTapTargetGuideline));
  await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
}

void main() {
  group('ColorSwatchTarget', () {
    testWidgets('48dp target, button + selected + colour label', (t) async {
      final handle = t.ensureSemantics();
      var taps = 0;
      await _pump(
        t,
        Center(
          child: ColorSwatchTarget(
            color: _red,
            isSelected: true,
            onTap: () => taps++,
            child: const SizedBox.square(dimension: 20),
          ),
        ),
      );

      final hit = t.getRect(find.byType(ColorSwatchTarget));
      expect(hit.size, const Size.square(ChromeSizes.minTouchTarget));
      await t.tapAt(hit.topLeft + const Offset(2, 2));
      expect(taps, 1);
      expect(
        t.getSemantics(find.byType(ColorSwatchTarget)),
        containsSemantics(
          label: _label(_red),
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      // TalkBack's double-tap goes through the semantics tap action.
      t.semantics.tap(find.semantics.byLabel(_label(_red)));
      expect(taps, 2);
      await _expectGuidelines(t);
      handle.dispose();
    });
  });

  group('UnifiedColorPicker', () {
    testWidgets('swatches and "more" meet tap-target and label guidelines',
        (t) async {
      final handle = t.ensureSemantics();
      Color? picked;
      await _pump(
        t,
        UnifiedColorPicker(
          selectedColor: _red,
          quickColors: const [_red, _blue],
          onColorSelected: (c) => picked = c,
          chipSize: 28,
          spacing: 8,
        ),
      );

      await _expectGuidelines(t);
      expect(
        t.getSemantics(find.bySemanticsLabel(_label(_red))),
        containsSemantics(isButton: true, isSelected: true),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel(_label(_blue))),
        containsSemantics(isButton: true, isSelected: false),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel(_strings.selection.more)),
        containsSemantics(isButton: true, hasTapAction: true),
      );

      await t.tap(find.bySemanticsLabel(_label(_blue)));
      // Single tap resolves after the double-tap window.
      await t.pump(const Duration(milliseconds: 500));
      expect(picked, _blue);
      handle.dispose();
    });
  });

  group('RecentColorsRow', () {
    testWidgets('reports selection and meets guidelines', (t) async {
      final handle = t.ensureSemantics();
      await _pump(
        t,
        RecentColorsRow(
          colors: const [_red, _blue],
          selectedColor: _blue,
          onColorSelected: (_) {},
        ),
      );

      await _expectGuidelines(t);
      expect(
        t.getSemantics(find.bySemanticsLabel(_label(_blue))),
        containsSemantics(isButton: true, isSelected: true),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel(_label(_red))),
        containsSemantics(isButton: true, isSelected: false),
      );
      handle.dispose();
    });
  });

  group('ColorPickerRecentRow', () {
    testWidgets('filled slots report the current colour as selected',
        (t) async {
      final handle = t.ensureSemantics();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(recentColorsProvider.notifier).addColor(_red);
      container.read(recentColorsProvider.notifier).addColor(_blue);
      Color? picked;
      await _pump(
        t,
        ColorPickerRecentRow(
          selectedColor: _red,
          onColorSelected: (c) => picked = c,
          outlineColor: Colors.grey,
          iconColor: Colors.grey,
        ),
        container: container,
      );

      await _expectGuidelines(t);
      expect(
        t.getSemantics(find.bySemanticsLabel(_label(_red))),
        containsSemantics(isButton: true, isSelected: true, hasTapAction: true),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel(_label(_blue))),
        containsSemantics(isButton: true, isSelected: false),
      );
      // Newest first: slot 0 is blue.
      await t.tap(find.byKey(const ValueKey('recentColorSlot0')));
      expect(picked, _blue);
      handle.dispose();
    });
  });

  group('CompactColorPicker', () {
    testWidgets('swatch grid reports the selected colour', (t) async {
      final handle = t.ensureSemantics();
      t.view.physicalSize = const Size(1024, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      // Top-left grid cell (gray, lightness 0.94).
      final gray = HSLColor.fromAHSL(1, 0, 0, 0.94).toColor();
      await _pump(
        t,
        CompactColorPicker(selectedColor: gray, onColorSelected: (_) {}),
      );

      expect(
        t.getSemantics(find.bySemanticsLabel(_label(gray)).first),
        containsSemantics(isButton: true, isSelected: true),
      );
      handle.dispose();
    });
  });
}
