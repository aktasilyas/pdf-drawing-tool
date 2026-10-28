part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Selection overlay, live-transformed elements and sticky note handles.
mixin _CanvasSelectionLayers
    on DrawingCanvasGestureHandlers<DrawingCanvas>, _CanvasFields {
  /// [context] is the State context; only the theme color scheme is read from it.
  List<Widget> _buildSelectionLayers(
    BuildContext context,
    _CanvasFrame f,
    Size size,
  ) {
    final selection = f.selection;
    final selectionPreviewPath = f.selectionPreviewPath;
    final transform = f.transform;
    final hasLiveTransform = f.hasLiveTransform;
    final selectedStrokes = f.selectedStrokes;
    final selectedShapes = f.selectedShapes;
    final selectedImages = f.selectedImages;
    final selectedTexts = f.selectedTexts;
    final selectionUi = f.selectionUi;
    return [
      RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: SelectionPainter(
            selection: selection,
            selectionColor: Theme.of(context).colorScheme.primary,
            previewPath: selectionPreviewPath,
            zoom: transform.zoom,
            hasLiveTransform: hasLiveTransform,
          ),
          isComplex: false,
          willChange: true,
        ),
      ),

      // ─────────────────────────────────────────────────────────
      // LAYER 7: Selected Elements with Live Transform
      // ─────────────────────────────────────────────────────────
      if (hasLiveTransform && selection != null)
        RepaintBoundary(
          child: CustomPaint(
            size: size,
            painter: SelectedElementsPainter(
              selectedStrokes: selectedStrokes,
              selectedShapes: selectedShapes,
              selectedImages: selectedImages,
              selectedTexts: selectedTexts,
              imageCacheManager: _imageCacheManager,
              moveDelta: selectionUi.moveDelta,
              rotation: selectionUi.rotation,
              scaleX: selectionUi.scaleX,
              scaleY: selectionUi.scaleY,
              centerX: (selection.bounds.left + selection.bounds.right) / 2,
              centerY: (selection.bounds.top + selection.bounds.bottom) / 2,
              renderer: _renderer,
            ),
            isComplex: true,
            willChange: true,
          ),
        ),

      // ─────────────────────────────────────────────────────────
      // LAYER 8: Selection Handles (for drag interactions)
      // ─────────────────────────────────────────────────────────
      if (selection != null && selection.isNotEmpty)
        SelectionHandles(
          selection: selection,
          onSelectionChanged: () => setState(() {}),
        ),
    ];
  }

  Widget _buildStickyNoteHandlesLayer(_CanvasFrame f) {
    final isStickyNoteTool = f.isStickyNoteTool;
    return Builder(
      builder: (context) {
        final noteState = ref.watch(stickyNotePlacementProvider);
        final selected = ref.watch(selectedStickyNoteProvider);
        if (selected == null || noteState.isMoving || selected.minimized) {
          return const SizedBox.shrink();
        }
        // On stickyNote tool: full interactive handles.
        // On other tools: paint-only (visible but no gesture).
        if (isStickyNoteTool) {
          return StickyNoteResizeHandles(note: selected);
        }
        return IgnorePointer(
          child: CustomPaint(
            painter: StickyNoteHandlesPainter(
              note: selected,
              selectionColor: Theme.of(context).colorScheme.primary,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
