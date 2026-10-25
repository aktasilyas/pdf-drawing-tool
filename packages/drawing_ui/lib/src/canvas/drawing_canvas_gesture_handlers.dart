import 'dart:async' show Timer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart' show BackgroundType;
import 'package:drawing_ui/src/canvas/stroke_painter.dart';
import 'package:drawing_ui/src/canvas/laser_controller.dart';
import 'package:drawing_ui/src/canvas/drawing_canvas_helpers.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/models/tool_type.dart';
import 'package:drawing_ui/src/widgets/ruler_overlay.dart'
    show rulerStripLength, rulerStripHeight;

part 'gestures/ruler_snapping.dart';
part 'gestures/sticky_note_gestures.dart';
part 'gestures/text_gestures.dart';
part 'gestures/placement_gestures.dart';
part 'gestures/selection_gestures.dart';
part 'gestures/shape_gestures.dart';
part 'gestures/straight_line_gestures.dart';
part 'gestures/laser_gestures.dart';
part 'gestures/note_eraser_gestures.dart';
part 'gestures/pixel_eraser_gestures.dart';
part 'gestures/eraser_gestures.dart';
part 'gestures/scale_gestures.dart';
part 'gestures/pointer_down_gestures.dart';
part 'gestures/pointer_move_up_gestures.dart';

/// Shared state contract for the gesture mixins of [DrawingCanvasState].
///
/// Abstract accessors are implemented by `DrawingCanvasState`; the private
/// fields are shared between the gesture mixins in this library.
mixin _GestureState<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T> {
  // Required fields from DrawingCanvasState
  core.CanvasMode? get canvasMode; // Canvas mode configuration
  DrawingController get drawingController;
  int get pointerCount;
  set pointerCount(int value);
  Offset? get lastPoint;
  set lastPoint(Offset? value);
  bool get isSelecting;
  set isSelecting(bool value);
  bool get isDrawingShape;
  set isDrawingShape(bool value);
  core.ShapeTool? get activeShapeTool;
  set activeShapeTool(core.ShapeTool? value);
  bool get isStraightLineDrawing;
  set isStraightLineDrawing(bool value);
  core.DrawingPoint? get straightLineStart;
  set straightLineStart(core.DrawingPoint? value);
  core.DrawingPoint? get straightLineEnd;
  set straightLineEnd(core.DrawingPoint? value);
  core.StrokeStyle? get straightLineStyle;
  set straightLineStyle(core.StrokeStyle? value);
  Set<String> get erasedShapeIds;
  Map<String, List<int>> get pixelEraseHits;
  List<core.Stroke> get pixelEraseOriginalStrokes;

  /// Path swept by the pixel eraser during the current gesture.
  core.EraserSweep get pixelEraseSweep;

  /// Note ID -> set of internal stroke IDs erased in current gesture.
  Map<String, Set<String>> get erasedNoteStrokeIds;

  /// Note ID -> set of internal shape IDs erased in current gesture.
  Map<String, Set<String>> get erasedNoteShapeIds;

  /// Note ID -> (stroke ID -> segment indices) for pixel erasure inside notes.
  Map<String, Map<String, List<int>>> get pixelEraseNoteHits;

  /// Note ID -> original strokes for pixel erasure inside notes.
  Map<String, List<core.Stroke>> get pixelEraseNoteOriginalStrokes;
  Offset? get lastFocalPoint;
  set lastFocalPoint(Offset? value);
  double? get lastScale;
  set lastScale(double? value);
  LaserController get laserController;
  bool get isLaserDrawing;
  set isLaserDrawing(bool value);
  core.StickyNote? get drawingInsideNote;
  set drawingInsideNote(core.StickyNote? value);
  Offset? get scaleStartFocalPoint;
  set scaleStartFocalPoint(Offset? value);
  ValueChanged<int>? get onPageSwipe;
  VoidCallback? get onPageSwipeDragBegin;
  ValueChanged<double>? get onPageSwipeDragUpdate;
  ValueChanged<double>? get onPageSwipeDragEnd;
  bool get scaleGestureIsZoom;
  set scaleGestureIsZoom(bool value);
  bool _swipeDragActive = false;

  // ── Long press paste menu ──
  Timer? _longPressTimer;
  Offset? _longPressScreenPos;
}

/// Gesture handling methods for DrawingCanvas.
/// Composes the private gesture mixins of this library.
abstract class DrawingCanvasGestureHandlers<T extends ConsumerStatefulWidget>
    extends ConsumerState<T>
    with
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _RulerSnapping<T>,
        _StickyNoteGestures<T>,
        _TextGestures<T>,
        _PlacementGestures<T>,
        _SelectionGestures<T>,
        _ShapeGestures<T>,
        _StraightLineGestures<T>,
        _LaserGestures<T>,
        _NoteEraserGestures<T>,
        _PixelEraserGestures<T>,
        _EraserGestures<T>,
        _ScaleGestures<T>,
        _PointerDownGestures<T>,
        _PointerMoveUpGestures<T> {
  /// Minimum distance between points to avoid excessive point creation.
  static const double minPointDistance = 1.0;
}
