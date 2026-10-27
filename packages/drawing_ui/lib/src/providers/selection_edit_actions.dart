import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';

// Selection edit actions: each mutating action is exactly one history command.

void deleteSelection(WidgetRef ref, Selection selection) {
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

void duplicateSelection(WidgetRef ref, Selection selection) {
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

void copyToClipboard(WidgetRef ref, Selection selection) {
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

void cutToClipboard(WidgetRef ref, Selection selection) {
  copyToClipboard(ref, selection);
  deleteSelection(ref, selection);
}

void bringToFront(WidgetRef ref, Selection selection) {
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

void sendToBack(WidgetRef ref, Selection selection) {
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

void changeColor(WidgetRef ref, Selection selection, int color) {
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
