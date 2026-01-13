import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// CANVAS TRANSFORM STATE
// =============================================================================

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

  const CanvasTransform({
    this.zoom = 1.0,
    this.offset = Offset.zero,
  });

  /// Minimum allowed zoom level (25%)
  static const double minZoom = 0.25;

  /// Maximum allowed zoom level (500%)
  static const double maxZoom = 5.0;

  /// Creates a copy with updated values
  CanvasTransform copyWith({double? zoom, Offset? offset}) {
    return CanvasTransform(
      zoom: zoom ?? this.zoom,
      offset: offset ?? this.offset,
    );
  }

  /// Transform matrix for canvas rendering.
  ///
  /// Applies translation (pan) first, then scale (zoom).
  /// This order ensures zoom happens around the correct focal point.
  Matrix4 get matrix {
    return Matrix4.identity()
      ..translate(offset.dx, offset.dy)
      ..scale(zoom);
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
          offset == other.offset;

  @override
  int get hashCode => zoom.hashCode ^ offset.hashCode;
}

// =============================================================================
// CANVAS TRANSFORM PROVIDER
// =============================================================================

/// Canvas transform state provider.
///
/// Manages zoom and pan state for the drawing canvas.
final canvasTransformProvider =
    StateNotifierProvider<CanvasTransformNotifier, CanvasTransform>((ref) {
  return CanvasTransformNotifier();
});

/// Notifier for canvas transform state.
class CanvasTransformNotifier extends StateNotifier<CanvasTransform> {
  CanvasTransformNotifier() : super(const CanvasTransform());

  /// Set absolute zoom level (clamped to min/max).
  void setZoom(double zoom) {
    final clampedZoom =
        zoom.clamp(CanvasTransform.minZoom, CanvasTransform.maxZoom);
    state = state.copyWith(zoom: clampedZoom);
  }

  /// Set absolute pan offset.
  void setOffset(Offset offset) {
    state = state.copyWith(offset: offset);
  }

  /// Apply zoom delta around a focal point (for pinch gesture).
  ///
  /// [delta] is the scale multiplier (e.g., 1.1 for 10% zoom in)
  /// [focalPoint] is the screen coordinate to zoom around
  void applyZoomDelta(double delta, Offset focalPoint) {
    final newZoom = (state.zoom * delta).clamp(
      CanvasTransform.minZoom,
      CanvasTransform.maxZoom,
    );

    // Calculate new offset to keep focal point stationary
    // The point under the finger should stay under the finger
    final focalCanvasPoint = state.screenToCanvas(focalPoint);
    final newOffset = focalPoint - focalCanvasPoint * newZoom;

    state = CanvasTransform(zoom: newZoom, offset: newOffset);
  }

  /// Apply pan delta (for drag gesture).
  ///
  /// [delta] is the screen coordinate movement
  void applyPanDelta(Offset delta) {
    state = state.copyWith(offset: state.offset + delta);
  }

  /// Reset to default (zoom 100%, centered).
  void reset() {
    state = const CanvasTransform();
  }

  /// Fit canvas to screen (reset zoom and center).
  void fitToScreen() {
    state = const CanvasTransform(zoom: 1.0, offset: Offset.zero);
  }

  /// Zoom in by a fixed step (for button/keyboard).
  void zoomIn() {
    applyZoomDelta(1.25, Offset.zero); // 25% zoom in
  }

  /// Zoom out by a fixed step (for button/keyboard).
  void zoomOut() {
    applyZoomDelta(0.8, Offset.zero); // 20% zoom out
  }
}

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Current zoom level (1.0 = 100%).
final zoomLevelProvider = Provider<double>((ref) {
  return ref.watch(canvasTransformProvider).zoom;
});

/// Zoom percentage string for UI display (e.g., "150%").
final zoomPercentageProvider = Provider<String>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return '${(zoom * 100).round()}%';
});

/// Whether canvas is at default zoom (100%).
final isDefaultZoomProvider = Provider<bool>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return (zoom - 1.0).abs() < 0.01;
});

/// Whether canvas can zoom in further.
final canZoomInProvider = Provider<bool>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return zoom < CanvasTransform.maxZoom;
});

/// Whether canvas can zoom out further.
final canZoomOutProvider = Provider<bool>((ref) {
  final zoom = ref.watch(zoomLevelProvider);
  return zoom > CanvasTransform.minZoom;
});
