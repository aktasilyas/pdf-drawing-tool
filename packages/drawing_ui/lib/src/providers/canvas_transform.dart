import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Canvas transform state for zoom and pan.
///
/// Stores the current zoom level and pan offset for the drawing canvas.
/// Used to transform the canvas view and convert screen coordinates to
/// canvas coordinates.
class CanvasTransform {
  /// Current zoom level (1.0 = 100%)
  final double zoom;

  /// Current pan offset in screen coordinates
  final Offset offset;

  /// Baseline zoom = the zoom level when page fits the viewport.
  /// UI shows "100%" at this value.
  /// For whiteboard/infinite mode this is 1.0.
  final double baselineZoom;

  const CanvasTransform({
    this.zoom = 1.0,
    this.offset = Offset.zero,
    this.baselineZoom = 1.0,
  });

  /// Minimum allowed zoom level (25%)
  static const double minZoom = 0.25;

  /// Maximum allowed zoom level (500%)
  static const double maxZoom = 5.0;

  /// UI display percentage relative to baseline zoom.
  /// At baselineZoom this returns 100, at 2x baselineZoom returns 200, etc.
  double get displayPercentage => (zoom / baselineZoom) * 100;

  /// Creates a copy with updated values
  CanvasTransform copyWith(
      {double? zoom, Offset? offset, double? baselineZoom}) {
    return CanvasTransform(
      zoom: zoom ?? this.zoom,
      offset: offset ?? this.offset,
      baselineZoom: baselineZoom ?? this.baselineZoom,
    );
  }

  /// Transform matrix for canvas rendering.
  ///
  /// Applies translation (pan) first, then scale (zoom).
  /// This order ensures zoom happens around the correct focal point.
  Matrix4 get matrix {
    return Matrix4.identity()
      ..translateByVector3(vector.Vector3(offset.dx, offset.dy, 0))
      ..scaleByVector3(vector.Vector3(zoom, zoom, 1.0));
  }

  /// Converts screen coordinates to canvas coordinates.
  ///
  /// Use this to transform pointer events to canvas space.
  Offset screenToCanvas(Offset screenPoint) {
    return (screenPoint - offset) / zoom;
  }

  /// Converts canvas coordinates to screen coordinates.
  ///
  /// Use this for hit testing and UI overlays.
  Offset canvasToScreen(Offset canvasPoint) {
    return canvasPoint * zoom + offset;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasTransform &&
          runtimeType == other.runtimeType &&
          zoom == other.zoom &&
          offset == other.offset &&
          baselineZoom == other.baselineZoom;

  @override
  int get hashCode => zoom.hashCode ^ offset.hashCode ^ baselineZoom.hashCode;
}
