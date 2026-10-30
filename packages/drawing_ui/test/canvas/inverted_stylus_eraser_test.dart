// Eraser end of a stylus (#508) erases while held, whatever tool is selected.
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ),
    );
    container =
        ProviderScope.containerOf(tester.element(find.byType(DrawingCanvas)));
  }

  Future<void> drawLine(WidgetTester tester, double y,
      {PointerDeviceKind kind = PointerDeviceKind.stylus}) async {
    final g = await tester.startGesture(Offset(100, y), kind: kind);
    for (var i = 0; i < 20; i++) {
      await g.moveBy(const Offset(10, 0));
    }
    await g.up();
    await tester.pump();
  }

  testWidgets('inverted stylus erases a stroke and the pen stays selected',
      (tester) async {
    await pump(tester);
    container.read(currentToolProvider.notifier).selectTool(ToolType.pencil);
    container.read(eraserSettingsProvider.notifier).setMode(EraserMode.stroke);
    await drawLine(tester, 200);
    expect(container.read(activeLayerStrokesProvider), hasLength(1));
    final undo = container.read(undoCountProvider);

    await drawLine(tester, 200, kind: PointerDeviceKind.invertedStylus);

    expect(container.read(activeLayerStrokesProvider), isEmpty);
    expect(container.read(undoCountProvider), undo + 1);
    expect(container.read(currentToolProvider), ToolType.pencil);
  });

  testWidgets('normal stylus with the pen still draws', (tester) async {
    await pump(tester);
    container.read(currentToolProvider.notifier).selectTool(ToolType.pencil);
    await drawLine(tester, 200);
    await drawLine(tester, 300);
    expect(container.read(activeLayerStrokesProvider), hasLength(2));
  });
}
