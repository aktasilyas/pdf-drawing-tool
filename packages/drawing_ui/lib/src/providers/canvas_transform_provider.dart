import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
  CanvasTransform copyWith({double? zoom, Offset? offset, double? baselineZoom}) {
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

    state = CanvasTransform(zoom: newZoom, offset: newOffset, baselineZoom: state.baselineZoom);
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

    state = CanvasTransform(zoom: newZoom, offset: newOffset, baselineZoom: state.baselineZoom);
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
    final baselineZoom = _fitZoom(viewportSize, pageSize);

    // Center page both horizontally AND vertically
    final pageScreenWidth = pageSize.width * baselineZoom;
    final pageScreenHeight = pageSize.height * baselineZoom;
    final offsetX = (viewportSize.width - pageScreenWidth) / 2;
    final offsetY = (viewportSize.height - pageScreenHeight) / 2;

    state = CanvasTransform(
      zoom: baselineZoom,
      offset: Offset(offsetX, offsetY),
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
    final baselineZoom = _fitZoom(viewportSize, pageSize);

    if (state.zoom < baselineZoom) {
      final pageScreenWidth = pageSize.width * baselineZoom;
      final pageScreenHeight = pageSize.height * baselineZoom;
      final offsetX = (viewportSize.width - pageScreenWidth) / 2;
      final offsetY = (viewportSize.height - pageScreenHeight) / 2;

      state = CanvasTransform(
        zoom: baselineZoom,
        offset: Offset(offsetX, offsetY),
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
    final newBaselineZoom = _fitZoom(viewportSize, pageSize);

    // Preserve relative zoom (e.g. 150% stays 150%)
    final currentRelativeZoom = state.baselineZoom > 0
        ? state.zoom / state.baselineZoom
        : 1.0;
    final newZoom = newBaselineZoom * currentRelativeZoom;

    state = state.copyWith(
      zoom: newZoom,
      baselineZoom: newBaselineZoom,
    );

    _clampOffsetLimitedCanvas(viewportSize, pageSize);
  }

  /// Baseline zoom that fits the page within the viewport.
  ///
  /// Uses min(fitWidth, fitHeight) with a small padding factor so the
  /// page doesn't touch the viewport edges on narrow (portrait) screens.
  static double _fitZoom(Size viewportSize, Size pageSize) {
    const padding = 0.96; // ~4% breathing room on the tight axis
    final fitWidth = viewportSize.width / pageSize.width;
    final fitHeight = viewportSize.height / pageSize.height;
    return (fitWidth < fitHeight) ? fitWidth * padding : fitHeight;
  }

  /// Clamp offset for limited canvas (top-aligned, not centered).
  void _clampOffsetLimitedCanvas(Size viewportSize, Size pageSize) {
    final pageScreenWidth = pageSize.width * state.zoom;
    final pageScreenHeight = pageSize.height * state.zoom;

    var newOffset = state.offset;

    // Horizontal clamping (center if smaller, clamp if larger)
    if (pageScreenWidth <= viewportSize.width) {
      // Page narrower than viewport: center horizontally
      newOffset = Offset(
        (viewportSize.width - pageScreenWidth) / 2,
        newOffset.dy,
      );
    } else {
      // Page wider than viewport: clamp to keep within bounds
      final minX = viewportSize.width - pageScreenWidth; // negative
      final maxX = 0.0;
      newOffset = Offset(
        newOffset.dx.clamp(minX, maxX),
        newOffset.dy,
      );
    }

    // Vertical clamping (center if smaller, clamp if larger)
    if (pageScreenHeight <= viewportSize.height) {
      // Page shorter than viewport: CENTER vertically
      newOffset = Offset(
        newOffset.dx,
        (viewportSize.height - pageScreenHeight) / 2,
      );
    } else {
      // Page taller than viewport: clamp to keep within bounds
      final minY = viewportSize.height - pageScreenHeight; // negative
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

  // NOTE: The following methods are kept for reference but not currently used
  // since we now use 1.0 (100%) as default zoom instead of fit-to-height/fit-to-screen
  
  /*
  /// Calculate zoom to fit page height to viewport height.
  /// 
  /// This ensures the page fills the viewport vertically (top=0, bottom=0).
  /// Horizontally, the page will be centered if narrower than viewport.
  /// 
  /// Uses fit-to-height strategy:
  /// - Page height = viewport height
  /// - Page may be wider or narrower than viewport (horizontal scroll/center)
  double _calculateFitHeightZoom(Size viewportSize, Size pageSize) {
    // Calculate zoom needed to fit page height to viewport height
    final verticalZoom = viewportSize.height / pageSize.height;
    
    // Allow any zoom level (no clamping to 1.0)
    // This allows pages to be enlarged if they're smaller than viewport
    return verticalZoom.clamp(0.01, double.infinity);
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
  */


  // NOTE: The following methods are kept for reference but not currently used
  // since we now use _clampOffsetLimitedCanvas for limited canvas mode
  
  /*
  /// Clamp offset to keep page within bounds (centers page if smaller than viewport).
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
  */

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

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Current zoom level (1.0 = 100%).
final zoomLevelProvider = Provider<double>((ref) {
  return ref.watch(canvasTransformProvider).zoom;
});

/// Zoom percentage string for UI display (e.g., "150%").
/// Now relative to baselineZoom: baseline = 100%.
final zoomPercentageProvider = Provider<String>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  final percentage = transform.displayPercentage.round();
  return '$percentage%';
});

/// Whether canvas is at baseline zoom (what user sees as "100%").
final isDefaultZoomProvider = Provider<bool>((ref) {
  final transform = ref.watch(canvasTransformProvider);
  return (transform.zoom - transform.baselineZoom).abs() < 0.01;
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

/// Current canvas viewport size (set by DrawingCanvas/DrawingScreen).
/// Used by zoom controls to compute target offsets.
final canvasViewportSizeProvider = StateProvider<Size>((ref) => Size.zero);
