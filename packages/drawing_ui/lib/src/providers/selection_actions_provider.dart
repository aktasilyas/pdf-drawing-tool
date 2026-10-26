import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/canvas/image_painter.dart';
import 'package:drawing_ui/src/models/selection_action.dart';
import 'package:drawing_ui/src/providers/ai_callback_provider.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/feature_toggles_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/pdf_render_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:drawing_ui/src/providers/pending_selection_image_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_paste.dart';
import 'package:drawing_ui/src/services/selection_capture_service.dart';
import 'package:drawing_ui/src/screens/drawing_screen_layout.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';
import 'package:drawing_ui/src/widgets/screenshot_preview_dialog.dart';

// ============================================================
// ACTION HELPERS
// ============================================================

void _deleteSelection(WidgetRef ref, Selection selection) {
  final document = ref.read(documentProvider);
  final command = DeleteSelectionCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
    shapeIds: selection.selectedShapeIds,
    imageIds: selection.selectedImageIds,
    textIds: selection.selectedTextIds,
  );
  ref.read(historyManagerProvider.notifier).execute(command);
  ref.read(selectionProvider.notifier).clearSelection();
  ref.read(selectionUiProvider.notifier).reset();
}

void _duplicateSelection(WidgetRef ref, Selection selection) {
  final document = ref.read(documentProvider);
  final command = DuplicateSelectionCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
    shapeIds: selection.selectedShapeIds,
    imageIds: selection.selectedImageIds,
    textIds: selection.selectedTextIds,
  );
  ref.read(historyManagerProvider.notifier).execute(command);
  ref.read(selectionProvider.notifier).clearSelection();
  ref.read(selectionUiProvider.notifier).reset();
}

void _copyToClipboard(WidgetRef ref, Selection selection) {
  final document = ref.read(documentProvider);
  final layer = document.layers[document.activeLayerIndex];

  final strokes = <Stroke>[];
  for (final id in selection.selectedStrokeIds) {
    final s = layer.getStrokeById(id);
    if (s != null) strokes.add(s);
  }

  final shapes = <Shape>[];
  for (final id in selection.selectedShapeIds) {
    final s = layer.getShapeById(id);
    if (s != null) shapes.add(s);
  }

  final images = <ImageElement>[];
  for (final id in selection.selectedImageIds) {
    final i = layer.getImageById(id);
    if (i != null) images.add(i);
  }

  final texts = <TextElement>[];
  for (final id in selection.selectedTextIds) {
    final t = layer.getTextById(id);
    if (t != null) texts.add(t);
  }

  ref.read(selectionClipboardProvider.notifier).state = SelectionClipboardData(
    strokes: strokes,
    shapes: shapes,
    images: images,
    texts: texts,
    originalBounds: selection.bounds,
  );
}

void _cutToClipboard(WidgetRef ref, Selection selection) {
  _copyToClipboard(ref, selection);
  _deleteSelection(ref, selection);
}

void _bringToFront(WidgetRef ref, Selection selection) {
  final document = ref.read(documentProvider);
  final command = ReorderSelectionCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
    shapeIds: selection.selectedShapeIds,
    imageIds: selection.selectedImageIds,
    textIds: selection.selectedTextIds,
    direction: ReorderDirection.bringToFront,
  );
  ref.read(historyManagerProvider.notifier).execute(command);
  ref.read(selectionUiProvider.notifier).hideContextMenu();
}

void _sendToBack(WidgetRef ref, Selection selection) {
  final document = ref.read(documentProvider);
  final command = ReorderSelectionCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
    shapeIds: selection.selectedShapeIds,
    imageIds: selection.selectedImageIds,
    textIds: selection.selectedTextIds,
    direction: ReorderDirection.sendToBack,
  );
  ref.read(historyManagerProvider.notifier).execute(command);
  ref.read(selectionUiProvider.notifier).hideContextMenu();
}

void _changeColor(WidgetRef ref, Selection selection, int color) {
  if (selection.selectedStrokeIds.isEmpty && selection.selectedTextIds.isEmpty)
    return;
  final document = ref.read(documentProvider);
  final command = ChangeSelectionStyleCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
    textIds: selection.selectedTextIds,
    newColor: color,
  );
  ref.read(historyManagerProvider.notifier).execute(command);
  ref.read(selectionUiProvider.notifier).hideContextMenu();
}

