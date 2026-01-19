import 'package:flutter/material.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Forward reference to avoid circular dependency
abstract class DrawingCanvas {}

/// Helper methods for DrawingCanvas.
/// These are extracted for better maintainability.
mixin DrawingCanvasHelpers<T extends ConsumerStatefulWidget> on ConsumerState<T> {
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

  /// Checks if a point is inside the selection bounds.
  bool isPointInSelection(Offset point, core.Selection selection) {
    final bounds = selection.bounds;
    return point.dx >= bounds.left &&
        point.dx <= bounds.right &&
        point.dy >= bounds.top &&
        point.dy <= bounds.bottom;
  }

  /// Apply eraser filters based on settings
  List<core.Stroke> applyEraserFilters(
    List<core.Stroke> strokes,
    EraserSettings settings,
  ) {
    var filtered = strokes;

    // Filter: Erase only highlighter strokes
    if (settings.eraseOnlyHighlighter) {
      filtered = filtered.where((stroke) {
        // Check if stroke is a highlighter (has transparency)
        final color = Color(stroke.style.color);
        return color.a < 1.0; // Highlighters typically have alpha < 1.0
      }).toList();
    }

    return filtered;
  }
}
