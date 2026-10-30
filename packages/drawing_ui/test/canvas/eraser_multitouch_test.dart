// Two-finger gestures with an eraser selected are navigation only (#487):
// a pinch or two-finger pan must never erase ink or add history, with any
// eraser mode, and single-finger erasing must keep working.
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

  Future<void> pump(WidgetTester tester, {core.CanvasMode? mode}) async {
    clock = Duration.zero;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: DrawingCanvas(canvasMode: mode)),
        ),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    state = tester.state<DrawingCanvasState>(finder);
    container = ProviderScope.containerOf(tester.element(finder));
  }

  void down(int pointer, Offset p) => state.handlePointerDown(
        PointerDownEvent(pointer: pointer, position: p, timeStamp: clock),
      );

  void move(int pointer, Offset p) {
    clock += const Duration(milliseconds: 8);
    state.handlePointerMove(
      PointerMoveEvent(pointer: pointer, position: p, timeStamp: clock),
    );
  }

  void up(int pointer, Offset p) => state.handlePointerUp(
        PointerUpEvent(pointer: pointer, position: p, timeStamp: clock),
      );

  void scaleStart(Offset focal) => state.handleScaleStart(
        ScaleStartDetails(
          focalPoint: focal,
          localFocalPoint: focal,
          pointerCount: 2,
        ),
      );

  void scaleEnd() => state.handleScaleEnd(ScaleEndDetails(pointerCount: 0));

  /// One-finger gesture along [points].
  void gesture(List<Offset> points) {
    down(1, points.first);
    for (final p in points.skip(1)) {
      move(1, p);
    }
    up(1, points.last);
  }

  List<core.Stroke> strokes() => container.read(activeLayerStrokesProvider);
  int undoCount() => container.read(historyManagerProvider).undoCount;

  /// Horizontal pen stroke from x=40 to x=440 at y=200 (screen).
  core.Stroke drawLine() {
    gesture([for (var x = 40.0; x <= 440; x += 4) Offset(x, 200)]);
    expect(strokes(), hasLength(1));
    return strokes().single;
  }

  void selectEraser(ToolType tool) {
    final settings = container.read(eraserSettingsProvider.notifier);
    settings.setSize(20);
    settings.setPressureSensitive(false);
    container.read(currentToolProvider.notifier).selectTool(tool);
  }

  /// A vertical sweep that crosses the line at x, from y=150 to y=250.
  List<Offset> sweep(double x) => [
        for (var y = 150.0; y <= 250; y += 10) Offset(x, y),
      ];

  /// A lasso loop around the line's middle part.
  const lasso = [
    Offset(150, 150),
    Offset(300, 150),
    Offset(300, 250),
    Offset(150, 250),
    Offset(150, 150),
  ];

  /// Path finger 1 follows: a lasso loop or a sweep across the line.
  List<Offset> pathFor(ToolType tool, double x) =>
      tool == ToolType.lassoEraser ? lasso : sweep(x);

  const erasers = [
    ToolType.pixelEraser,
    ToolType.strokeEraser,
    ToolType.lassoEraser,
  ];

  for (final tool in erasers) {
    group('${tool.name}:', () {
      testWidgets('a pinch changes no content and adds no history',
          (tester) async {
        await pump(tester);
        final line = drawLine();
        selectEraser(tool);
        final before = undoCount();

        final a = pathFor(tool, 200);
        down(1, a.first);
        move(1, a[1]); // first finger moves before the second lands
        down(2, const Offset(400, 400));
        scaleStart(const Offset(300, 300));
        for (var i = 2; i < a.length; i++) {
          move(1, a[i]);
          move(2, Offset(400.0 + i * 5, 400.0 + i * 5));
        }
        up(2, const Offset(450, 450));
        up(1, a.last);
        scaleEnd();

        expect(strokes(), [line]);
        expect(undoCount(), before);
        expect(container.read(pixelEraserPreviewProvider), isEmpty);
        expect(container.read(strokeEraserPreviewProvider), isEmpty);
        expect(container.read(lassoEraserPointsProvider), isEmpty);
      });

      testWidgets('a two-finger pan across the ink changes nothing',
          (tester) async {
        await pump(tester);
        final line = drawLine();
        selectEraser(tool);
        final before = undoCount();

        final a = pathFor(tool, 200);
        final b = pathFor(tool, 260);
        down(1, a.first);
        down(2, b.first);
        scaleStart(const Offset(230, 150));
        for (var i = 1; i < a.length; i++) {
          move(1, a[i]);
          move(2, b[i]);
        }
        up(1, a.last);
        up(2, b.last);
        scaleEnd();

        expect(strokes(), [line]);
        expect(undoCount(), before);
      });

      testWidgets('lifting one finger and moving the other does not erase',
          (tester) async {
        await pump(tester);
        final line = drawLine();
        selectEraser(tool);
        final before = undoCount();

        down(1, const Offset(100, 100));
        down(2, const Offset(140, 100));
        scaleStart(const Offset(120, 100));
        up(2, const Offset(140, 100));
        final a = pathFor(tool, 200);
        for (final p in a) {
          move(1, p);
        }
        up(1, a.last);
        scaleEnd();

        expect(strokes(), [line]);
        expect(undoCount(), before);
      });

      testWidgets('a pinch without a scale callback still never erases',
          (tester) async {
        // The scale recognizer may not have claimed the gesture yet: the
        // second finger alone ends the eraser session.
        await pump(tester);
        final line = drawLine();
        selectEraser(tool);
        final before = undoCount();

        final a = pathFor(tool, 200);
        down(1, a.first);
        down(2, const Offset(400, 400));
        for (final p in a.skip(1)) {
          move(1, p);
        }
        up(2, const Offset(400, 400));
        up(1, a.last);

        expect(strokes(), [line]);
        expect(undoCount(), before);
      });

      testWidgets('a pinch starting outside the page does not erase',
          (tester) async {
        // Page-bounded drawing with the page at the screen origin (an
        // infinite mode skips page centering), so x < 0 is off the page.
        await pump(
          tester,
          mode: const core.CanvasMode(isInfinite: true),
        );
        expect(
          container.read(canvasTransformProvider).screenToCanvas(
                const Offset(-30, 200),
              ),
          const Offset(-30, 200),
        );
        final line = drawLine();
        selectEraser(tool);
        final before = undoCount();

        // First finger lands left of the page, second on the ink.
        final a = pathFor(tool, 200);
        down(1, const Offset(-30, 200));
        down(2, a.first);
        for (final p in a.skip(1)) {
          move(2, p);
        }
        up(1, const Offset(-30, 200));
        up(2, a.last);

        expect(strokes(), [line]);
        expect(undoCount(), before);
      });

      testWidgets('single-finger erasing still works in one undo step',
          (tester) async {
        await pump(tester);
        final line = drawLine();
        selectEraser(tool);
        final before = undoCount();

        gesture(pathFor(tool, 200));

        expect(strokes(), isNot([line]));
        expect(undoCount(), before + 1);
        container.read(historyManagerProvider.notifier).undo();
        expect(strokes(), [line]);

        // A pinch earlier does not block the next single-finger erase.
        down(1, const Offset(100, 100));
        down(2, const Offset(140, 100));
        scaleStart(const Offset(120, 100));
        up(1, const Offset(100, 100));
        up(2, const Offset(140, 100));
        scaleEnd();
        gesture(pathFor(tool, 200));
        expect(strokes(), isNot([line]));
      });
    });
  }
}
