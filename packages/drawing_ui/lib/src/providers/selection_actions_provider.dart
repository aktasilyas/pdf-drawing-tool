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

  ref.read(selectionClipboardProvider.notifier).state =
      SelectionClipboardData(
    strokes: strokes,
    shapes: shapes,
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

  ref.read(selectionUiProvider.notifier).reset();
  ref.read(selectionProvider.notifier).clearSelection();
}

void _bringToFront(WidgetRef ref, Selection selection) {
  final document = ref.read(documentProvider);
  final command = ReorderSelectionCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
    shapeIds: selection.selectedShapeIds,
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
    direction: ReorderDirection.sendToBack,
  );
  ref.read(historyManagerProvider.notifier).execute(command);
  ref.read(selectionUiProvider.notifier).hideContextMenu();
}

void _changeColor(WidgetRef ref, Selection selection, int color) {
  if (selection.selectedStrokeIds.isEmpty) return;
  final document = ref.read(documentProvider);
  final command = ChangeSelectionStyleCommand(
    layerIndex: document.activeLayerIndex,
    strokeIds: selection.selectedStrokeIds,
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

  // Get color of first selected stroke for the color indicator
  int selectedColor = 0xFF000000;
  final doc = ref.read(documentProvider);
  final layer = doc.layers[doc.activeLayerIndex];
  for (final id in selection.selectedStrokeIds) {
    final s = layer.getStrokeById(id);
    if (s != null) { selectedColor = s.style.color; break; }
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
      label: 'Ön',
      onExecute: () => _bringToFront(ref, selection),
    ),
    SelectionAction(
      id: 'overflow_back',
      icon: StarNoteIcons.caretDown,
      label: 'Arka',
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

/// Convenience: change the color of strokes in a selection.
void executeColorChange(WidgetRef ref, Selection selection, int color) {
  _changeColor(ref, selection, color);
}
