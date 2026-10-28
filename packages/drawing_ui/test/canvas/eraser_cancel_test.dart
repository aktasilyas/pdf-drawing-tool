// A cancelled eraser gesture (palm rejection, system gesture) must leave the
// canvas exactly as before it: no hidden strokes, lasso outline or cursor (#425).
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
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

  void down(Offset p) =>
      state.handlePointerDown(PointerDownEvent(position: p, timeStamp: clock));

  void move(Offset p) {
    clock += const Duration(milliseconds: 8);
    state.handlePointerMove(PointerMoveEvent(position: p, timeStamp: clock));
  }

  void drawLine() {
    down(const Offset(40, 200));
    for (var x = 44.0; x <= 640; x += 4) {
      move(Offset(x, 200));
    }
    state.handlePointerUp(
      PointerUpEvent(position: const Offset(640, 200), timeStamp: clock),
    );
    expect(container.read(activeLayerStrokesProvider), hasLength(1));
  }

  void selectEraser(EraserMode mode, ToolType tool) {
    final settings = container.read(eraserSettingsProvider.notifier);
    settings.setMode(mode);
    settings.setSize(20);
    settings.setPressureSensitive(false);
    container.read(currentToolProvider.notifier).selectTool(tool);
  }

  for (final (mode, tool) in [
    (EraserMode.stroke, ToolType.strokeEraser),
    (EraserMode.pixel, ToolType.pixelEraser),
    (EraserMode.lasso, ToolType.lassoEraser),
  ]) {
    testWidgets('cancel in ${mode.name} mode resets every eraser provider',
        (tester) async {
      await pump(tester);
      drawLine();
      final before = container.read(documentProvider);
      final undoDepth = container.read(undoCountProvider);
      selectEraser(mode, tool);

      down(const Offset(200, 200));
      move(const Offset(260, 200));
      move(const Offset(320, 200));
      state.handlePointerCancel(
        const PointerCancelEvent(position: Offset(320, 200)),
      );

      expect(container.read(strokeEraserPreviewProvider), isEmpty);
      expect(container.read(pixelEraserPreviewProvider), isEmpty);
      expect(container.read(lassoEraserPointsProvider), isEmpty);
      expect(container.read(eraserCursorPositionProvider), isNull);
      expect(container.read(documentProvider), same(before));
      expect(container.read(activeLayerStrokesProvider), hasLength(1));
      expect(
        container.read(undoCountProvider),
        undoDepth,
      );
    });
  }
}
