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
  /// (#462), even when the current page changed in the meantime.
  void finishTextEditing() {
    final textToolState = ref.read(textToolProvider);

    // IMPORTANT: Get the current text state BEFORE calling finishEditing
    // because finishEditing clears the state
    final currentText = textToolState.activeText;

    if (currentText == null || currentText.text.trim().isEmpty) {
      handleTextEmptied();
      return;
    }

    // Now finish editing (this clears the state)
    ref.read(textToolProvider.notifier).finishEditing();

    final layerIndex = _originLayerIndex(textToolState);
    final pageId = textToolState.originPageId;
    final history = ref.read(historyManagerProvider.notifier);

    if (textToolState.isNewText) {
      history.execute(
        core.AddTextCommand(layerIndex: layerIndex, textElement: currentText),
        pageId: pageId,
      );
      // The selection system works on the current page only.
      if (_isOnCurrentPage(textToolState)) _selectText(currentText);
    } else {
      history.execute(
        core.UpdateTextCommand(layerIndex: layerIndex, newText: currentText),
        pageId: pageId,
      );
    }
  }

  /// Ends editing whose content is empty or whitespace only.
  ///
  /// A new text creates nothing. An existing text is removed with one
  /// [core.RemoveTextCommand], so undo brings the original text back.
  void handleTextEmptied() {
    final textToolState = ref.read(textToolProvider);
    final currentText = textToolState.activeText;
    ref.read(textToolProvider.notifier).cancelEditing();
    if (currentText == null || textToolState.isNewText) return;

    final exists =
        _originLayerTexts(textToolState).any((t) => t.id == currentText.id);
    if (!exists) return;
    ref.read(historyManagerProvider.notifier).execute(
          core.RemoveTextCommand(
            layerIndex: _originLayerIndex(textToolState),
            textId: currentText.id,
          ),
          pageId: textToolState.originPageId,
        );
  }

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

  int _originLayerIndex(TextToolState s) =>
      s.originLayerIndex ?? ref.read(documentProvider).activeLayerIndex;

  bool _isOnCurrentPage(TextToolState s) =>
      s.originPageId == null ||
      s.originPageId == ref.read(currentPageProvider).id;

  /// Texts of the layer the edited text was started on.
  List<core.TextElement> _originLayerTexts(TextToolState s) {
    final document = ref.read(documentProvider);
    final pageId = s.originPageId;
    if (pageId == null || !document.isMultiPage) {
      return ref.read(activeLayerTextsProvider);
    }
    final index = document.pages.indexWhere((p) => p.id == pageId);
    if (index < 0) return const [];
    final layers = document.pages[index].layers;
    final layerIndex = _originLayerIndex(s);
    if (layerIndex < 0 || layerIndex >= layers.length) return const [];
    return layers[layerIndex].texts;
  }

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
