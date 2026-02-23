import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Forward reference to avoid circular dependency
abstract class DrawingCanvas {}

/// Helper methods for DrawingCanvas.
/// These are extracted for better maintainability.
mixin DrawingCanvasHelpers<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Creates a DrawingPoint from a pointer event.
  /// Transforms screen coordinates to canvas coordinates based on zoom/pan.
  core.DrawingPoint createDrawingPoint(PointerEvent event) {
    final transform = ref.read(canvasTransformProvider);

    // Convert screen coordinates to canvas coordinates
    final canvasPoint = transform.screenToCanvas(event.localPosition);

    return core.DrawingPoint(
      x: canvasPoint.dx,
      y: canvasPoint.dy,
      pressure: event.pressure.clamp(0.0, 1.0),
      tilt: 0.0,
      timestamp: event.timeStamp.inMilliseconds,
    );
  }

  /// Gets the current stroke style from provider.
  core.StrokeStyle getCurrentStyle() {
    return ref.read(activeStrokeStyleProvider);
  }

  /// Checks if a point is inside the selection interaction area.
  ///
  /// Constants match [SelectionHandles] exactly: hitR=22, rotDist=36.
  /// Includes: expanded bounds (for scale handles), rotation handle, and
  /// the connecting line between top-center and rotation handle.
  bool isPointInSelection(Offset point, core.Selection selection) {
    final bounds = selection.bounds;
    const hitR = 22.0;
    const rotDist = 36.0;

    // Check expanded bounds — handles extend beyond bounds by hitR
    if (point.dx >= bounds.left - hitR &&
        point.dx <= bounds.right + hitR &&
        point.dy >= bounds.top - hitR &&
        point.dy <= bounds.bottom + hitR) {
      return true;
    }

    // Check rotation handle (rotDist above top-center, hitR radius)
    final cx = (bounds.left + bounds.right) / 2;
    final rotHandleY = bounds.top - rotDist;
    final dx = point.dx - cx;
    final dy = point.dy - rotHandleY;
    if (dx * dx + dy * dy <= hitR * hitR) {
      return true;
    }

    // Check line between top-center and rotation handle
    if ((point.dx - cx).abs() <= hitR &&
        point.dy >= rotHandleY - hitR &&
        point.dy <= bounds.top) {
      return true;
    }

    return false;
  }

  /// Filters strokes based on lasso selectable type settings.
  List<core.Stroke> filterStrokesBySelectableType(
    List<core.Stroke> strokes,
    Map<SelectableType, bool> selectableTypes,
  ) {
    final allowHandwriting =
        selectableTypes[SelectableType.handwriting] ?? true;
    final allowHighlighter =
        selectableTypes[SelectableType.highlighter] ?? true;
    if (allowHandwriting && allowHighlighter) return strokes;

    return strokes.where((stroke) {
      final isHighlighter =
          stroke.style.nibShape == core.NibShape.rectangle &&
              stroke.style.opacity < 1.0;
      return isHighlighter ? allowHighlighter : allowHandwriting;
    }).toList();
  }

  /// Apply eraser filters based on settings
  List<core.Stroke> applyEraserFilters(
    List<core.Stroke> strokes,
    EraserSettings settings,
  ) {
    if (!settings.eraseOnlyHighlighter) return strokes;

    // Highlighter strokes: rectangle nib + opacity < 1.0
    return strokes.where((stroke) {
      return stroke.style.nibShape == core.NibShape.rectangle &&
          stroke.style.opacity < 1.0;
    }).toList();
  }
}
