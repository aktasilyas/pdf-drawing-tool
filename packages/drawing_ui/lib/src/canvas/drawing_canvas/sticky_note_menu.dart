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
        final centerX =
            (sn.x + sn.width / 2) * transform.zoom + transform.offset.dx;
        final screenY = sn.y * transform.zoom + transform.offset.dy - 50;
        return _StickyNoteContextMenu(
          left: centerX,
          top: screenY,
          onDelete: () => _handleStickyNoteDelete(sn),
          onColorChange: (color) => _handleStickyNoteColorChange(sn, color),
        );
      },
    );
  }
}

// =============================================================================
// STICKY NOTE CONTEXT MENU
// =============================================================================

/// Floating context menu for sticky note actions (color change, delete).
class _StickyNoteContextMenu extends StatelessWidget {
  final double left;
  final double top;
  final VoidCallback onDelete;
  final ValueChanged<int> onColorChange;

  static const _noteColors = [
    0xFFFFF3CD, // Yellow
    0xFFF8D7DA, // Pink
    0xFFD1ECF1, // Blue
    0xFFD4EDDA, // Green
    0xFFFFE0CC, // Orange
    0xFFE8D5F5, // Purple
  ];

  const _StickyNoteContextMenu({
    required this.left,
    required this.top,
    required this.onDelete,
    required this.onColorChange,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left - 100,
      top: top,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {},
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color dots row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _noteColors.map((c) => _colorDot(c)).toList(),
                  ),
                ),
                // Delete button
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: _noteColors.length * 28.0 + 12,
                      height: 36,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(ElyanotesIcons.trash,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(context.drawingStrings.selection.delete,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorDot(int colorValue) {
    return GestureDetector(
      onTap: () => onColorChange(colorValue),
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
      ),
    );
  }
}
