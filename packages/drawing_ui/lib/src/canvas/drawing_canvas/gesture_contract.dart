part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Implements the abstract accessors of [DrawingCanvasGestureHandlers].
mixin _GestureContract
    on DrawingCanvasGestureHandlers<DrawingCanvas>, _CanvasFields {
  /// Canvas mode configuration (for gesture handlers)
  @override
  core.CanvasMode? get canvasMode => widget.canvasMode;

  // ─────────────────────────────────────────────────────────────────────────
  // Public Getters/Setters (for mixins and testing)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  @visibleForTesting
  DrawingController get drawingController => _drawingController;

  @override
  int get pointerCount => _pointerCount;
  @override
  set pointerCount(int value) => _pointerCount = value;

  @override
  Offset? get lastPoint => _lastPoint;
  @override
  set lastPoint(Offset? value) => _lastPoint = value;

  @override
  bool get isSelecting => _isSelecting;
  @override
  set isSelecting(bool value) => _isSelecting = value;

  @override
  bool get isDrawingShape => _isDrawingShape;
  @override
  set isDrawingShape(bool value) => _isDrawingShape = value;

  @override
  core.ShapeTool? get activeShapeTool => _activeShapeTool;
  @override
  set activeShapeTool(core.ShapeTool? value) => _activeShapeTool = value;

  @override
  bool get isStraightLineDrawing => _isStraightLineDrawing;
  @override
  set isStraightLineDrawing(bool value) => _isStraightLineDrawing = value;

  @override
  core.DrawingPoint? get straightLineStart => _straightLineStart;
  @override
  set straightLineStart(core.DrawingPoint? value) => _straightLineStart = value;

  @override
  core.DrawingPoint? get straightLineEnd => _straightLineEnd;
  @override
  set straightLineEnd(core.DrawingPoint? value) => _straightLineEnd = value;

  @override
  core.StrokeStyle? get straightLineStyle => _straightLineStyle;
  @override
  set straightLineStyle(core.StrokeStyle? value) => _straightLineStyle = value;

  @override
  Set<String> get erasedShapeIds => _erasedShapeIds;

  @override
  Map<String, List<int>> get pixelEraseHits => _pixelEraseHits;

  @override
  List<core.Stroke> get pixelEraseOriginalStrokes => _pixelEraseOriginalStrokes;

  @override
  core.EraserSweep get pixelEraseSweep => _pixelEraseSweep;

  @override
  Map<String, Set<String>> get erasedNoteStrokeIds => _erasedNoteStrokeIds;

  @override
  Map<String, Set<String>> get erasedNoteShapeIds => _erasedNoteShapeIds;

  @override
  Map<String, Map<String, List<int>>> get pixelEraseNoteHits =>
      _pixelEraseNoteHits;

  @override
  Map<String, List<core.Stroke>> get pixelEraseNoteOriginalStrokes =>
      _pixelEraseNoteOriginalStrokes;

  @override
  LaserController get laserController => _laserController;

  @override
  bool get isLaserDrawing => _isLaserDrawing;
  @override
  set isLaserDrawing(bool value) => _isLaserDrawing = value;

  @override
  Offset? get lastFocalPoint => _lastFocalPoint;
  @override
  set lastFocalPoint(Offset? value) => _lastFocalPoint = value;

  @override
  double? get lastScale => _lastScale;
  @override
  set lastScale(double? value) => _lastScale = value;

  @override
  core.StickyNote? get drawingInsideNote => _drawingInsideNote;
  @override
  set drawingInsideNote(core.StickyNote? value) => _drawingInsideNote = value;

  @override
  Offset? get scaleStartFocalPoint => _scaleStartFocalPoint;
  @override
  set scaleStartFocalPoint(Offset? value) => _scaleStartFocalPoint = value;

  @override
  ValueChanged<int>? get onPageSwipe => widget.onPageSwipe;
  @override
  VoidCallback? get onPageSwipeDragBegin => widget.onPageSwipeDragBegin;
  @override
  ValueChanged<double>? get onPageSwipeDragUpdate =>
      widget.onPageSwipeDragUpdate;
  @override
  ValueChanged<double>? get onPageSwipeDragEnd => widget.onPageSwipeDragEnd;

  @override
  bool get scaleGestureIsZoom => _scaleGestureIsZoom;
  @override
  set scaleGestureIsZoom(bool value) => _scaleGestureIsZoom = value;
}
