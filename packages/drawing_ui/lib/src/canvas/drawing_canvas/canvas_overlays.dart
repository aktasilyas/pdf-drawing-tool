part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Screen-space overlays drawn above the viewport (outside the transform).
mixin _CanvasOverlays
    on
        DrawingCanvasGestureHandlers<DrawingCanvas>,
        _CanvasFields,
        _StickyNoteMenu,
        _PlacementIndicators {
  List<Widget> _buildScreenOverlays(_CanvasFrame f) {
    final selectionUi = f.selectionUi;
    final selection = f.selection;
    final transform = f.transform;
    final textToolState = f.textToolState;
    final isTextTool = f.isTextTool;
    final isEraserTool = f.isEraserTool;
    final eraserCursorPosition = f.eraserCursorPosition;
    final lassoEraserPoints = f.lassoEraserPoints;
    return [
      // ───────────────────────────────────────────────────────────────────
      // Selection Toolbar (floating toolbar with quick actions + overflow)
      // ───────────────────────────────────────────────────────────────────
      if (selectionUi.showMenu && selection != null)
        SelectionToolbar(
          selection: selection,
          cacheManager: _imageCacheManager,
        ),

      // ───────────────────────────────────────────────────────────────────
      // Paste Context Menu (long press on empty canvas)
      // ───────────────────────────────────────────────────────────────────
      Builder(
        builder: (context) {
          final pasteMenu = ref.watch(pasteMenuProvider);
          if (pasteMenu == null) return const SizedBox.shrink();
          return PasteContextMenu(state: pasteMenu);
        },
      ),

      // ───────────────────────────────────────────────────────────────────
      // Sticky Note Context Menu (color picker + delete)
      // ───────────────────────────────────────────────────────────────────
      _buildStickyNoteMenu(f),

      // ───────────────────────────────────────────────────────────────────
      // Text Input Overlay (must be outside gesture handlers)
      // ───────────────────────────────────────────────────────────────────
      if (textToolState.isEditing && textToolState.activeText != null)
        TextInputOverlay(
          textElement: textToolState.activeText!,
          zoom: transform.zoom,
          canvasOffset: transform.offset,
          onTextChanged: (updatedText) {
            ref.read(textToolProvider.notifier).updateText(updatedText);
          },
          onEditingComplete: () => finishTextEditing(),
          onCancel: () => handleTextEmptied(),
        ),

      // ───────────────────────────────────────────────────────────────────
      // Text Style Popup (must be outside gesture handlers)
      // ───────────────────────────────────────────────────────────────────
      if (textToolState.showStylePopup && textToolState.styleText != null)
        TextStylePopup(
          textElement: textToolState.styleText!,
          zoom: transform.zoom,
          canvasOffset: transform.offset,
          onStyleChanged: handleTextStyleChanged,
          onClose: () => ref.read(textToolProvider.notifier).hideStylePopup(),
          stickerMode: !isTextTool,
        ),

      // ───────────────────────────────────────────────────────────────────
      // Sticker Placement Mode Indicator
      // ───────────────────────────────────────────────────────────────────
      _buildStickerIndicator(),

      // ───────────────────────────────────────────────────────────────────
      // Image Placement Mode Indicator
      // ───────────────────────────────────────────────────────────────────
      _buildImageIndicator(),

      // ───────────────────────────────────────────────────────────────────
      // Eraser Cursor Overlay (using screen coordinates)
      // ───────────────────────────────────────────────────────────────────
      if (isEraserTool || eraserCursorPosition != null)
        EraserCursorWidget(
          cursorPosition: eraserCursorPosition ?? Offset.zero,
          isVisible: eraserCursorPosition != null,
          lassoPoints: lassoEraserPoints,
        ),
    ];
  }
}
