import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/providers/document_provider.dart';

/// State for sticky note selection and context menu.
class StickyNotePlacementState {
  /// Currently selected sticky note (for resize handles + context menu).
  final StickyNote? selectedNote;

  /// Whether the context menu is visible for the selected note.
  final bool showMenu;

  /// Whether move mode is active.
  final bool isMoving;

  const StickyNotePlacementState({
    this.selectedNote,
    this.showMenu = false,
    this.isMoving = false,
  });
}

/// Notifier for sticky note placement state.
class StickyNotePlacementNotifier
    extends StateNotifier<StickyNotePlacementState> {
  StickyNotePlacementNotifier()
      : super(const StickyNotePlacementState());

  /// Select a sticky note (shows handles only, no context menu).
  void selectNote(StickyNote note) {
    state = StickyNotePlacementState(selectedNote: note);
  }

  /// Show context menu for the selected note.
  void showContextMenu() {
    state = StickyNotePlacementState(
      selectedNote: state.selectedNote,
      showMenu: true,
    );
  }

  /// Hide context menu but keep note selected (handles remain).
  void hideContextMenu() {
    state = StickyNotePlacementState(selectedNote: state.selectedNote);
  }

  /// Deselect note entirely (clears handles + menu).
  void deselectNote() {
    state = const StickyNotePlacementState();
  }

  /// Update the selected note (e.g. after resize/move).
  void updateSelectedNote(StickyNote note) {
    state = StickyNotePlacementState(selectedNote: note);
  }

  /// Start moving the given note.
  void startMoving(StickyNote note) {
    state = StickyNotePlacementState(
      selectedNote: note,
      isMoving: true,
    );
  }

  /// Cancel moving.
  void cancelMoving() {
    state = const StickyNotePlacementState();
  }
}

/// Provider for sticky note placement state.
final stickyNotePlacementProvider = StateNotifierProvider<
    StickyNotePlacementNotifier, StickyNotePlacementState>(
  (ref) => StickyNotePlacementNotifier(),
);

/// Reactive list of sticky notes in the active layer.
final activeLayerStickyNotesProvider = Provider<List<StickyNote>>((ref) {
  final document = ref.watch(documentProvider);
  if (document.layers.isEmpty) return [];
  return document.layers[document.activeLayerIndex].stickyNotes;
});
