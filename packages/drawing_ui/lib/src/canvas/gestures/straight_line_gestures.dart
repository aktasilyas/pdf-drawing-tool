part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Straight-line handlers (highlighter straight-line mode and ruler pen).
mixin _StraightLineGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _RulerSnapping<T>,
        _StickyNoteGestures<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // STRAIGHT LINE EVENT HANDLERS (for highlighter)
  // ─────────────────────────────────────────────────────────────────────────

  void handleStraightLineDown(PointerDownEvent event) {
    if (_isPointOnRuler(event.localPosition)) return;

    _detectDrawingInsideNote(event);
    var point = _clampToNote(createDrawingPoint(event));
    point = _snapToRuler(point);
    final style = getCurrentStyle();

    straightLineStart = point;
    straightLineEnd = point;
    straightLineStyle = style;
    isStraightLineDrawing = true;

    setState(() {});
  }

  void handleStraightLineMove(PointerMoveEvent event) {
    if (!isStraightLineDrawing || straightLineStart == null) return;

    var point = _clampToNote(createDrawingPoint(event));
    point = _snapToRuler(point);
    straightLineEnd = point;

    setState(() {}); // Triggers rebuild for real-time preview
  }

  void handleStraightLineUp(PointerUpEvent event) {
    if (!isStraightLineDrawing) return;

    final start = straightLineStart;
    final end = straightLineEnd;
    final style = straightLineStyle;

    if (start != null && end != null && style != null) {
      // Create stroke with just two points (start and end)
      final stroke = core.Stroke.create(
        points: [start, end],
        style: style,
      );

      if (drawingInsideNote != null) {
        _addStrokeToStickyNote(stroke, drawingInsideNote!);
      } else {
        ref.read(historyManagerProvider.notifier).addStroke(stroke);
      }
    }

    // Reset state
    straightLineStart = null;
    straightLineEnd = null;
    straightLineStyle = null;
    isStraightLineDrawing = false;
    drawingInsideNote = null;

    setState(() {});
  }
}
