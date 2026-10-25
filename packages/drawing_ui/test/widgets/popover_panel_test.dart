import 'dart:ui' as ui;

import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_ui/src/theme/drawing_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden/helpers/chrome_theme.dart';

const _panelKey = Key('popover-content');

class _Harness extends StatefulWidget {
  const _Harness({
    required this.controller,
    required this.anchorTop,
    required this.brightness,
    required this.onDismiss,
    required this.onCanvasDown,
  });

  final PopoverController controller;
  final double anchorTop;
  final Brightness brightness;
  final VoidCallback onDismiss;
  final VoidCallback onCanvasDown;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final GlobalKey anchorKey = GlobalKey();

  void open() {
    widget.controller.show(
      context: anchorKey.currentContext!,
      anchorKey: anchorKey,
      onDismiss: widget.onDismiss,
      child: const SizedBox(key: _panelKey, width: 200, height: 120),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: chromeTheme(widget.brightness),
      home: Scaffold(
        body: Stack(children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => widget.onCanvasDown(),
            ),
          ),
          Positioned(
            top: widget.anchorTop,
            left: 100,
            child: SizedBox(key: anchorKey, width: 48, height: 48),
          ),
        ]),
      ),
    );
  }
}

Future<_HarnessState> _pump(
  WidgetTester tester, {
  required PopoverController controller,
  double anchorTop = 20,
  Brightness brightness = Brightness.light,
  VoidCallback? onDismiss,
  VoidCallback? onCanvasDown,
}) async {
  tester.view.physicalSize = const Size(800, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final harness = _Harness(
    controller: controller,
    anchorTop: anchorTop,
    brightness: brightness,
    onDismiss: onDismiss ?? () {},
    onCanvasDown: onCanvasDown ?? () {},
  );
  await tester.pumpWidget(harness);
  final state = tester.state<_HarnessState>(find.byType(_Harness));
  state.open();
  await tester.pump();
  return state;
}

BoxDecoration _panelDecoration(WidgetTester tester) {
  final containers = find.ancestor(
    of: find.byKey(_panelKey),
    matching: find.byType(Container),
  );
  final container = tester.widget<Container>(containers.first);
  return container.decoration! as BoxDecoration;
}

void main() {
  late PopoverController controller;

  setUp(() => controller = PopoverController());
  tearDown(() => controller.dispose());

  for (final brightness in Brightness.values) {
    final dark = brightness == Brightness.dark;
    final palette = dark ? ChromePalette.dark : ChromePalette.light;

    testWidgets('chrome palette ${brightness.name}', (tester) async {
      await _pump(tester, controller: controller, brightness: brightness);
      await tester.pumpAndSettle();

      final decoration = _panelDecoration(tester);
      expect(decoration.color, palette.surfaceElevated);
      final border = decoration.border! as Border;
      expect(border.top.color, palette.border);
      expect(border.top.width, 1);
      expect(decoration.borderRadius, BorderRadius.circular(ChromeRadius.xl));
      expect(decoration.boxShadow, DrawingShadows.panel(brightness));
    });
  }

  testWidgets('opens below the anchor with an sm gap', (tester) async {
    await _pump(tester, controller: controller, anchorTop: 20);
    await tester.pumpAndSettle();

    final panelTop = tester.getTopLeft(find.byKey(_panelKey)).dy;
    // Anchor bottom 68 + gap 8 + 1dp border.
    expect(panelTop, 68 + ChromeSpacing.sm + 1);
  });

  testWidgets('flips above when less than 360 is free below', (tester) async {
    // Anchor bottom at 448: 800 - 448 - 8 - 12 = 332 below, 412 above.
    await _pump(tester, controller: controller, anchorTop: 400);
    await tester.pumpAndSettle();

    final panelBottom = tester.getBottomLeft(find.byKey(_panelKey)).dy;
    expect(panelBottom, 400 - ChromeSpacing.sm - 1);
  });

  testWidgets('enter animation takes 200ms', (tester) async {
    await _pump(tester, controller: controller);
    await tester.pump(const Duration(milliseconds: 100));
    final fades = find.ancestor(
      of: find.byKey(_panelKey),
      matching: find.byType(FadeTransition),
    );
    final fade = tester.widget<FadeTransition>(fades.first);
    expect(fade.opacity.value, inInclusiveRange(0.05, 0.95));

    await tester.pump(const Duration(milliseconds: 100));
    expect(fade.opacity.value, 1);
  });

  testWidgets('hide plays a 100ms exit first', (tester) async {
    await _pump(tester, controller: controller);
    await tester.pumpAndSettle();

    controller.hide();
    expect(controller.isShowing, isFalse);
    await tester.pump();
    expect(find.byKey(_panelKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(_panelKey), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(find.byKey(_panelKey), findsNothing);
  });

  testWidgets('outside pen-down closes without drawing', (tester) async {
    var dismissed = 0;
    var canvasDowns = 0;
    await _pump(
      tester,
      controller: controller,
      onDismiss: () => dismissed++,
      onCanvasDown: () => canvasDowns++,
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      const Offset(600, 600),
      kind: ui.PointerDeviceKind.stylus,
    );
    await tester.pump();
    expect(dismissed, 1);
    expect(canvasDowns, 0);
    await gesture.moveBy(const Offset(40, 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(canvasDowns, 0);
    expect(find.byKey(_panelKey), findsNothing);

    // Once closed, the next pen-down reaches the canvas.
    await tester.tapAt(const Offset(600, 600));
    expect(canvasDowns, 1);
  });

  testWidgets('tap inside the panel does not dismiss', (tester) async {
    var dismissed = 0;
    await _pump(tester, controller: controller, onDismiss: () => dismissed++);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_panelKey));
    await tester.pumpAndSettle();
    expect(dismissed, 0);
    expect(find.byKey(_panelKey), findsOneWidget);
  });

  testWidgets('Escape closes the popover', (tester) async {
    var dismissed = 0;
    await _pump(tester, controller: controller, onDismiss: () => dismissed++);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    expect(find.byKey(_panelKey), findsNothing);
  });

  testWidgets('show while open replaces the panel at once', (tester) async {
    final state = await _pump(tester, controller: controller);
    await tester.pumpAndSettle();

    state.open();
    await tester.pump();
    expect(find.byKey(_panelKey), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(_panelKey), findsOneWidget);
    expect(controller.isShowing, isTrue);
  });

  testWidgets('dispose removes the panel immediately', (tester) async {
    await _pump(tester, controller: controller);
    await tester.pumpAndSettle();

    controller.dispose();
    await tester.pump();
    expect(find.byKey(_panelKey), findsNothing);
  });
}
