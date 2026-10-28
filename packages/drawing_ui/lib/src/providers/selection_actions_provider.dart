import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/models/selection_action.dart';
import 'package:drawing_ui/src/models/selection_action_kind.dart';
import 'package:drawing_ui/src/widgets/selection_screenshot_feedback.dart';
import 'package:drawing_ui/src/providers/ai_callback_provider.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/feature_toggles_provider.dart';
import 'package:drawing_ui/src/providers/selection_capture_actions.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_edit_actions.dart';
import 'package:drawing_ui/src/providers/selection_paste.dart';
import 'package:drawing_ui/src/screens/drawing_screen_layout.dart'
    show openAIPanel;
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

// ============================================================
// ACTION CONFIG BUILDER
// ============================================================

/// Builds the [SelectionActionConfig] for the current selection.
SelectionActionConfig buildSelectionActionConfig(
  WidgetRef ref,
  Selection selection, {
  ImageCacheManager? cacheManager,
  BuildContext? context,
  VoidCallback? onAIPressed,
}) {
  // Resolve AI callback: prefer explicit param, then provider, then fallback
  final aiEnabled = ref.read(aiAssistantEnabledProvider);
  final resolvedAICallback = onAIPressed ??
      ref.read(onAIPressedCallbackProvider) ??
      (context != null ? () => openAIPanel(context) : null);

  void onScreenshot() {
    screenshotSelection(ref, selection, cacheManager, context).then(
      (outcome) {
        if (outcome != null) {
          showSelectionScreenshotFeedback(context, outcome);
        }
      },
    );
  }

  // Empty selection: only AI + Screenshot actions
  if (selection.isEmpty) {
    return SelectionActionConfig(
      toolbarActions: [
        if (aiEnabled)
          SelectionAction(
            id: 'ai',
            icon: ElyanotesIcons.sparkle,
            kind: SelectionActionKind.ai,
            isEnabled: resolvedAICallback != null,
            onExecute: resolvedAICallback != null
                ? () => captureAndOpenAI(
                    ref, selection, cacheManager, resolvedAICallback)
                : null,
          ),
        SelectionAction(
          id: 'screenshot',
          icon: ElyanotesIcons.camera,
          kind: SelectionActionKind.screenshot,
          isEnabled: cacheManager != null,
          onExecute: cacheManager != null ? onScreenshot : null,
        ),
      ],
      topRowActions: const [],
      overflowActions: const [],
    );
  }

  final clipboard = ref.read(selectionClipboardProvider);
  final hasClipboard = clipboard != null;

  // Get color of first selected element for the color indicator
  int selectedColor = 0xFF000000;
  final doc = ref.read(documentProvider);
  final layer = doc.layers[doc.activeLayerIndex];
  bool foundColor = false;
  for (final id in selection.selectedStrokeIds) {
    final s = layer.getStrokeById(id);
    if (s != null) {
      selectedColor = s.style.color;
      foundColor = true;
      break;
    }
  }
  if (!foundColor) {
    for (final id in selection.selectedShapeIds) {
      final i = layer.shapes.indexWhere((s) => s.id == id);
      if (i != -1) {
        selectedColor = layer.shapes[i].style.color;
        foundColor = true;
        break;
      }
    }
  }
  if (!foundColor) {
    for (final id in selection.selectedTextIds) {
      final t = layer.getTextById(id);
      if (t != null) {
        selectedColor = t.color;
        break;
      }
    }
  }

  // ── Toolbar actions (quick bar) ──
  final toolbarActions = <SelectionAction>[
    if (aiEnabled)
      SelectionAction(
        id: 'ai',
        icon: ElyanotesIcons.sparkle,
        kind: SelectionActionKind.ai,
        isEnabled: resolvedAICallback != null,
        onExecute: resolvedAICallback != null
            ? () => captureAndOpenAI(
                ref, selection, cacheManager, resolvedAICallback)
            : null,
      ),
    SelectionAction(
      id: 'color',
      icon: ElyanotesIcons.palette,
      kind: SelectionActionKind.color,
      colorIndicator: selectedColor,
      onExecute: () {},
    ),
    SelectionAction(
      id: 'screenshot',
      icon: ElyanotesIcons.camera,
      kind: SelectionActionKind.screenshot,
      isEnabled: cacheManager != null,
      onExecute: cacheManager != null ? onScreenshot : null,
    ),
    SelectionAction(
      id: 'cut',
      icon: ElyanotesIcons.scissors,
      kind: SelectionActionKind.cut,
      onExecute: () => cutToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'duplicate',
      icon: ElyanotesIcons.duplicate,
      kind: SelectionActionKind.duplicate,
      onExecute: () => duplicateSelection(ref, selection),
    ),
    SelectionAction(
      id: 'delete',
      icon: ElyanotesIcons.trash,
      kind: SelectionActionKind.delete,
      isDestructive: true,
      onExecute: () => deleteSelection(ref, selection),
    ),
  ];

  // ── Top row actions (icon buttons in horizontal row at top of overflow) ──
  final topRowActions = <SelectionAction>[
    SelectionAction(
      id: 'overflow_cut',
      icon: ElyanotesIcons.scissors,
      kind: SelectionActionKind.cut,
      onExecute: () => cutToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_front',
      icon: ElyanotesIcons.bringToFront,
      kind: SelectionActionKind.bringToFront,
      onExecute: () => bringToFront(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_back',
      icon: ElyanotesIcons.sendToBack,
      kind: SelectionActionKind.sendToBack,
      onExecute: () => sendToBack(ref, selection),
    ),
  ];

  // ── Overflow menu list actions (text left, icon right) ──
  final overflowActions = <SelectionAction>[
    SelectionAction(
      id: 'overflow_copy',
      icon: ElyanotesIcons.copy,
      kind: SelectionActionKind.copy,
      onExecute: () => copyToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_duplicate',
      icon: ElyanotesIcons.duplicate,
      kind: SelectionActionKind.duplicate,
      onExecute: () => duplicateSelection(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_paste',
      icon: ElyanotesIcons.paste,
      kind: SelectionActionKind.paste,
      isEnabled: hasClipboard,
      onExecute: hasClipboard ? () => pasteFromClipboard(ref) : null,
    ),
    SelectionAction(
      id: 'overflow_ai',
      icon: ElyanotesIcons.sparkle,
      kind: SelectionActionKind.askAi,
      isEnabled: resolvedAICallback != null,
      onExecute: resolvedAICallback != null
          ? () =>
              captureAndOpenAI(ref, selection, cacheManager, resolvedAICallback)
          : null,
    ),
    SelectionAction(
      id: 'overflow_screenshot',
      icon: ElyanotesIcons.camera,
      kind: SelectionActionKind.takeScreenshot,
      isEnabled: cacheManager != null,
      onExecute: cacheManager != null ? onScreenshot : null,
    ),
    SelectionAction(
      id: 'overflow_delete',
      icon: ElyanotesIcons.trash,
      kind: SelectionActionKind.delete,
      isDestructive: true,
      onExecute: () => deleteSelection(ref, selection),
    ),
  ];

  return SelectionActionConfig(
    toolbarActions: toolbarActions,
    topRowActions: topRowActions,
    overflowActions: overflowActions,
  );
}

/// Convenience: change the color of strokes in a selection.
void executeColorChange(WidgetRef ref, Selection selection, int color) {
  changeColor(ref, selection, color);
}
