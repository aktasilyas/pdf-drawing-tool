import 'dart:ui' show Offset;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/models/selection_action.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

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

  ref.read(selectionClipboardProvider.notifier).state =
      SelectionClipboardData(
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

void _pasteFromClipboard(WidgetRef ref) {
  final clipboard = ref.read(selectionClipboardProvider);
  if (clipboard == null) return;

  final document = ref.read(documentProvider);
  final layerIndex = document.activeLayerIndex;

  // Add strokes with new IDs and slight offset
  for (final stroke in clipboard.strokes) {
    final movedPoints = stroke.points
        .map((p) => DrawingPoint(
              x: p.x + 40,
              y: p.y + 40,
              pressure: p.pressure,
              tilt: p.tilt,
              timestamp: p.timestamp,
            ))
        .toList();
    final newStroke = Stroke.create(style: stroke.style, points: movedPoints);
    final cmd = AddStrokeCommand(layerIndex: layerIndex, stroke: newStroke);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  for (final shape in clipboard.shapes) {
    final newShape = Shape(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: shape.type,
      startPoint: DrawingPoint(
        x: shape.startPoint.x + 40,
        y: shape.startPoint.y + 40,
        pressure: shape.startPoint.pressure,
      ),
      endPoint: DrawingPoint(
        x: shape.endPoint.x + 40,
        y: shape.endPoint.y + 40,
        pressure: shape.endPoint.pressure,
      ),
      style: shape.style,
      isFilled: shape.isFilled,
      fillColor: shape.fillColor,
    );
    final cmd = AddShapeCommand(layerIndex: layerIndex, shape: newShape);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  for (final image in clipboard.images) {
    final newImage = ImageElement.create(
      filePath: image.filePath,
      x: image.x + 40,
      y: image.y + 40,
      width: image.width,
      height: image.height,
      rotation: image.rotation,
    );
    final cmd = AddImageCommand(layerIndex: layerIndex, imageElement: newImage);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  for (final text in clipboard.texts) {
    final newText = TextElement.create(
      text: text.text,
      x: text.x + 40,
      y: text.y + 40,
      fontSize: text.fontSize,
      color: text.color,
      fontFamily: text.fontFamily,
      isBold: text.isBold,
      isItalic: text.isItalic,
      isUnderline: text.isUnderline,
      alignment: text.alignment,
    );
    final cmd = AddTextCommand(layerIndex: layerIndex, textElement: newText);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  ref.read(selectionUiProvider.notifier).reset();
  ref.read(selectionProvider.notifier).clearSelection();
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
  if (selection.selectedStrokeIds.isEmpty &&
      selection.selectedTextIds.isEmpty) return;
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

// ============================================================
// ACTION CONFIG BUILDER
// ============================================================

/// Builds the [SelectionActionConfig] for the current selection.
SelectionActionConfig buildSelectionActionConfig(
  WidgetRef ref,
  Selection selection,
) {
  final clipboard = ref.read(selectionClipboardProvider);
  final hasClipboard = clipboard != null;

  // Get color of first selected element for the color indicator
  int selectedColor = 0xFF000000;
  final doc = ref.read(documentProvider);
  final layer = doc.layers[doc.activeLayerIndex];
  bool foundColor = false;
  for (final id in selection.selectedStrokeIds) {
    final s = layer.getStrokeById(id);
    if (s != null) { selectedColor = s.style.color; foundColor = true; break; }
  }
  if (!foundColor) {
    for (final id in selection.selectedTextIds) {
      final t = layer.getTextById(id);
      if (t != null) { selectedColor = t.color; break; }
    }
  }

  // ── Toolbar actions (quick bar) ──
  final toolbarActions = <SelectionAction>[
    SelectionAction(
      id: 'ai',
      icon: StarNoteIcons.sparkle,
      label: 'AI Asistan',
      isEnabled: false,
    ),
    SelectionAction(
      id: 'color',
      icon: StarNoteIcons.palette,
      label: 'Renk',
      colorIndicator: selectedColor,
      onExecute: () {},
    ),
    SelectionAction(
      id: 'screenshot',
      icon: StarNoteIcons.camera,
      label: 'Ekran Resmi',
      isEnabled: false,
    ),
    SelectionAction(
      id: 'cut',
      icon: StarNoteIcons.scissors,
      label: 'Kes',
      onExecute: () => _cutToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'duplicate',
      icon: StarNoteIcons.duplicate,
      label: 'Cogalt',
      onExecute: () => _duplicateSelection(ref, selection),
    ),
    SelectionAction(
      id: 'delete',
      icon: StarNoteIcons.trash,
      label: 'Sil',
      isDestructive: true,
      onExecute: () => _deleteSelection(ref, selection),
    ),
  ];

  // ── Top row actions (icon buttons in horizontal row at top of overflow) ──
  final topRowActions = <SelectionAction>[
    SelectionAction(
      id: 'overflow_cut',
      icon: StarNoteIcons.scissors,
      label: 'Kes',
      onExecute: () => _cutToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_front',
      icon: StarNoteIcons.caretUp,
      label: 'Öne Getir',
      onExecute: () => _bringToFront(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_back',
      icon: StarNoteIcons.caretDown,
      label: 'Arkaya Gönder',
      onExecute: () => _sendToBack(ref, selection),
    ),
  ];

  // ── Overflow menu list actions (text left, icon right) ──
  final overflowActions = <SelectionAction>[
    SelectionAction(
      id: 'overflow_copy',
      icon: StarNoteIcons.copy,
      label: 'Kopyala',
      onExecute: () => _copyToClipboard(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_duplicate',
      icon: StarNoteIcons.duplicate,
      label: 'Çoğalt',
      onExecute: () => _duplicateSelection(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_paste',
      icon: StarNoteIcons.paste,
      label: 'Yapıştır',
      isEnabled: hasClipboard,
      onExecute: hasClipboard ? () => _pasteFromClipboard(ref) : null,
    ),
    SelectionAction(
      id: 'overflow_ai',
      icon: StarNoteIcons.sparkle,
      label: 'Yapay zekaya sor',
      isEnabled: false,
    ),
    SelectionAction(
      id: 'overflow_screenshot',
      icon: StarNoteIcons.camera,
      label: 'Ekran Resmi Çek',
      isEnabled: false,
    ),
    SelectionAction(
      id: 'overflow_delete',
      icon: StarNoteIcons.trash,
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

/// Paste clipboard content centered at a specific canvas point.
///
/// Used by the long-press paste context menu to paste at the press location.
void pasteFromClipboardAt(WidgetRef ref, Offset canvasPoint) {
  final clipboard = ref.read(selectionClipboardProvider);
  if (clipboard == null) return;

  final document = ref.read(documentProvider);
  final layerIndex = document.activeLayerIndex;

  // Compute delta from clipboard's original center to target point
  final centerX =
      (clipboard.originalBounds.left + clipboard.originalBounds.right) / 2;
  final centerY =
      (clipboard.originalBounds.top + clipboard.originalBounds.bottom) / 2;
  final dx = canvasPoint.dx - centerX;
  final dy = canvasPoint.dy - centerY;

  for (final stroke in clipboard.strokes) {
    final movedPoints = stroke.points
        .map((p) => DrawingPoint(
              x: p.x + dx,
              y: p.y + dy,
              pressure: p.pressure,
              tilt: p.tilt,
              timestamp: p.timestamp,
            ))
        .toList();
    final newStroke = Stroke.create(style: stroke.style, points: movedPoints);
    final cmd = AddStrokeCommand(layerIndex: layerIndex, stroke: newStroke);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  for (final shape in clipboard.shapes) {
    final newShape = Shape(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: shape.type,
      startPoint: DrawingPoint(
        x: shape.startPoint.x + dx,
        y: shape.startPoint.y + dy,
        pressure: shape.startPoint.pressure,
      ),
      endPoint: DrawingPoint(
        x: shape.endPoint.x + dx,
        y: shape.endPoint.y + dy,
        pressure: shape.endPoint.pressure,
      ),
      style: shape.style,
      isFilled: shape.isFilled,
      fillColor: shape.fillColor,
    );
    final cmd = AddShapeCommand(layerIndex: layerIndex, shape: newShape);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  for (final image in clipboard.images) {
    final newImage = ImageElement.create(
      filePath: image.filePath,
      x: image.x + dx,
      y: image.y + dy,
      width: image.width,
      height: image.height,
      rotation: image.rotation,
    );
    final cmd = AddImageCommand(layerIndex: layerIndex, imageElement: newImage);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  for (final text in clipboard.texts) {
    final newText = TextElement.create(
      text: text.text,
      x: text.x + dx,
      y: text.y + dy,
      fontSize: text.fontSize,
      color: text.color,
      fontFamily: text.fontFamily,
      isBold: text.isBold,
      isItalic: text.isItalic,
      isUnderline: text.isUnderline,
      alignment: text.alignment,
    );
    final cmd = AddTextCommand(layerIndex: layerIndex, textElement: newText);
    ref.read(historyManagerProvider.notifier).execute(cmd);
  }

  ref.read(selectionUiProvider.notifier).reset();
  ref.read(selectionProvider.notifier).clearSelection();
}

/// Convenience: change the color of strokes in a selection.
void executeColorChange(WidgetRef ref, Selection selection, int color) {
  _changeColor(ref, selection, color);
}
