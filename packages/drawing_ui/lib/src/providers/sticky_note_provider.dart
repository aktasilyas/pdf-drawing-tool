import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';
import 'package:drawing_ui/src/providers/page_provider.dart';

/// State for sticky note selection and context menu.
///
/// Only the selected note's **id** is stored; the note itself is always read
/// from the document via [selectedStickyNoteProvider], so erase, undo and
/// redo are reflected at once. [dragPreview] holds the in-flight geometry of
/// a move/resize drag until it is committed.
class StickyNotePlacementState {
  /// Id of the selected sticky note (for resize handles + context menu).
  final String? selectedNoteId;

  /// Uncommitted note geometry while a move/resize drag is in progress.
  final StickyNote? dragPreview;

  /// Whether the context menu is visible for the selected note.
  final bool showMenu;

  /// Whether move mode is active.
  final bool isMoving;

  const StickyNotePlacementState({
    this.selectedNoteId,
    this.dragPreview,
    this.showMenu = false,
    this.isMoving = false,
  });
}

/// Notifier for sticky note placement state.
class StickyNotePlacementNotifier
    extends StateNotifier<StickyNotePlacementState> {
  StickyNotePlacementNotifier() : super(const StickyNotePlacementState());

  /// Select a sticky note (shows handles only, no context menu).
  void selectNote(StickyNote note) {
    state = StickyNotePlacementState(selectedNoteId: note.id);
  }

  /// Show context menu for the selected note.
  void showContextMenu() {
    state = StickyNotePlacementState(
      selectedNoteId: state.selectedNoteId,
      showMenu: true,
    );
  }

  /// Hide context menu but keep note selected (handles remain).
  void hideContextMenu() {
    state = StickyNotePlacementState(selectedNoteId: state.selectedNoteId);
  }

  /// Deselect note entirely (clears handles + menu).
  void deselectNote() {
    state = const StickyNotePlacementState();
  }

  /// Shows [note] as the uncommitted geometry of a move/resize drag.
  void updateDragPreview(StickyNote note) {
    state = StickyNotePlacementState(
      selectedNoteId: note.id,
      dragPreview: note,
    );
  }

  /// Drops the drag preview (after the drag was committed or abandoned).
  void clearDragPreview() {
    if (state.dragPreview == null) return;
    state = StickyNotePlacementState(selectedNoteId: state.selectedNoteId);
  }

  /// Start moving the given note.
  void startMoving(StickyNote note) {
    state = StickyNotePlacementState(
      selectedNoteId: note.id,
      isMoving: true,
    );
  }

  /// Cancel moving.
  void cancelMoving() {
    state = const StickyNotePlacementState();
  }
}

/// Provider for sticky note placement state.
///
/// A page or active-layer change deselects the note.
final stickyNotePlacementProvider = StateNotifierProvider<
    StickyNotePlacementNotifier, StickyNotePlacementState>(
  (ref) {
    final notifier = StickyNotePlacementNotifier();
    void deselect(Object? previous, Object? next) {
      if (previous != next) notifier.deselectNote();
    }

    ref.listen(currentPageIndexProvider, deselect);
    ref.listen(documentProvider.select((d) => d.currentPageIndex), deselect);
    ref.listen(documentProvider.select((d) => d.activeLayerIndex), deselect);
    return notifier;
  },
);

/// Reactive list of sticky notes in the active layer.
final activeLayerStickyNotesProvider = Provider<List<StickyNote>>((ref) {
  final document = ref.watch(documentProvider);
  if (document.layers.isEmpty) return [];
  return document.layers[document.activeLayerIndex].stickyNotes;
});

/// The selected sticky note as it is now: the drag preview while a
/// move/resize is in flight, otherwise the note in the document. `null` when
/// nothing is selected or the note is no longer in the active layer.
final selectedStickyNoteProvider = Provider<StickyNote?>((ref) {
  final placement = ref.watch(stickyNotePlacementProvider);
  final id = placement.selectedNoteId;
  if (id == null) return null;
  StickyNote? current;
  for (final note in ref.watch(activeLayerStickyNotesProvider)) {
    if (note.id == id) {
      current = note;
      break;
    }
  }
  if (current == null) return null;
  return placement.dragPreview ?? current;
});