Future<void> _screenshotSelection(
  WidgetRef ref,
  Selection selection,
  ImageCacheManager? cacheManager,
  BuildContext? context,
) async {
  if (cacheManager == null) return;

  try {
    final document = ref.read(documentProvider);
    final layer = document.layers[document.activeLayerIndex];

    // Get current page background and size for screenshot rendering
    final currentPage = document.currentPage;
    final background = currentPage?.background;
    final pageSz = currentPage != null
        ? Size(currentPage.size.width, currentPage.size.height)
        : null;

    // Get PDF image bytes from cache if PDF background
    Uint8List? pdfImageBytes;
    if (background?.type == BackgroundType.pdf) {
      if (background!.pdfData != null) {
        pdfImageBytes = background.pdfData;
      } else if (background.pdfFilePath != null &&
          background.pdfPageIndex != null) {
        final cacheKey = '${background.pdfFilePath}|${background.pdfPageIndex}';
        final cache = ref.read(pdfPageCacheProvider);
        pdfImageBytes = cache[cacheKey];
      }
    }

    final bytes = await SelectionCaptureService.captureSelection(
      selection: selection,
      layer: layer,
      cacheManager: cacheManager,
      background: background,
      pdfImageBytes: pdfImageBytes,
      pageSize: pageSz,
    );
    if (bytes == null) {
      _showSnackBar(context, 'Ekran resmi oluşturulamadı');
      return;
    }

    if (context == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ScreenshotPreviewDialog(bytes: bytes),
    );
    if (confirmed != true) return;

    final gallerySaved = await SelectionCaptureService.saveToGallery(bytes);
    final clipboardCopied =
        await SelectionCaptureService.copyToClipboard(bytes);

    String msg;
    if (gallerySaved && clipboardCopied) {
      msg = 'Ekran resmi galeriye kaydedildi ve panoya kopyalandı';
    } else if (gallerySaved) {
      msg = 'Ekran resmi galeriye kaydedildi';
    } else if (clipboardCopied) {
      msg = 'Ekran resmi panoya kopyalandı';
    } else {
      msg = 'Ekran resmi kaydedilemedi';
    }
    _showSnackBar(context, msg);
  } catch (e) {
    debugPrint('Screenshot selection failed: $e');
    _showSnackBar(context, 'Ekran resmi oluşturulamadı');
  }
}

Future<void> _captureAndOpenAI(
  WidgetRef ref,
  Selection selection,
  ImageCacheManager? cacheManager,
  VoidCallback aiCallback,
) async {
  // Skip capture only when no cache or zero-area bounds (Selection.empty()).
  // Non-empty bounds should be captured even without selected elements,
  // so the user can ask AI about the selected canvas area.
  final hasBounds = selection.bounds.width > 0 && selection.bounds.height > 0;
  if (cacheManager == null || !hasBounds) {
    aiCallback();
    return;
  }

  // Read everything from ref BEFORE the async gap to avoid stale WidgetRef.
  final document = ref.read(documentProvider);
  final pendingNotifier = ref.read(pendingSelectionImageProvider.notifier);

  try {
    final layer = document.layers[document.activeLayerIndex];

    final currentPage = document.currentPage;
    final background = currentPage?.background;
    final pageSz = currentPage != null
        ? Size(currentPage.size.width, currentPage.size.height)
        : null;

    Uint8List? pdfImageBytes;
    if (background?.type == BackgroundType.pdf) {
      if (background!.pdfData != null) {
        pdfImageBytes = background.pdfData;
      } else if (background.pdfFilePath != null &&
          background.pdfPageIndex != null) {
        final cacheKey = '${background.pdfFilePath}|${background.pdfPageIndex}';
        final cache = ref.read(pdfPageCacheProvider);
        pdfImageBytes = cache[cacheKey];
      }
    }

    final bytes = await SelectionCaptureService.captureSelection(
      selection: selection,
      layer: layer,
      cacheManager: cacheManager,
      background: background,
      pdfImageBytes: pdfImageBytes,
      pageSize: pageSz,
    );

    if (bytes != null) {
      pendingNotifier.state = bytes;
    }
  } catch (e) {
    debugPrint('Capture for AI failed: $e');
  }

  aiCallback();
}

