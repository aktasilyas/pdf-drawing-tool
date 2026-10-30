part of 'package:drawing_ui/src/canvas/drawing_canvas_gesture_handlers.dart';

/// Text tool handlers: create, edit, select and finish text elements.
mixin _TextGestures<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, DrawingCanvasHelpers<T>, _GestureState<T> {
  // ─────────────────────────────────────────────────────────────────────────
  // TEXT EVENT HANDLERS
  // ─────────────────────────────────────────────────────────────────────────

  void handleTextDown(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;

    // Check if there's already active text editing
    final textToolState = ref.read(textToolProvider);

    if (textToolState.isEditing) {
      // Check if tapped on the same text element - if not, finish current and STOP
      final activeText = textToolState.activeText;
      if (activeText != null) {
        // Check if tapped on current active text
        if (activeText.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
          // Same text clicked - do nothing, let TextField handle it
          return;
        }
        // Tapped somewhere else - finish current editing and STOP
        // User needs to tap again to create new text (this closes keyboard)
        finishTextEditing();
        return; // IMPORTANT: Don't create new text on same tap
      }
    }

    // If menu is showing, close it first
    if (textToolState.showMenu) {
      ref.read(textToolProvider.notifier).hideContextMenu();
      return;
    }

    // If style popup is showing, close it first
    if (textToolState.showStylePopup) {
      ref.read(textToolProvider.notifier).hideStylePopup();
      return;
    }

    // Check if tapped on existing text - enter editing directly (text tool)
    final texts = ref.read(activeLayerTextsProvider);

    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        ref.read(textToolProvider.notifier).editExistingText(
              text,
              pageId: ref.read(currentPageProvider).id,
              layerIndex: ref.read(documentProvider).activeLayerIndex,
            );
        return;
      }
    }

    // Create new text at tap location using text settings
    final textSettings = ref.read(textSettingsProvider);
    ref.read(textToolProvider.notifier).startNewText(
          canvasPoint.dx,
          canvasPoint.dy,
          pageId: ref.read(currentPageProvider).id,
          layerIndex: ref.read(documentProvider).activeLayerIndex,
          fontSize: textSettings.fontSize,
          color: textSettings.color,
          isBold: textSettings.isBold,
          isItalic: textSettings.isItalic,
          isUnderline: textSettings.isUnderline,
        );
  }

  /// Commits the text being edited to the page and layer it was started on
  /// (#462), even when the current page changed in the meantime. A new text
  /// on the current page is then selected.
  void finishTextEditing() {
    final actions = ref.read(textToolActionsProvider);
    final textToolState = ref.read(textToolProvider);
    final added = actions.commit();
    // The selection system works on the current page only.
    if (added != null && actions.isOnCurrentPage(textToolState)) {
      _selectText(added);
    }
  }

  /// Ends editing whose content is empty or whitespace only (see
  /// [TextToolActions.endEmptied]).
  void handleTextEmptied() => ref.read(textToolActionsProvider).endEmptied();

  /// Ends text editing when the current page changes, so the text is
  /// committed to the page it was started on and the overlay closes (#462).
  ///
  /// Deferred to a microtask so the page-index sync between PageManager and
  /// the document has finished before the commit.
  void finishTextEditingOnPageChange() {
    if (!ref.read(textToolProvider).isEditing) return;
    Future.microtask(() {
      if (!mounted || !ref.read(textToolProvider).isEditing) return;
      finishTextEditing();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Selects a text element into the main selection system.
  void _selectText(core.TextElement text) {
    final selection = core.Selection.create(
      type: core.SelectionType.rectangle,
      selectedStrokeIds: const [],
      selectedShapeIds: const [],
      selectedImageIds: const [],
      selectedTextIds: [text.id],
      bounds: text.bounds,
    );
    ref.read(selectionProvider.notifier).setSelection(selection);
    ref.read(selectionUiProvider.notifier).showContextMenu();
    ref.read(currentToolProvider.notifier).selectTool(ToolType.selection);
  }

  void handleTextStyleChanged(core.TextElement updatedText) {
    final document = ref.read(documentProvider);
    final command = core.UpdateTextCommand(
      layerIndex: document.activeLayerIndex,
      newText: updatedText,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  /// Selects the topmost text element under the pointer into the main
  /// selection system. Returns true if a text element was hit.
  bool _trySelectTextAt(PointerDownEvent event) {
    final transform = ref.read(canvasTransformProvider);
    final canvasPoint =
        (event.localPosition - transform.offset) / transform.zoom;
    final texts = ref.read(activeLayerTextsProvider);
    for (final text in texts.reversed) {
      if (text.containsPoint(canvasPoint.dx, canvasPoint.dy, 10)) {
        _selectText(text);
        return true;
      }
    }
    return false;
  }
}
