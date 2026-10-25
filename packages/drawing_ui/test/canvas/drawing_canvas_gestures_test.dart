// Characterization tests for the pointer/tool/scale handlers of DrawingCanvas
// (see docs/plans/54-split-gesture-handlers.md). They call the public handlers
// on DrawingCanvasState directly, which avoids the hit-test problem behind the
// skipped pointer tests in drawing_canvas_test.dart, and assert on provider
// and document state.
import 'package:drawing_ui/src/canvas/drawing_canvas.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DrawingCanvasState state;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DrawingCanvas())),
      ),
    );
    final finder = find.byType(DrawingCanvas);
    state = tester.state<DrawingCanvasState>(finder);
    container = ProviderScope.containerOf(tester.element(finder));
  }

  int strokeCount() => container.read(activeLayerStrokesProvider).length;

  /// Draws a pen stroke along the given screen points.
  void drawStroke(List<Offset> points) {
    state.handlePointerDown(PointerDownEvent(position: points.first));
    for (final p in points.skip(1)) {
      state.handlePointerMove(PointerMoveEvent(position: p));
    }
    state.handlePointerUp(PointerUpEvent(position: points.last));
  }

  group('DrawingCanvas gesture handlers (characterization)', () {
    testWidgets('pen: down/move/up commits one stroke and resets lastPoint',
        (tester) async {
      await pump(tester);
      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      expect(state.drawingController.isDrawing, isTrue);
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(120, 110)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(140, 120)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(160, 130)),
      );
      expect(state.drawingController.pointCount, greaterThan(1));
      state.handlePointerUp(const PointerUpEvent(position: Offset(160, 130)));

      expect(strokeCount(), 1);
      expect(state.drawingController.isDrawing, isFalse);
      expect(state.lastPoint, isNull);
    });

    testWidgets('cancel mid-stroke commits nothing', (tester) async {
      await pump(tester);
      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(130, 130)),
      );
      state.handlePointerCancel(
        const PointerCancelEvent(position: Offset(130, 130)),
      );

      expect(strokeCount(), 0);
      expect(state.drawingController.isDrawing, isFalse);
      expect(state.lastPoint, isNull);
    });

    testWidgets('stroke eraser removes a stroke it crosses', (tester) async {
      await pump(tester);
      drawStroke(const [
        Offset(100, 100),
        Offset(140, 100),
        Offset(180, 100),
        Offset(220, 100),
      ]);
      expect(strokeCount(), 1);

      container
          .read(eraserSettingsProvider.notifier)
          .setMode(EraserMode.stroke);
      container
          .read(currentToolProvider.notifier)
          .selectTool(ToolType.strokeEraser);

      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(160, 100)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(220, 100)),
      );
      state.handlePointerUp(const PointerUpEvent(position: Offset(220, 100)));

      expect(strokeCount(), 0);
    });

    testWidgets('shape tool (rectangle): down/move/up adds one shape',
        (tester) async {
      await pump(tester);
      container
          .read(shapesSettingsProvider.notifier)
          .setSelectedShape(ShapeType.rectangle);
      container.read(currentToolProvider.notifier).selectTool(ToolType.shapes);

      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      expect(state.isDrawingShape, isTrue);
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(200, 180)),
      );
      state.handlePointerUp(const PointerUpEvent(position: Offset(200, 180)));

      expect(container.read(activeLayerShapesProvider).length, 1);
      expect(state.isDrawingShape, isFalse);
    });

    testWidgets('highlighter straight-line mode commits a 2-point stroke',
        (tester) async {
      await pump(tester);
      container
          .read(highlighterSettingsProvider.notifier)
          .setStraightLineMode(true);
      container
          .read(currentToolProvider.notifier)
          .selectTool(ToolType.highlighter);

      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      expect(state.isStraightLineDrawing, isTrue);
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(150, 120)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(220, 140)),
      );
      state.handlePointerUp(const PointerUpEvent(position: Offset(220, 140)));

      final strokes = container.read(activeLayerStrokesProvider);
      expect(strokes.length, 1);
      expect(strokes.first.points.length, 2);
      expect(state.isStraightLineDrawing, isFalse);
    });

    testWidgets('selection tool: lasso around a stroke selects it',
        (tester) async {
      await pump(tester);
      drawStroke(const [
        Offset(100, 100),
        Offset(130, 120),
        Offset(160, 140),
        Offset(190, 160),
      ]);
      expect(strokeCount(), 1);

      container
          .read(currentToolProvider.notifier)
          .selectTool(ToolType.selection);
      expect(container.read(selectionProvider), isNull);

      state.handlePointerDown(
        const PointerDownEvent(position: Offset(50, 50)),
      );
      expect(state.isSelecting, isTrue);
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(250, 50)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(250, 250)),
      );
      state.handlePointerMove(
        const PointerMoveEvent(position: Offset(50, 250)),
      );
      state.handlePointerUp(const PointerUpEvent(position: Offset(50, 250)));

      final selection = container.read(selectionProvider);
      expect(selection, isNotNull);
      expect(selection!.selectedStrokeIds.length, 1);
      expect(state.isSelecting, isFalse);
    });

    testWidgets('text tool tap starts editing; finishTextEditing ends it',
        (tester) async {
      await pump(tester);
      container.read(currentToolProvider.notifier).selectTool(ToolType.text);

      state.handlePointerDown(
        const PointerDownEvent(position: Offset(100, 100)),
      );
      expect(container.read(textToolProvider).isEditing, isTrue);

      state.finishTextEditing();
      expect(container.read(textToolProvider).isEditing, isFalse);
    });

    testWidgets('two-finger scale changes the canvas zoom', (tester) async {
      await pump(tester);
      final before = container.read(canvasTransformProvider).zoom;

      const focal = Offset(200, 200);
      state.handleScaleStart(
        ScaleStartDetails(
          focalPoint: focal,
          localFocalPoint: focal,
          pointerCount: 2,
        ),
      );
      expect(container.read(isZoomingProvider), isTrue);
      state.handleScaleUpdate(
        ScaleUpdateDetails(
          focalPoint: focal,
          localFocalPoint: focal,
          scale: 2.0,
          pointerCount: 2,
        ),
      );
      state.handleScaleEnd(ScaleEndDetails(pointerCount: 2));

      expect(container.read(canvasTransformProvider).zoom, isNot(before));
      expect(container.read(isZoomingProvider), isFalse);
    });
  });
}
