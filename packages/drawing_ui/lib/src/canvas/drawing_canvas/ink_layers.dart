part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Wraps [child] with [Opacity] only when opacity < 1.0.
Widget _wrapOpacity(double opacity, Widget child) {
  if (opacity >= 1.0) return child;
  return Opacity(opacity: opacity, child: child);
}

/// Committed active-layer content and the live ink layers above it.
mixin _CanvasInkLayers
    on DrawingCanvasGestureHandlers<DrawingCanvas>, _CanvasFields {
  /// Tiled committed content and sticky notes of the active layer.
  Widget _buildActiveLayerContent(
    _CanvasFrame f,
    Size size,
    CanvasTransform effectiveTransform,
  ) {
    final activeLayerOpacity = f.activeLayerOpacity;
    final currentPage = f.currentPage;
    final activeLayerIndex = f.activeLayerIndex;
    final strokes = f.strokes;
    final shapes = f.shapes;
    final images = f.images;
    final texts = f.texts;
    final elementOrder = f.elementOrder;
    final excludedStrokeIds = f.excludedStrokeIds;
    final excludedShapeIds = f.excludedShapeIds;
    final excludedImageIds = f.excludedImageIds;
    final excludedTextIds = f.excludedTextIds;
    final pixelEraserPreview = f.pixelEraserPreview;
    final strokeEraserPreview = f.strokeEraserPreview;
    final textToolState = f.textToolState;
    final previewShape = f.previewShape;
    final stickyNotes = f.stickyNotes;
    return _wrapOpacity(
        activeLayerOpacity,
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Tiled raster cache of committed content
            Consumer(
              builder: (context, ref, _) => ActiveLayerContent(
                key: ValueKey('${currentPage.id}/$activeLayerIndex'),
                scene: ElementScene(
                  strokes: strokes,
                  shapes: shapes,
                  images: images,
                  texts: texts,
                  elementOrder: elementOrder,
                  excludedIds: {
                    ...excludedStrokeIds,
                    ...excludedShapeIds,
                    ...excludedImageIds,
                    ...excludedTextIds,
                  },
                  pixelEraserPreview: pixelEraserPreview,
                  strokeEraserPreview: strokeEraserPreview,
                ),
                transform: effectiveTransform,
                viewportSize: size,
                isZooming: ref.watch(isZoomingProvider),
                renderer: _renderer,
                cacheManager: _imageCacheManager,
                activeShape: previewShape,
                activeText:
                    textToolState.isEditing ? textToolState.activeText : null,
                selectionColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            // Committed Sticky Notes
            if (stickyNotes.isNotEmpty)
              Consumer(
                builder: (context, ref, _) {
                  final liveNote = ref.watch(
                    stickyNotePlacementProvider.select((s) => s.selectedNote),
                  );
                  return RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: StickyNotePainter(
                        stickyNotes: stickyNotes,
                        renderer: _renderer,
                        overrideNote: liveNote,
                      ),
                      isComplex: true,
                      willChange: liveNote != null,
                    ),
                  );
                },
              ),
          ],
        ));
  }

  /// Active stroke, laser pointer and straight-line preview layers.
  List<Widget> _buildLiveInkLayers(_CanvasFrame f, Size size) {
    final activeLayerVisible = f.activeLayerVisible;
    final activeLayerOpacity = f.activeLayerOpacity;
    final straightLinePreviewPoints = f.straightLinePreviewPoints;
    final straightLinePreviewStyle = f.straightLinePreviewStyle;
    return [
      if (activeLayerVisible)
        _wrapOpacity(
          activeLayerOpacity,
          RepaintBoundary(
            child: ActiveStrokeLayer(
              controller: _drawingController,
              size: size,
            ),
          ),
        ),

      // ─────────────────────────────────────────────────────────
      // LAYER 4.5: Laser Pointer Overlay
      // ─────────────────────────────────────────────────────────
      LaserOverlayWidget(
        controller: _laserController,
        size: size,
      ),

      // ─────────────────────────────────────────────────────────
      // LAYER 5: Straight Line Preview (for highlighter)
      // ─────────────────────────────────────────────────────────
      if (straightLinePreviewPoints != null && straightLinePreviewStyle != null)
        RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: ActiveStrokePainter(
              points: straightLinePreviewPoints,
              style: straightLinePreviewStyle,
              renderer: _renderer,
            ),
            isComplex: false,
            willChange: true,
          ),
        ),
    ];
  }
}
