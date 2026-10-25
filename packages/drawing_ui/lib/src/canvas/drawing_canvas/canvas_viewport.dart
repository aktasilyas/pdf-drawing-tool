part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Gesture-handling viewport: pointer listener, scale detector and the
/// zoom/pan transformed layer stack.
mixin _CanvasViewport
    on
        DrawingCanvasGestureHandlers<DrawingCanvas>,
        _CanvasFields,
        _CanvasPageLayers,
        _CanvasInkLayers,
        _CanvasSelectionLayers {
  Widget _buildViewport(
    _CanvasFrame f,
    Size size,
    CanvasTransform effectiveTransform,
  ) {
    final enablePointerEvents = f.enablePointerEvents;
    final canvasMode = f.canvasMode;
    final allLayers = f.allLayers;
    final activeLayerIndex = f.activeLayerIndex;
    final activeLayerVisible = f.activeLayerVisible;
    // Canvas with gesture handlers
    return Listener(
      onPointerDown: enablePointerEvents ? handlePointerDown : null,
      onPointerMove: enablePointerEvents ? handlePointerMove : null,
      onPointerUp: enablePointerEvents ? handlePointerUp : null,
      onPointerCancel: enablePointerEvents ? handlePointerCancel : null,
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        onScaleStart: handleScaleStart,
        onScaleUpdate: handleScaleUpdate,
        onScaleEnd: handleScaleEnd,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          key: ref.read(canvasBoundaryKeyProvider),
          child: ClipRect(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Transform(
                // Apply zoom and pan transformation
                transform: effectiveTransform.matrix,
                alignment: Alignment.topLeft,
                child: Stack(
                  clipBehavior: Clip.none, // Allow content outside bounds
                  children: [
                    // ═══════════════════════════════════════════════════════════
                    // LAYER 0: Page Container (LIMITED mod için)
                    // ═══════════════════════════════════════════════════════════
                    if (!canvasMode.isInfinite) ..._buildPageLayers(f),

                    // ─────────────────────────────────────────────────────────
                    // PASSIVE LAYERS BELOW ACTIVE
                    // ─────────────────────────────────────────────────────────
                    for (int i = 0;
                        i < activeLayerIndex && i < allLayers.length;
                        i++)
                      if (allLayers[i].isVisible)
                        PassiveLayerStack(
                          layer: allLayers[i],
                          renderer: _renderer,
                          imageCacheManager: _imageCacheManager,
                        ),

                    // ─────────────────────────────────────────────────────────
                    // ACTIVE LAYER: Committed content (hidden when !isVisible)
                    // ─────────────────────────────────────────────────────────
                    if (activeLayerVisible)
                      _buildActiveLayerContent(f, size, effectiveTransform),

                    // ─────────────────────────────────────────────────────────
                    // PASSIVE LAYERS ABOVE ACTIVE
                    // ─────────────────────────────────────────────────────────
                    for (int i = activeLayerIndex + 1;
                        i < allLayers.length;
                        i++)
                      if (allLayers[i].isVisible)
                        PassiveLayerStack(
                          layer: allLayers[i],
                          renderer: _renderer,
                          imageCacheManager: _imageCacheManager,
                        ),

                    // ─────────────────────────────────────────────────────────
                    // ACTIVE LAYER: Active Stroke (Live Drawing)
                    // ─────────────────────────────────────────────────────────
                    // Uses ListenableBuilder to listen to DrawingController
                    // for optimal performance during drawing
                    ..._buildLiveInkLayers(f, size),

                    // ─────────────────────────────────────────────────────────
                    // LAYER 6: Selection Overlay
                    // ─────────────────────────────────────────────────────────
                    // Selection path and bounding box
                    ..._buildSelectionLayers(context, f, size),

                    // ─────────────────────────────────────────────────────────
                    // LAYER 9: Sticky Note Resize Handles
                    // ─────────────────────────────────────────────────────────
                    _buildStickyNoteHandlesLayer(f),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
