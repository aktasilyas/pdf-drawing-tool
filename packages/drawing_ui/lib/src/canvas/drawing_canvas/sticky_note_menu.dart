part of 'package:drawing_ui/src/canvas/drawing_canvas.dart';

/// Sticky note context menu actions and builder.
mixin _StickyNoteMenu on DrawingCanvasGestureHandlers<DrawingCanvas> {
  void _handleStickyNoteDelete(core.StickyNote note) {
    final document = ref.read(documentProvider);
    final command = core.RemoveStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      stickyNoteId: note.id,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(stickyNotePlacementProvider.notifier).deselectNote();
  }

  void _handleStickyNoteColorChange(core.StickyNote note, int color) {
    // Start from the document's current note (erase/undo may have changed it).
    final current = ref.read(selectedStickyNoteProvider);
    if (current == null || current.id != note.id) return;
    final updated = current.copyWith(color: color);
    final document = ref.read(documentProvider);
    final command = core.UpdateStickyNoteCommand(
      layerIndex: document.activeLayerIndex,
      newNote: updated,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(stickyNotePlacementProvider.notifier).selectNote(updated);
  }

  Widget _buildStickyNoteMenu(_CanvasFrame f) {
    final transform = f.transform;
    return Builder(
      builder: (context) {
        final noteState = ref.watch(stickyNotePlacementProvider);
        final sn = ref.watch(selectedStickyNoteProvider);
        if (!noteState.showMenu || sn == null) {
          return const SizedBox.shrink();
        }
        final noteRect = Rect.fromLTWH(
          sn.x * transform.zoom + transform.offset.dx,
          sn.y * transform.zoom + transform.offset.dy,
          sn.width * transform.zoom,
          sn.height * transform.zoom,
        );
        return StickyNoteContextMenu(
          noteRect: noteRect,
          selectedColor: sn.color,
          onDelete: () => _handleStickyNoteDelete(sn),
          onColorChange: (color) => _handleStickyNoteColorChange(sn, color),
        );
      },
    );
  }
}
