// Pixel eraser through the DrawingCanvas handlers (#125): a fast eraser swipe
// must cut one clean gap out of a stroke, at any zoom, and undo must restore
// the stroke exactly.
import 'package:drawing_core/drawing_core.dart' as core;
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

  Offset toCanvas(Offset screenPoint) =>
      container.read(canvasTransformProvider).screenToCanvas(screenPoint);

  /// Sends down/move/up through the canvas handlers along screen points.
  void gesture(List<Offset> points) {
    state.handlePointerDown(
      PointerDownEvent(position: points.first, timeStamp: clock),
    );
    for (final p in points.skip(1)) {
      clock += const Duration(milliseconds: 8);
      state.handlePointerMove(PointerMoveEvent(position: p, timeStamp: clock));
    }
    state.handlePointerUp(
      PointerUpEvent(position: points.last, timeStamp: clock),
    );
  }

  List<core.Stroke> strokes() => container.read(activeLayerStrokesProvider);

  /// Draws a horizontal pen stroke from x=40 to x=640 at y=200 (screen).
  core.Stroke drawLine() {
    gesture([for (var x = 40.0; x <= 640; x += 4) Offset(x, 200)]);
    expect(strokes(), hasLength(1));
    return strokes().single;
  }

  void selectPixelEraser() {
    final settings = container.read(eraserSettingsProvider.notifier);
    settings.setMode(EraserMode.pixel);
    settings.setSize(20);
    settings.setPressureSensitive(false);
    final tool = container.read(currentToolProvider.notifier);
    tool.selectTool(ToolType.pixelEraser);
  }

  for (final zoom in [1.0, 1.7, 4.0]) {
    testWidgets('fast swipe along a stroke cuts one gap at zoom $zoom',
        (tester) async {
      await pump(tester);
      container.read(canvasTransformProvider.notifier).setZoom(zoom);
      final line = drawLine();
      selectPixelEraser();

      // Samples 60 screen px apart: six times the eraser radius.
      gesture(const [
        Offset(200, 200),
        Offset(260, 200),
        Offset(320, 200),
        Offset(380, 200),
      ]);

      final pieces = strokes();
      expect(pieces, hasLength(2), reason: 'one gap, no dashes');

      // Eraser size is in screen px; reach adds half the ink width.
      final reach = 20 / zoom / 2 + line.style.thickness / 2;
      final startX = toCanvas(const Offset(200, 200)).dx;
      final endX = toCanvas(const Offset(380, 200)).dx;
      // Pieces keep stroke order: split_0 is left of the gap.
      final left = pieces[0];
      final right = pieces[1];
      expect(left.id, '${line.id}_split_0');
      expect(right.id, '${line.id}_split_1');
      expect(left.points.last.x, closeTo(startX - reach, 0.1));
      expect(right.points.first.x, closeTo(endX + reach, 0.1));
      expect(left.points.first, line.points.first);
      expect(right.points.last, line.points.last);
    });
  }

  testWidgets('undo restores the erased stroke exactly', (tester) async {
    await pump(tester);
    final line = drawLine();
    selectPixelEraser();

    gesture(const [Offset(300, 150), Offset(300, 250)]);
    expect(strokes(), hasLength(2));

    container.read(historyManagerProvider.notifier).undo();

    expect(strokes(), [line]);
  });

  testWidgets('a swipe that misses every stroke changes nothing',
      (tester) async {
    await pump(tester);
    final line = drawLine();
    selectPixelEraser();

    gesture(const [Offset(100, 400), Offset(500, 400)]);

    expect(strokes(), [line]);
    expect(container.read(pixelEraserPreviewProvider), isEmpty);
  });
}
