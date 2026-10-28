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
        ref.read(textToolProvider.notifier).editExistingText(text);
        return;
      }
    }

    // Create new text at tap location using text settings
    final textSettings = ref.read(textSettingsProvider);
    ref.read(textToolProvider.notifier).startNewText(
          canvasPoint.dx,
          canvasPoint.dy,
          fontSize: textSettings.fontSize,
          color: textSettings.color,
          isBold: textSettings.isBold,
          isItalic: textSettings.isItalic,
          isUnderline: textSettings.isUnderline,
        );
  }

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

    final document = ref.read(documentProvider);

    if (textToolState.isNewText) {
      // Add new text
      final command = core.AddTextCommand(
        layerIndex: document.activeLayerIndex,
        textElement: currentText,
      );
      ref.read(historyManagerProvider.notifier).execute(command);

      // Auto-select into selection system
      _selectText(currentText);
    } else {
      // Update existing text
      final command = core.UpdateTextCommand(
        layerIndex: document.activeLayerIndex,
        newText: currentText,
      );
      ref.read(historyManagerProvider.notifier).execute(command);
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

    final document = ref.read(documentProvider);
    final exists =
        ref.read(activeLayerTextsProvider).any((t) => t.id == currentText.id);
    if (!exists) return;
    ref.read(historyManagerProvider.notifier).execute(
          core.RemoveTextCommand(
            layerIndex: document.activeLayerIndex,
            textId: currentText.id,
          ),
        );
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
