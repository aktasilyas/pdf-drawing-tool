import 'dart:ui' show Offset;

import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/history_provider.dart';
import 'package:drawing_ui/src/providers/selection_clipboard_provider.dart';
import 'package:drawing_ui/src/providers/selection_provider.dart';

/// Offset of a plain paste from the copied elements, in canvas units.
const double kPasteOffset = 40;

/// One undoable command that adds copies of [clipboard], moved by
/// ([dx], [dy]), to layer [layerIndex]. Every copy gets a fresh, unique id.
/// Returns null when the clipboard holds nothing.
CompositeCommand? buildPasteCommand(
  SelectionClipboardData clipboard,
  int layerIndex,
  double dx,
  double dy,
) {
  final commands = <DrawingCommand>[
    for (final stroke in clipboard.strokes)
      AddStrokeCommand(
        layerIndex: layerIndex,
        stroke: Stroke.create(
          style: stroke.style,
          points: [for (final p in stroke.points) _moved(p, dx, dy)],
        ),
      ),
    for (final shape in clipboard.shapes)
      AddShapeCommand(
        layerIndex: layerIndex,
        shape: Shape(
          id: ElementIds.next(),
          type: shape.type,
          startPoint: _moved(shape.startPoint, dx, dy),
          endPoint: _moved(shape.endPoint, dx, dy),
          style: shape.style,
          isFilled: shape.isFilled,
          fillColor: shape.fillColor,
        ),
      ),
    for (final image in clipboard.images)
      AddImageCommand(
        layerIndex: layerIndex,
        imageElement: ImageElement.create(
          filePath: image.filePath,
          x: image.x + dx,
          y: image.y + dy,
          width: image.width,
          height: image.height,
          rotation: image.rotation,
        ),
      ),
    for (final text in clipboard.texts)
      AddTextCommand(
        layerIndex: layerIndex,
        textElement: TextElement.create(
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
          width: text.width,
          height: text.height,
          rotation: text.rotation,
        ),
      ),
  ];
  if (commands.isEmpty) return null;
  return CompositeCommand(commands, description: 'Paste');
}

DrawingPoint _moved(DrawingPoint p, double dx, double dy) => DrawingPoint(
      x: p.x + dx,
      y: p.y + dy,
      pressure: p.pressure,
      tilt: p.tilt,
      timestamp: p.timestamp,
    );

/// Pastes the clipboard moved by ([dx], [dy]) as one undo step.
void pasteClipboard(WidgetRef ref, double dx, double dy) {
  final clipboard = ref.read(selectionClipboardProvider);
  if (clipboard == null) return;

  final layerIndex = ref.read(documentProvider).activeLayerIndex;
  final command = buildPasteCommand(clipboard, layerIndex, dx, dy);
  if (command != null) {
    ref.read(historyManagerProvider.notifier).execute(command);
  }

  ref.read(selectionUiProvider.notifier).reset();
  ref.read(selectionProvider.notifier).clearSelection();
}

/// Pastes the clipboard [kPasteOffset] below-right of the copied elements.
void pasteFromClipboard(WidgetRef ref) =>
    pasteClipboard(ref, kPasteOffset, kPasteOffset);

/// Pastes the clipboard centred at [canvasPoint] (long-press paste menu).
void pasteFromClipboardAt(WidgetRef ref, Offset canvasPoint) {
  final clipboard = ref.read(selectionClipboardProvider);
  if (clipboard == null) return;

  final bounds = clipboard.originalBounds;
  final dx = canvasPoint.dx - (bounds.left + bounds.right) / 2;
  final dy = canvasPoint.dy - (bounds.top + bounds.bottom) / 2;
  pasteClipboard(ref, dx, dy);
}
