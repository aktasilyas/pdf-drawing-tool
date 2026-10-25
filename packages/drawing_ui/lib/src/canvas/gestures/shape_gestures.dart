part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Shape tool handlers.
mixin _ShapeGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _StickyNoteGestures<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // SHAPE EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleShapeDown(PointerDownEvent event) {
    _detectDrawingInsideNote(event);

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    final coreShapeType = ref.read(activeCoreShapeTypeProvider);
    final isFilled = ref.read(shapeFilledProvider);
    final fillColor = ref.read(shapeFillColorProvider);
    final style = ref.read(shapeStrokeStyleProvider);

    // Create shape tool based on type
    switch (coreShapeType) {
      case core.ShapeType.line:
        activeShapeTool = core.LineTool(style: style);
        break;
      case core.ShapeType.arrow:
        activeShapeTool = core.ArrowTool(style: style);
        break;
      case core.ShapeType.rectangle:
        activeShapeTool = core.RectangleTool(
          style: style,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
      case core.ShapeType.ellipse:
        activeShapeTool = core.EllipseTool(
          style: style,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
      case core.ShapeType.triangle:
      case core.ShapeType.diamond:
      case core.ShapeType.star:
      case core.ShapeType.pentagon:
      case core.ShapeType.hexagon:
      case core.ShapeType.plus:
        activeShapeTool = core.GenericShapeTool(
          style: style,
          shapeType: coreShapeType,
          filled: isFilled,
          fillColor: fillColor,
        );
        break;
    }

    final clampedPoint = _clampToNote(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    activeShapeTool!.startShape(clampedPoint);

    isDrawingShape = true;
    setState(() {});
  }

  void handleShapeMove(PointerMoveEvent event) {
    final tool = activeShapeTool;
    if (tool == null) return;

    final transform = ref.read(canvasTransformProvider);
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    final clampedPoint = _clampToNote(core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: 1.0,
    ));

    tool.updateShape(clampedPoint);

    setState(() {});
  }

  void handleShapeUp(PointerUpEvent event) {
    final tool = activeShapeTool;
    if (tool == null) return;

    isDrawingShape = false;

    final shape = tool.endShape();

    if (shape != null) {
      if (drawingInsideNote != null) {
        _addShapeToStickyNote(shape, drawingInsideNote!);
      } else {
        final document = ref.read(documentProvider);
        final command = core.AddShapeCommand(
          layerIndex: document.activeLayerIndex,
          shape: shape,
        );
        ref.read(historyManagerProvider.notifier).execute(command);
      }
    }

    activeShapeTool = null;
    drawingInsideNote = null;
    setState(() {});
  }
}
