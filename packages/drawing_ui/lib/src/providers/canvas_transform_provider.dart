import 'package:flutter/foundation.dart';
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
      // Calculate page bounds in screen coordinates
      final pageScreenWidth = pageSize.width * newZoom;
      final pageScreenHeight = pageSize.height * newZoom;

      // Horizontal clamping
      if (pageScreenWidth <= viewportSize.width) {
        newOffset = Offset(
          (viewportSize.width - pageScreenWidth) / 2,
          newOffset.dy,
        );
      } else {
        final minX = viewportSize.width - pageScreenWidth;
        final maxX = 0.0;
        newOffset = Offset(
          newOffset.dx.clamp(minX, maxX),
          newOffset.dy,
        );
      }

      // Vertical clamping
      if (pageScreenHeight <= viewportSize.height) {
        newOffset = Offset(
          newOffset.dx,
          (viewportSize.height - pageScreenHeight) / 2,
        );
      } else {
        final minY = viewportSize.height - pageScreenHeight;
        final maxY = 0.0;
        newOffset = Offset(
          newOffset.dx,
          newOffset.dy.clamp(minY, maxY),
        );
      }
    }

    state = CanvasTransform(zoom: newZoom, offset: newOffset);
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

    // Calculate new offset
    var newOffset = state.offset + delta;

    // Calculate page bounds in screen coordinates
    final pageScreenWidth = pageSize.width * state.zoom;
    final pageScreenHeight = pageSize.height * state.zoom;

    // Clamp pan so page stays visible
    // For portrait mode: page fills width, limited vertical scroll
    // For landscape mode: page fills height, limited horizontal scroll

    // Horizontal clamping: center page if smaller than viewport
    if (pageScreenWidth <= viewportSize.width) {
      // Center horizontally
      newOffset = Offset(
        (viewportSize.width - pageScreenWidth) / 2,
        newOffset.dy,
      );
    } else {
      // Clamp so page doesn't go too far left or right
      final minX = viewportSize.width - pageScreenWidth;
      final maxX = 0.0;
      newOffset = Offset(
        newOffset.dx.clamp(minX, maxX),
        newOffset.dy,
      );
    }

    // Vertical clamping: page top/bottom should touch viewport edges
    if (pageScreenHeight <= viewportSize.height) {
      // Center vertically
      newOffset = Offset(
        newOffset.dx,
        (viewportSize.height - pageScreenHeight) / 2,
      );
    } else {
      // Clamp so page doesn't go too far up or down
      final minY = viewportSize.height - pageScreenHeight;
      final maxY = 0.0;
      newOffset = Offset(
        newOffset.dx,
        newOffset.dy.clamp(minY, maxY),
      );
    }

    state = state.copyWith(offset: newOffset);
  }

  /// Reset to default (zoom 100%, centered).
  void reset() {
    state = const CanvasTransform();
  }

  /// Fit canvas to screen (reset zoom and center).
  void fitToScreen() {
    state = const CanvasTransform(zoom: 1.0, offset: Offset.zero);
  }

  /// Initialize transform for limited canvas (fill viewport with page).
  ///
  /// [viewportSize] is the screen viewport size
  /// [pageSize] is the document page size
  /// This calculates the optimal zoom to fill the viewport
  void initializeForPage({
    required Size viewportSize,
    required Size pageSize,
  }) {
    // Calculate zoom to fill viewport (page fills the screen)
    final fillZoom = _calculateFitZoom(viewportSize, pageSize);

    // Calculate offset - center horizontally, top-align vertically
    final pageScreenWidth = pageSize.width * fillZoom;
    final pageScreenHeight = pageSize.height * fillZoom;

    // Center horizontally if page is narrower than viewport
    final offsetX = pageScreenWidth < viewportSize.width
        ? (viewportSize.width - pageScreenWidth) / 2
        : 0.0;
    // Top-align vertically (offset Y = 0)
    final offsetY = pageScreenHeight < viewportSize.height
        ? (viewportSize.height - pageScreenHeight) / 2
        : 0.0;

    // #region agent log
    debugPrint('🔍 [DEBUG] initializeForPage:');
    debugPrint(
        '🔍 [DEBUG]   viewportSize: ${viewportSize.width} x ${viewportSize.height}');
    debugPrint('🔍 [DEBUG]   pageSize: ${pageSize.width} x ${pageSize.height}');
    debugPrint('🔍 [DEBUG]   fillZoom: $fillZoom');
    debugPrint(
        '🔍 [DEBUG]   pageScreenSize: $pageScreenWidth x $pageScreenHeight');
    debugPrint('🔍 [DEBUG]   offset: ($offsetX, $offsetY)');
    // #endregion

    state = CanvasTransform(
      zoom: fillZoom,
      offset: Offset(offsetX, offsetY),
    );
  }

  /// Snap back zoom and offset for limited canvas.
  ///
  /// Called when gesture ends to ensure page fills viewport.
  /// [viewportSize] is the screen viewport size
  /// [pageSize] is the document page size
  void snapBackForPage({
    required Size viewportSize,
    required Size pageSize,
  }) {
    // Calculate fill zoom (same as initializeForPage)
    final fillZoom = _calculateFitZoom(viewportSize, pageSize);

    // If current zoom is below fill zoom, snap back to fill state
    if (state.zoom < fillZoom) {
      // Calculate new offset at fill zoom
      final pageScreenWidth = pageSize.width * fillZoom;
      final pageScreenHeight = pageSize.height * fillZoom;

      // Center horizontally if page is narrower than viewport
      final offsetX = pageScreenWidth < viewportSize.width
          ? (viewportSize.width - pageScreenWidth) / 2
          : 0.0;
      // Top-align or center vertically
      final offsetY = pageScreenHeight < viewportSize.height
          ? (viewportSize.height - pageScreenHeight) / 2
          : 0.0;

      state = CanvasTransform(
        zoom: fillZoom,
        offset: Offset(offsetX, offsetY),
      );
    } else {
      // Just ensure offset is clamped
      _clampOffset(viewportSize, pageSize);
    }
  }

  /// Calculate zoom to fit page in viewport (page fully visible with margins).
  ///
  /// Uses fit strategy for both portrait and landscape:
  /// - Portrait viewport: page fits in viewport, side/top margins
  /// - Landscape viewport: page fits in viewport, fully visible
  double _calculateFitZoom(Size viewportSize, Size pageSize) {
    final horizontalZoom = viewportSize.width / pageSize.width;
    final verticalZoom = viewportSize.height / pageSize.height;
    
    // Always use SMALLER zoom (fit to screen, no overflow)
    // This ensures entire page is visible with margins
    final fitZoom = horizontalZoom < verticalZoom ? horizontalZoom : verticalZoom;
    
    // Don't enlarge beyond 1.0 (keep natural size)
    // But allow shrinking to any level needed to fit
    return fitZoom.clamp(0.01, 1.0);
  }

  /// Clamp offset to keep page within bounds.
  void _clampOffset(Size viewportSize, Size pageSize) {
    final pageScreenWidth = pageSize.width * state.zoom;
    final pageScreenHeight = pageSize.height * state.zoom;

    var newOffset = state.offset;

    // Horizontal clamping
    if (pageScreenWidth <= viewportSize.width) {
      newOffset = Offset(
        (viewportSize.width - pageScreenWidth) / 2,
        newOffset.dy,
      );
    } else {
      final minX = viewportSize.width - pageScreenWidth;
      final maxX = 0.0;
      newOffset = Offset(
        newOffset.dx.clamp(minX, maxX),
        newOffset.dy,
      );
    }

    // Vertical clamping
    if (pageScreenHeight <= viewportSize.height) {
      newOffset = Offset(
        newOffset.dx,
        (viewportSize.height - pageScreenHeight) / 2,
      );
    } else {
      final minY = viewportSize.height - pageScreenHeight;
      final maxY = 0.0;
      newOffset = Offset(
        newOffset.dx,
        newOffset.dy.clamp(minY, maxY),
      );
    }

    if (newOffset != state.offset) {
      state = state.copyWith(offset: newOffset);
    }
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

/// Whether zoom gesture is currently active.
final isZoomingProvider = StateProvider<bool>((ref) => false);