void _showSnackBar(BuildContext? context, String message) {
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}

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

  // Empty selection: only AI + Screenshot actions
  if (selection.isEmpty) {
    return SelectionActionConfig(
      toolbarActions: [
        if (aiEnabled)
          SelectionAction(
            id: 'ai',
            icon: ElyanotesIcons.sparkle,
            label: 'AI Asistan',
            isEnabled: resolvedAICallback != null,
            onExecute: resolvedAICallback != null
                ? () => _captureAndOpenAI(
                    ref, selection, cacheManager, resolvedAICallback)
                : null,
          ),
        SelectionAction(
          id: 'screenshot',
          icon: ElyanotesIcons.camera,
          label: 'Ekran Resmi',
          isEnabled: cacheManager != null,
          onExecute: cacheManager != null
              ? () =>
                  _screenshotSelection(ref, selection, cacheManager, context)
              : null,
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
        label: 'AI Asistan',
        isEnabled: resolvedAICallback != null,
        onExecute: resolvedAICallback != null
            ? () => _captureAndOpenAI(
                ref, selection, cacheManager, resolvedAICallback)
            : null,
      ),
    SelectionAction(
      id: 'color',
      icon: ElyanotesIcons.palette,
      label: 'Renk',
      colorIndicator: selectedColor,
      onExecute: () {},
    ),
    SelectionAction(
      id: 'screenshot',
      icon: ElyanotesIcons.camera,
      label: 'Ekran Resmi',
      isEnabled: cacheManager != null,
      onExecute: cacheManager != null
          ? () => _screenshotSelection(ref, selection, cacheManager, context)
          : null,
    ),
    SelectionAction(
      id: 'cut',
      icon: ElyanotesIcons.scissors,
      label: 'Kes',
      onExecute: () => _cutToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'duplicate',
      icon: ElyanotesIcons.duplicate,
      label: 'Cogalt',
      onExecute: () => _duplicateSelection(ref, selection),
    ),
    SelectionAction(
      id: 'delete',
      icon: ElyanotesIcons.trash,
      label: 'Sil',
      isDestructive: true,
      onExecute: () => _deleteSelection(ref, selection),
    ),
  ];

  // ── Top row actions (icon buttons in horizontal row at top of overflow) ──
  final topRowActions = <SelectionAction>[
    SelectionAction(
      id: 'overflow_cut',
      icon: ElyanotesIcons.scissors,
      label: 'Kes',
      onExecute: () => _cutToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_front',
      icon: ElyanotesIcons.bringToFront,
      label: 'Öne Getir',
      onExecute: () => _bringToFront(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_back',
      icon: ElyanotesIcons.sendToBack,
      label: 'Arkaya Gönder',
      onExecute: () => _sendToBack(ref, selection),
    ),
  ];

  // ── Overflow menu list actions (text left, icon right) ──
  final overflowActions = <SelectionAction>[
    SelectionAction(
      id: 'overflow_copy',
      icon: ElyanotesIcons.copy,
      label: 'Kopyala',
      onExecute: () => _copyToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_duplicate',
      icon: ElyanotesIcons.duplicate,
      label: 'Çoğalt',
      onExecute: () => _duplicateSelection(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_paste',
      icon: ElyanotesIcons.paste,
      label: 'Yapıştır',
      isEnabled: hasClipboard,
      onExecute: hasClipboard ? () => pasteFromClipboard(ref) : null,
    ),
    SelectionAction(
      id: 'overflow_ai',
      icon: ElyanotesIcons.sparkle,
      label: 'Yapay zekaya sor',
      isEnabled: resolvedAICallback != null,
      onExecute: resolvedAICallback != null
          ? () => _captureAndOpenAI(
              ref, selection, cacheManager, resolvedAICallback)
          : null,
    ),
    SelectionAction(
      id: 'overflow_screenshot',
      icon: ElyanotesIcons.camera,
      label: 'Ekran Resmi Çek',
      isEnabled: cacheManager != null,
      onExecute: cacheManager != null
          ? () => _screenshotSelection(ref, selection, cacheManager, context)
          : null,
    ),
    SelectionAction(
      id: 'overflow_delete',
      icon: ElyanotesIcons.trash,
      label: 'Sil',
      isDestructive: true,
      onExecute: () => _deleteSelection(ref, selection),
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
  _changeColor(ref, selection, color);
}
