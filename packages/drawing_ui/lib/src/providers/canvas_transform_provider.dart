import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/canvas_transform.dart';
import 'package:drawing_ui/src/providers/canvas_transform_math.dart';

export 'package:drawing_ui/src/providers/canvas_transform.dart';
export 'package:drawing_ui/src/providers/canvas_zoom_providers.dart';

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
  ///
  /// [minZoom] minimum zoom limit (defaults to legacy 0.25)
  /// [maxZoom] maximum zoom limit (defaults to legacy 5.0)
  void setZoom(double zoom, {double minZoom = 0.25, double maxZoom = 5.0}) {
    final clampedZoom = zoom.clamp(minZoom, maxZoom);
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
  /// [minZoom] minimum zoom limit (defaults to legacy 0.25)
  /// [maxZoom] maximum zoom limit (defaults to legacy 5.0)
  void applyZoomDelta(
    double delta,
    Offset focalPoint, {
    double minZoom = 0.25,
    double maxZoom = 5.0,
  }) {
    final newZoom = (state.zoom * delta).clamp(minZoom, maxZoom);

    // Calculate new offset to keep focal point stationary
    // The point under the finger should stay under the finger
    final focalCanvasPoint = state.screenToCanvas(focalPoint);
    final newOffset = focalPoint - focalCanvasPoint * newZoom;

    state = CanvasTransform(
        zoom: newZoom, offset: newOffset, baselineZoom: state.baselineZoom);
  }

  /// Apply zoom delta with custom limits from CanvasMode.
  ///
  /// [delta] is the scale multiplier
  /// [focalPoint] is the screen coordinate to zoom around
  /// [minZoom] minimum zoom from CanvasMode
  /// [maxZoom] maximum zoom from CanvasMode
  /// [viewportSize] for clamping pan after zoom
  /// [pageSize] for clamping pan after zoom
  /// [unlimitedPan] for clamping pan after zoom
  void applyZoomDeltaClamped(
    double delta,
    Offset focalPoint, {
    required double minZoom,
    required double maxZoom,
    Size? viewportSize,
    Size? pageSize,
    bool unlimitedPan = true,
  }) {
    final newZoom = (state.zoom * delta).clamp(minZoom, maxZoom);

    // Calculate new offset to keep focal point stationary
    final focalCanvasPoint = state.screenToCanvas(focalPoint);
    var newOffset = focalPoint - focalCanvasPoint * newZoom;

    // Apply pan clamping if not unlimited
    if (!unlimitedPan && viewportSize != null && pageSize != null) {
      newOffset = clampPageOffset(
        newOffset,
        viewportSize: viewportSize,
        pageSize: pageSize,
        zoom: newZoom,
      );
    }

    state = CanvasTransform(
        zoom: newZoom, offset: newOffset, baselineZoom: state.baselineZoom);
  }

  /// Apply pan delta (for drag gesture).
  ///
  /// [delta] is the screen coordinate movement
  void applyPanDelta(Offset delta) {
    state = state.copyWith(offset: state.offset + delta);
  }

  /// Apply pan delta with clamping for limited canvas mode.
  ///
  /// [delta] is the screen coordinate movement
  /// [viewportSize] is the screen viewport size
  /// [pageSize] is the document page size
  /// [unlimitedPan] if false, pan will be clamped to keep page visible
  void applyPanDeltaClamped(
    Offset delta, {
    required Size viewportSize,
    required Size pageSize,
    required bool unlimitedPan,
  }) {
    if (unlimitedPan) {
      // No clamping for unlimited pan
      state = state.copyWith(offset: state.offset + delta);
      return;
    }

    // Clamp pan so the page stays visible: centered on an axis where it is
    // smaller than the viewport, edge-clamped where it is larger.
    final newOffset = clampPageOffset(
      state.offset + delta,
      viewportSize: viewportSize,
      pageSize: pageSize,
      zoom: state.zoom,
    );

    state = state.copyWith(offset: newOffset);
  }

  /// Reset to baseline zoom (what user sees as "100%").
  void reset() {
    state = CanvasTransform(
      zoom: state.baselineZoom,
      offset: Offset.zero,
      baselineZoom: state.baselineZoom,
    );
  }

  /// Fit canvas to screen (return to baseline zoom).
  void fitToScreen() {
    state = CanvasTransform(
      zoom: state.baselineZoom,
      offset: Offset.zero,
      baselineZoom: state.baselineZoom,
    );
  }

  /// Initialize transform for limited canvas (fit page within viewport).
  ///
  /// [viewportSize] is the screen viewport size
  /// [pageSize] is the document page size
  /// Uses min(fitWidth, fitHeight) so the page fits both dimensions.
  void initializeForPage({
    required Size viewportSize,
    required Size pageSize,
  }) {
    final baselineZoom = fitPageZoom(viewportSize, pageSize);

    // Center page both horizontally AND vertically
    state = CanvasTransform(
      zoom: baselineZoom,
      offset: centeredPageOffset(viewportSize, pageSize, baselineZoom),
      baselineZoom: baselineZoom,
    );
  }

  /// Snap back zoom and offset for limited canvas.
  ///
  /// Called when gesture ends.
  /// - If zoom < fitHeight: snap back to fitHeight (fill screen)
  /// - If zoom >= fitHeight (zoom in): keep current zoom
  /// [viewportSize] is the screen viewport size
  /// [pageSize] is the document page size
  void snapBackForPage({
    required Size viewportSize,
    required Size pageSize,
  }) {
    final baselineZoom = fitPageZoom(viewportSize, pageSize);

    if (state.zoom < baselineZoom) {
      state = CanvasTransform(
        zoom: baselineZoom,
        offset: centeredPageOffset(viewportSize, pageSize, baselineZoom),
        baselineZoom: baselineZoom,
      );
    } else {
      // Zoom >= baseline: keep current zoom, just clamp offset
      _clampOffsetLimitedCanvas(viewportSize, pageSize);
    }
  }

  /// Recenter page for viewport changes (e.g., sidebar toggle, rotation).
  ///
  /// Recalculates baselineZoom for the new viewport and preserves
  /// the user's relative zoom level. E.g. if user was at 150%,
  /// after rotation they stay at 150%.
  void recenterForViewport({
    required Size viewportSize,
    required Size pageSize,
  }) {
    final newBaselineZoom = fitPageZoom(viewportSize, pageSize);

    // Preserve relative zoom (e.g. 150% stays 150%)
    final currentRelativeZoom =
        state.baselineZoom > 0 ? state.zoom / state.baselineZoom : 1.0;
    final newZoom = newBaselineZoom * currentRelativeZoom;

    state = state.copyWith(
      zoom: newZoom,
      baselineZoom: newBaselineZoom,
    );

    _clampOffsetLimitedCanvas(viewportSize, pageSize);
  }

  /// Clamp offset for limited canvas (center if smaller, clamp if larger).
  void _clampOffsetLimitedCanvas(Size viewportSize, Size pageSize) {
    final newOffset = clampPageOffset(
      state.offset,
      viewportSize: viewportSize,
      pageSize: pageSize,
      zoom: state.zoom,
    );
    if (newOffset != state.offset) {
      state = state.copyWith(offset: newOffset);
    }
  }

  /// Go to a specific zoom level and center the page.
  void goToZoom({
    required double targetZoom,
    required Size viewportSize,
    required Size pageSize,
    double minZoom = 0.25,
    double maxZoom = 5.0,
  }) {
    final clampedZoom = targetZoom.clamp(minZoom, maxZoom);

    final pageScreenWidth = pageSize.width * clampedZoom;
    final pageScreenHeight = pageSize.height * clampedZoom;

    // Center page
    final offsetX = pageScreenWidth <= viewportSize.width
        ? (viewportSize.width - pageScreenWidth) / 2
        : 0.0;
    final offsetY = pageScreenHeight <= viewportSize.height
        ? (viewportSize.height - pageScreenHeight) / 2
        : 0.0;

    state = state.copyWith(
      zoom: clampedZoom,
      offset: Offset(offsetX, offsetY),
    );
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
