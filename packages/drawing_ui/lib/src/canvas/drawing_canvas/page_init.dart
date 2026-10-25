part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Limited-mode page centering and viewport change detection.
mixin _CanvasPageInit
    on DrawingCanvasGestureHandlers<DrawingCanvas>, _CanvasFields {
  /// Initialize canvas transform for limited mode (page centering).
  void _initializeCanvasForLimitedMode(
      Size viewportSize, core.Page currentPage) {
    final canvasMode =
        widget.canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (canvasMode.isInfinite) {
      _hasInitialized = true;
      _lastViewportSize = viewportSize;
      _lastPageSize = Size(currentPage.size.width, currentPage.size.height);
      return;
    }

    final pageSize = Size(currentPage.size.width, currentPage.size.height);

    // Check if viewport or page size changed significantly
    final needsReInit = !_hasInitialized ||
        _isOrientationChanged(viewportSize) ||
        _isSignificantHeightChange(viewportSize) ||
        _isPageSizeChanged(pageSize);
    if (!needsReInit) return;

    // Mark as initialized immediately to prevent multiple calls
    _hasInitialized = true;
    _lastViewportSize = viewportSize;
    _lastPageSize = pageSize;

    // Schedule initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(canvasViewportSizeProvider.notifier).state = viewportSize;
      ref.read(canvasTransformProvider.notifier).initializeForPage(
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
          );
    });
  }

  /// Check if orientation changed (width/height swapped).
  bool _isOrientationChanged(Size newSize) {
    final lastSize = _lastViewportSize;
    if (lastSize == null) return false;

    final wasPortrait = lastSize.height > lastSize.width;
    final isPortrait = newSize.height > newSize.width;

    return wasPortrait != isPortrait;
  }

  /// Detect significant viewport height change (keyboard show/hide).
  /// Keyboards are typically > 200px, so 100px threshold avoids false positives.
  bool _isSignificantHeightChange(Size newSize) {
    final lastSize = _lastViewportSize;
    if (lastSize == null) return false;
    return (newSize.height - lastSize.height).abs() > 100;
  }

  /// Detect page size change (paper format or orientation change).
  bool _isPageSizeChanged(Size newPageSize) {
    final last = _lastPageSize;
    if (last == null) return false;
    return (last.width - newPageSize.width).abs() > 1 ||
        (last.height - newPageSize.height).abs() > 1;
  }

  /// Fit-to-screen transform used while the canvas transform is still at its
  /// default state (limited mode only).
  CanvasTransform _effectiveTransform(
    CanvasTransform transform,
    core.CanvasMode canvasMode,
    core.Page currentPage,
    Size size,
  ) {
    // CRITICAL FIX: Use computed transform if still at default state
    // This prevents "small square" bug on first render
    CanvasTransform effectiveTransform = transform;
    if (!canvasMode.isInfinite) {
      final isDefaultTransform =
          transform.zoom == 1.0 && transform.offset == Offset.zero;
      if (isDefaultTransform) {
        // Compute fit-to-screen transform for first frame
        final pageSize = Size(currentPage.size.width, currentPage.size.height);
        final fitWidth = size.width / pageSize.width;
        final fitHeight = size.height / pageSize.height;
        // Use fit-width with padding on narrow (portrait) screens
        final fitZoom = (fitWidth < fitHeight) ? fitWidth * 0.96 : fitHeight;

        final pageScreenWidth = pageSize.width * fitZoom;
        final pageScreenHeight = pageSize.height * fitZoom;
        final offsetX = (size.width - pageScreenWidth) / 2;
        final offsetY = (size.height - pageScreenHeight) / 2;

        effectiveTransform = CanvasTransform(
          zoom: fitZoom,
          offset: Offset(offsetX, offsetY),
          baselineZoom: fitZoom,
        );
      }
    }
    return effectiveTransform;
  }
}
