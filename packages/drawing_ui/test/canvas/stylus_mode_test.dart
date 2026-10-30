// Stylus mode (#501): once a pen was seen, touches never reach the tools and
// a resting palm never blocks or cancels a pen stroke.
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DrawingCanvasState state;
  late ProviderContainer container;
  var clock = Duration.zero;

  Future<void> pump(WidgetTester tester) async {
    clock = Duration.zero;
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    state = tester.state<DrawingCanvasState>(finder);
    container = ProviderScope.containerOf(tester.element(finder));
  }

  void down(int id, Offset p, PointerDeviceKind kind) =>
      state.handlePointerDown(PointerDownEvent(
          pointer: id, kind: kind, position: p, timeStamp: clock));

  void move(int id, Offset p, PointerDeviceKind kind) {
    clock += const Duration(milliseconds: 8);
    state.handlePointerMove(PointerMoveEvent(
        pointer: id, kind: kind, position: p, timeStamp: clock));
  }

  void up(int id, Offset p, PointerDeviceKind kind) => state.handlePointerUp(
      PointerUpEvent(pointer: id, kind: kind, position: p, timeStamp: clock));

  void line(int id, PointerDeviceKind kind, double y) {
    down(id, Offset(40, y), kind);
    for (var x = 44.0; x <= 400; x += 4) {
      move(id, Offset(x, y), kind);
    }
    up(id, Offset(400, y), kind);
  }

  const touch = PointerDeviceKind.touch;
  const pen = PointerDeviceKind.stylus;

  testWidgets('finger-only: touch draws as before', (tester) async {
    await pump(tester);
    line(1, touch, 200);
    expect(container.read(activeLayerStrokesProvider), hasLength(1));
  });

  testWidgets('after a stylus stroke, touch with pen tool adds nothing',
      (tester) async {
    await pump(tester);
    line(1, pen, 100);
    expect(container.read(inputModeProvider).stylusDetected, isTrue);
    final undo = container.read(undoCountProvider);

    line(2, touch, 200);

    expect(container.read(activeLayerStrokesProvider), hasLength(1));
    expect(container.read(undoCountProvider), undo);
  });

  for (final tool in [ToolType.strokeEraser, ToolType.lassoEraser]) {
    testWidgets('touch with ${tool.name} changes nothing in stylus mode',
        (tester) async {
      await pump(tester);
      line(1, pen, 200);
      final before = container.read(documentProvider);
      final undo = container.read(undoCountProvider);
      container.read(currentToolProvider.notifier).selectTool(tool);

      line(2, touch, 200);

      expect(container.read(documentProvider), same(before));
      expect(container.read(undoCountProvider), undo);
    });
  }

  testWidgets('stylus stroke with a palm down is committed', (tester) async {
    await pump(tester);
    line(1, pen, 100); // enter stylus mode
    down(5, const Offset(300, 500), touch); // palm
    line(2, pen, 200);
    up(5, const Offset(300, 500), touch);

    expect(container.read(activeLayerStrokesProvider), hasLength(2));
  });

  testWidgets('draw with finger on lets touch draw again', (tester) async {
    await pump(tester);
    line(1, pen, 100);
    container.read(inputModeProvider.notifier).setDrawWithFinger(true);
    line(2, touch, 200);
    expect(container.read(activeLayerStrokesProvider), hasLength(2));
  });

  testWidgets('turning draw with finger off blocks touch without a stylus',
      (tester) async {
    await pump(tester);
    container.read(inputModeProvider.notifier).setDrawWithFinger(false);
    line(1, touch, 200);
    expect(container.read(activeLayerStrokesProvider), isEmpty);
  });
}
