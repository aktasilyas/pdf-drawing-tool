part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Two-finger zoom/pan/page-swipe handlers.
mixin _ScaleGestures<T extends ConsumerStatefulWidget>
    on
        ConsumerState<T>,
        DrawingCanvasHelpers<T>,
        _GestureState<T>,
        _PointerKindGate<T>,
        _TextGestures<T>,
        _EraserGestures<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // SCALE GESTURE HANDLERS (Two Finger Zoom/Pan)
  // ─────────────────────────────────────────────────────────────────────────

  void handleScaleStart(ScaleStartDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2 || isStylusActive) return;

    // Show zoom indicator
    ref.read(isZoomingProvider.notifier).state = true;

    // Cancel any ongoing operations when zoom/pan starts
    if (drawingController.isDrawing) {
      drawingController.cancelStroke();
    }
    if (isLaserDrawing) {
      laserController.cancelStroke();
      isLaserDrawing = false;
    }
    if (_eraserSessionActive) {
      handleEraserCancel();
    }
    if (isSelecting) {
      ref.read(activeSelectionToolProvider).cancelSelection();
      isSelecting = false;
    }
    // Reset selection UI state (hide menu, cancel live transform)
    ref.read(selectionUiProvider.notifier).reset();
    if (isDrawingShape) {
      activeShapeTool?.cancelShape();
      activeShapeTool = null;
      isDrawingShape = false;
    }

    // Finish text editing if active (save the text)
    final textToolState = ref.read(textToolProvider);
    if (textToolState.isEditing) {
      finishTextEditing();
    }

    lastFocalPoint = details.localFocalPoint;
    lastScale = 1.0;
    scaleStartFocalPoint = details.localFocalPoint;
    scaleGestureIsZoom = false;
    _swipeDragActive = false;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    // Only handle zoom/pan with 2+ fingers
    if (details.pointerCount < 2 || isStylusActive) return;
    if (!mounted) return;

    final transformNotifier = ref.read(canvasTransformProvider.notifier);
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);
    final currentPage = ref.read(currentPageProvider);

    // Get viewport size from context
    final renderBox = context.findRenderObject() as RenderBox?;
    final viewportSize = renderBox?.size ?? const Size(800, 600);

    // Gesture classification: zoom vs swipe.
    // Zoom: fingers move apart/together but focal point stays ~stationary.
    // Swipe: fingers move together, focal point travels far.
    if (!scaleGestureIsZoom && !mode.isInfinite && onPageSwipe != null) {
      // When zoomed in beyond baseline, two-finger gestures should always
      // pan/zoom the canvas — never trigger page swipe.
      final currentTransform = ref.read(canvasTransformProvider);
      final isZoomedIn =
          currentTransform.zoom > currentTransform.baselineZoom * 1.05;
      if (isZoomedIn) {
        scaleGestureIsZoom = true;
      } else {
        final scaleChange = (details.scale - 1.0).abs();
        final displacement = scaleStartFocalPoint != null
            ? (details.localFocalPoint - scaleStartFocalPoint!).distance
            : 0.0;
        if (scaleChange > 0.30) {
          scaleGestureIsZoom = true;
        } else if (scaleChange > 0.12 && displacement < 30) {
          scaleGestureIsZoom = true;
        }
      }
      // If reclassified as zoom while drag was active, cancel it
      if (scaleGestureIsZoom && _swipeDragActive) {
        onPageSwipeDragEnd?.call(0);
        _swipeDragActive = false;
      }
    }

    // When swipe mode: feed interactive drag deltas to PageSlideTransition
    final suppressZoom =
        !mode.isInfinite && onPageSwipe != null && !scaleGestureIsZoom;
    if (suppressZoom &&
        onPageSwipeDragUpdate != null &&
        lastFocalPoint != null) {
      final scrollDir = ref.read(scrollDirectionProvider);
      final isHoriz = scrollDir == Axis.horizontal;
      final panDelta = details.localFocalPoint - lastFocalPoint!;
      final primaryDelta = isHoriz ? panDelta.dx : panDelta.dy;
      if (!_swipeDragActive) {
        final displacement = scaleStartFocalPoint != null
            ? (details.localFocalPoint - scaleStartFocalPoint!).distance
            : 0.0;
        if (displacement > 10) {
          _swipeDragActive = true;
          onPageSwipeDragBegin?.call();
        }
      }
      if (_swipeDragActive) {
        onPageSwipeDragUpdate!(primaryDelta);
      }
      lastFocalPoint = details.localFocalPoint;
      lastScale = details.scale;
      return;
    }

    // Apply zoom (pinch gesture) — skip if zoom is locked or gesture is swipe
    final isZoomLocked = ref.read(zoomLockedProvider);
    if (!isZoomLocked &&
        !suppressZoom &&
        lastScale != null &&
        details.scale != 1.0) {
      final scaleDelta = details.scale / lastScale!;
      if ((scaleDelta - 1.0).abs() > 0.001) {
        if (mode.isInfinite) {
          transformNotifier.applyZoomDelta(
            scaleDelta,
            details.localFocalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
          );
        } else {
          transformNotifier.applyZoomDeltaClamped(
            scaleDelta,
            details.localFocalPoint,
            minZoom: mode.minZoom,
            maxZoom: mode.maxZoom,
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
            unlimitedPan: mode.unlimitedPan,
          );
        }
      }
    }

    // Apply pan (two finger drag)
    if (lastFocalPoint != null) {
      final panDelta = details.localFocalPoint - lastFocalPoint!;
      if (panDelta.distance > 0.5) {
        if (mode.isInfinite || mode.unlimitedPan) {
          transformNotifier.applyPanDelta(panDelta);
        } else {
          transformNotifier.applyPanDeltaClamped(
            panDelta,
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
            unlimitedPan: mode.unlimitedPan,
          );
        }
      }
    }

    lastFocalPoint = details.localFocalPoint;
    lastScale = details.scale;
  }

  void handleScaleEnd(ScaleEndDetails details) {
    if (!mounted) return;
    // Hide zoom indicator
    ref.read(isZoomingProvider.notifier).state = false;

    // Zoom değişimini provider'a bildir (for adaptive PDF quality)
    final currentTransform = ref.read(canvasTransformProvider);
    final currentZoom = currentTransform.zoom;
    final page = ref.read(currentPageProvider);

    if (page.background.type == BackgroundType.pdf &&
        page.background.pdfFilePath != null &&
        page.background.pdfPageIndex != null) {
      final cacheKey =
          '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
      ref
          .read(zoomBasedRenderProvider.notifier)
          .onZoomChanged(currentZoom, cacheKey);
    }

    // End interactive swipe drag if active
    final mode = canvasMode ?? const core.CanvasMode(isInfinite: true);
    if (_swipeDragActive) {
      final scrollDir = ref.read(scrollDirectionProvider);
      final isHoriz = scrollDir == Axis.horizontal;
      final vel = details.velocity.pixelsPerSecond;
      final primaryVel = isHoriz ? vel.dx : vel.dy;
      onPageSwipeDragEnd?.call(primaryVel);
      _swipeDragActive = false;
      lastFocalPoint = null;
      lastScale = null;
      scaleStartFocalPoint = null;
      return;
    }

    // Fallback: detect two-finger swipe (for cases without interactive drag)
    if (!mode.isInfinite && onPageSwipe != null && !scaleGestureIsZoom) {
      final swipeDir = _detectPageSwipe(details.velocity);
      if (swipeDir != 0) {
        onPageSwipe!(swipeDir);
        lastFocalPoint = null;
        lastScale = null;
        scaleStartFocalPoint = null;
        return;
      }
    }

    // Snap back for limited canvas mode
    if (!mode.isInfinite && !mode.unlimitedPan) {
      final currentPage = ref.read(currentPageProvider);
      final renderBox = context.findRenderObject() as RenderBox?;
      final viewportSize = renderBox?.size ?? const Size(800, 600);

      ref.read(canvasTransformProvider.notifier).snapBackForPage(
            viewportSize: viewportSize,
            pageSize: Size(currentPage.size.width, currentPage.size.height),
          );
    }

    lastFocalPoint = null;
    lastScale = null;
    scaleStartFocalPoint = null;
  }

  /// Detects a two-finger horizontal/vertical swipe gesture.
  /// Called only when gesture was NOT classified as zoom (scaleGestureIsZoom == false).
  /// Returns +1 (next page), -1 (previous page), or 0 (no swipe).
  int _detectPageSwipe(Velocity velocity) {
    final startPoint = scaleStartFocalPoint;
    final endPoint = lastFocalPoint;

    // Need valid tracking data
    if (startPoint == null || endPoint == null) return 0;

    final scrollDir = ref.read(scrollDirectionProvider);
    final isHorizontal = scrollDir == Axis.horizontal;

    // Check displacement from start
    final displacement = endPoint - startPoint;
    final primaryDisplacement =
        isHorizontal ? displacement.dx : displacement.dy;
    final crossDisplacement = isHorizontal ? displacement.dy : displacement.dx;

    // Minimum displacement along primary axis
    if (primaryDisplacement.abs() < 30) return 0;

    // Primary axis must dominate cross axis (loose ratio for natural swipes)
    if (crossDisplacement.abs() > 0 &&
        primaryDisplacement.abs() < crossDisplacement.abs() * 1.2) {
      return 0;
    }

    // Negative displacement = swiped toward next page
    return primaryDisplacement < 0 ? 1 : -1;
  }
}
