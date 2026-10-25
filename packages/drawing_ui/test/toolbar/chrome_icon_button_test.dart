import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _palette = ChromePalette.light;
final _idleIcon = ElyanotesIcons.iconForTool(ToolType.ballpointPen);
final _selectedIcon =
    ElyanotesIcons.iconForTool(ToolType.ballpointPen, active: true);

Widget _host(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: const [_palette]),
    home: Scaffold(body: Center(child: child)),
  );
}

ChromeIconButton _button({
  VoidCallback? onPressed,
  bool selected = false,
  bool enabled = true,
  Color? inkDotColor,
}) {
  return ChromeIconButton(
    icon: _idleIcon,
    selectedIcon: _selectedIcon,
    tooltip: 'Pen',
    onPressed: onPressed ?? () {},
    selected: selected,
    enabled: enabled,
    inkDotColor: inkDotColor,
  );
}

BoxDecoration _visual(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(ChromeIconButton),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return box.decoration! as BoxDecoration;
}

PhosphorIcon _icon(WidgetTester tester) {
  return tester.widget<PhosphorIcon>(find.byType(PhosphorIcon));
}

void main() {
  testWidgets('hit area is 48dp around a 40dp visual', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_button(onPressed: () => taps++)));

    final hit = tester.getRect(find.byType(ChromeIconButton));
    expect(hit.size, const Size.square(ChromeSizes.minTouchTarget));
    final visual = tester.getSize(find.byType(AnimatedContainer));
    expect(visual, const Size.square(ChromeIconButton.visualSize));

    // A tap in the corner, outside the 40dp visual, still counts.
    await tester.tapAt(hit.topLeft + const Offset(1, 1));
    expect(taps, 1);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('idle uses textMuted, the idle icon, no fill', (tester) async {
    await tester.pumpWidget(_host(_button()));

    expect(_icon(tester).icon, _idleIcon);
    expect(_icon(tester).color, _palette.textMuted);
    expect(_visual(tester).color!.a, 0);
  });

  testWidgets('selected uses accentContainer fill and the Fill icon',
      (tester) async {
    await tester.pumpWidget(_host(_button(selected: true)));

    expect(_icon(tester).icon, _selectedIcon);
    expect(_icon(tester).color, _palette.accent);
    expect(_visual(tester).color, _palette.accentContainer);
  });

  testWidgets('disabled uses textDisabled and ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(_button(enabled: false, selected: true, onPressed: () => taps++)),
    );

    expect(_icon(tester).color, _palette.textDisabled);
    expect(_icon(tester).icon, _idleIcon);
    await tester.tap(find.byType(ChromeIconButton));
    expect(taps, 0);
  });

  testWidgets('pressed overlays textPrimary at 8%', (tester) async {
    await tester.pumpWidget(_host(_button()));

    final center = tester.getCenter(find.byType(ChromeIconButton));
    final gesture = await tester.startGesture(center);
    // Tap-down fires after the press timeout while the arena is open.
    await tester.pump(const Duration(milliseconds: 150));
    final expected = Color.alphaBlend(
      _palette.textPrimary.withValues(alpha: ChromeIconButton.pressedAlpha),
      _palette.accentContainer.withValues(alpha: 0),
    );
    expect(_visual(tester).color, expected);

    await gesture.up();
    await tester.pump();
    expect(_visual(tester).color!.a, 0);
  });

  testWidgets('keyboard focus shows an accent ring and Enter activates',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_button(onPressed: () => taps++)));
    expect(_visual(tester).border, isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final border = _visual(tester).border! as Border;
    expect(border.top.color, _palette.accent);
    expect(border.top.width, ChromeIconButton.focusRingWidth);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('pen group shows an ink dot ringed in surface', (tester) async {
    const ink = Color(0xFFD32F2F);
    await tester.pumpWidget(_host(_button(inkDotColor: ink)));

    final dot = find.byWidgetPredicate((w) {
      if (w is! Container || w.decoration is! BoxDecoration) return false;
      final d = w.decoration! as BoxDecoration;
      return d.shape == BoxShape.circle && d.color == ink;
    });
    expect(dot, findsOneWidget);
    final d = tester.widget<Container>(dot).decoration! as BoxDecoration;
    expect((d.border! as Border).top.color, _palette.surface);
  });

  testWidgets('exposes button, selected and label semantics', (tester) async {
    await tester.pumpWidget(_host(_button(selected: true)));

    expect(
      tester.getSemantics(find.byType(ChromeIconButton)),
      containsSemantics(
        label: 'Pen',
        isButton: true,
        isSelected: true,
        isEnabled: true,
      ),
    );
  });

  group('ToolButton', () {
    testWidgets('renders a 48dp chrome button with the key on the visual',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _host(
          ToolButton(
            toolType: ToolType.ballpointPen,
            isSelected: true,
            onPressed: () {},
            buttonKey: key,
          ),
        ),
      );

      final hit = tester.getSize(find.byType(ToolButton));
      expect(hit, const Size.square(ChromeSizes.minTouchTarget));
      expect(
        tester.getSize(find.byKey(key)),
        const Size.square(ChromeIconButton.visualSize),
      );
      expect(_icon(tester).icon, _selectedIcon);
      expect(_visual(tester).color, _palette.accentContainer);
    });

    testWidgets('compact keeps the 48dp hit area', (tester) async {
      await tester.pumpWidget(
        _host(
          ToolButton(
            toolType: ToolType.pencil,
            isSelected: false,
            onPressed: () {},
            compact: true,
          ),
        ),
      );

      final hit = tester.getSize(find.byType(ToolButton));
      expect(hit, const Size.square(ChromeSizes.minTouchTarget));
    });
  });
}
