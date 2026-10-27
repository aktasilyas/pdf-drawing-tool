import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/providers/recent_colors_provider.dart';

const _blue = Color(0xFF2196F3);
const _red = Color(0xFFE53935);
const _green = Color(0xFF43A047);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Color selected = _blue,
  ValueChanged<Color>? onSelected,
  VoidCallback? onClose,
  List<Color> recent = const [],
  Size size = const Size(1024, 768),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  for (final c in recent.reversed) {
    container.read(recentColorsProvider.notifier).addColor(c);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: CompactColorPicker(
              selectedColor: selected,
              onColorSelected: onSelected ?? (_) {},
              onClose: onClose,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('renders both tabs', (tester) async {
    await _pump(tester);
    expect(find.text('Kartelalar'), findsOneWidget);
    expect(find.text('Spektrum'), findsOneWidget);
  });

  testWidgets('info bar reflects the selected colour', (tester) async {
    await _pump(tester, selected: const Color(0xFF0A80FF));
    expect(find.text('#0A80FF'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('255'), findsOneWidget);
  });

  testWidgets('Done reports the picked swatch and records it as recent',
      (tester) async {
    Color? reported;
    final container =
        await _pump(tester, onSelected: (c) => reported = c);

    final cell = find.descendant(
      of: find.byType(ColorSwatchGrid),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(cell.at(3));
    await tester.pump();
    final hex = (tester.widget<Text>(find.textContaining('#')).data)!;
    expect(hex, isNot('#2196F3'));

    await tester.tap(find.text('Bitti'));
    await tester.pump();

    expect(reported, isNotNull);
    expect('#${_hexOf(reported!)}', hex);
    expect(container.read(recentColorsProvider).first, reported);
  });

  testWidgets('recent row shows newest first and applies on tap',
      (tester) async {
    Color? reported;
    await _pump(tester,
        recent: const [_red, _green], onSelected: (c) => reported = c);

    BoxDecoration deco(int i) {
      final box = find.descendant(
        of: find.byKey(ValueKey('recentColorSlot$i')),
        matching: find.byType(Container),
      );
      return tester.widget<Container>(box.first).decoration! as BoxDecoration;
    }

    expect(deco(0).color, _red);
    expect(deco(1).color, _green);
    expect(find.byKey(const ValueKey('recentColorSlot2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recentColorSlot1')));
    await tester.pump();
    expect(find.text('#43A047'), findsOneWidget);

    await tester.tap(find.text('Bitti'));
    expect(_hexOf(reported!), '43A047');
  });

  testWidgets('Cancel calls onClose without reporting a colour',
      (tester) async {
    var closed = 0;
    Color? reported;
    await _pump(tester,
        onClose: () => closed++, onSelected: (c) => reported = c);

    await tester.tap(find.text('İptal et'));
    expect(closed, 1);
    expect(reported, isNull);
  });

  testWidgets('tappable controls are at least 48dp', (tester) async {
    await _pump(tester, recent: const [_red]);

    void expectTarget(Finder f) {
      final size = tester.getSize(f);
      expect(size.width, greaterThanOrEqualTo(48), reason: '$f width');
      expect(size.height, greaterThanOrEqualTo(48), reason: '$f height');
    }

    expectTarget(find.byKey(const ValueKey('recentColorSlot0')));
    for (final label in ['İptal et', 'Bitti']) {
      expectTarget(find.ancestor(
        of: find.text(label),
        matching: find.byType(GestureDetector),
      ).first);
    }
    for (final label in ['Kartelalar', 'Spektrum']) {
      final tab = find.ancestor(
        of: find.text(label),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(tab.first).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('no overflow on a 780x360 landscape phone', (tester) async {
    await _pump(tester,
        size: const Size(780, 360), recent: const [_red, _green]);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Spektrum'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

String _hexOf(Color c) => [c.r, c.g, c.b]
    .map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0'))
    .join()
    .toUpperCase();
