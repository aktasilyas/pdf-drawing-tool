import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';

/// Manages the current selection state.
///
/// Provides methods to set, clear, and update selections.
class SelectionNotifier extends StateNotifier<Selection?> {
  SelectionNotifier() : super(null);

  /// Sets the current selection.
  void setSelection(Selection? selection) {
    state = selection;
  }

  /// Clears the current selection.
  void clearSelection() {
    state = null;
  }

  /// Updates the selection bounds (for move preview).
  void updateBounds(BoundingBox newBounds) {
    if (state != null) {
      state = state!.copyWith(bounds: newBounds);
    }
  }

  /// Updates the selected stroke IDs.
  void updateStrokeIds(List<String> strokeIds) {
    if (state != null) {
      state = state!.copyWith(selectedStrokeIds: strokeIds);
    }
  }
}

/// The current selection state.
///
/// Returns null if nothing is selected.
final selectionProvider =
    StateNotifierProvider<SelectionNotifier, Selection?>((ref) {
  return SelectionNotifier();
});

/// Whether there is an active selection.
final hasSelectionProvider = Provider<bool>((ref) {
  return ref.watch(selectionProvider) != null;
});

/// Number of selected elements.
final selectionCountProvider = Provider<int>((ref) {
  return ref.watch(selectionProvider)?.count ?? 0;
});

/// The bounding box of the current selection.
final selectionBoundsProvider = Provider<BoundingBox?>((ref) {
  return ref.watch(selectionProvider)?.bounds;
});

/// IDs of currently selected strokes.
final selectedStrokeIdsProvider = Provider<List<String>>((ref) {
  return ref.watch(selectionProvider)?.selectedStrokeIds ?? [];
});

/// The active selection tool type (lasso or rectangle).
/// Default matches LassoSettings.defaultSettings() which is freeform (lasso).
final activeSelectionToolTypeProvider = StateProvider<SelectionType>((ref) {
  return SelectionType.lasso; // Default to lasso (matches LassoMode.freeform)
});

/// Lasso selection tool instance.
final lassoSelectionToolProvider = Provider<LassoSelectionTool>((ref) {
  return LassoSelectionTool();
});

/// Rectangle selection tool instance.
final rectSelectionToolProvider = Provider<RectSelectionTool>((ref) {
  return RectSelectionTool();
});

/// The currently active selection tool.
///
/// Returns either lasso or rectangle tool based on [activeSelectionToolTypeProvider].
final activeSelectionToolProvider = Provider<SelectionTool>((ref) {
  final type = ref.watch(activeSelectionToolTypeProvider);

  switch (type) {
    case SelectionType.lasso:
      return ref.watch(lassoSelectionToolProvider);
    case SelectionType.rectangle:
      return ref.watch(rectSelectionToolProvider);
  }
});

// ============================================================
// SELECTION UI STATE (live move, rotation, context menu)
// ============================================================

/// UI-layer state for live selection feedback and context menu.
class SelectionUiState {
  /// Live drag offset (reset on commit).
  final Offset moveDelta;

  /// Live rotation angle in radians (reset on commit).
  final double rotation;

  /// Whether the context menu is visible.
  final bool showMenu;

  const SelectionUiState({
    this.moveDelta = Offset.zero,
    this.rotation = 0.0,
    this.showMenu = false,
  });

  /// Whether any live transform is active.
  bool get hasTransform => moveDelta != Offset.zero || rotation != 0.0;

  SelectionUiState copyWith({
    Offset? moveDelta,
    double? rotation,
    bool? showMenu,
  }) {
    return SelectionUiState(
      moveDelta: moveDelta ?? this.moveDelta,
      rotation: rotation ?? this.rotation,
      showMenu: showMenu ?? this.showMenu,
    );
  }
}

/// Notifier for selection UI state.
class SelectionUiNotifier extends StateNotifier<SelectionUiState> {
  SelectionUiNotifier() : super(const SelectionUiState());

  void setMoveDelta(Offset delta) {
    state = state.copyWith(moveDelta: delta, showMenu: false);
  }

  void setRotation(double angle) {
    state = state.copyWith(rotation: angle, showMenu: false);
  }

  void showContextMenu() {
    state = state.copyWith(showMenu: true);
  }

  void hideContextMenu() {
    state = state.copyWith(showMenu: false);
  }

  void reset() {
    state = const SelectionUiState();
  }
}

/// Provider for selection UI state (live move, rotation, context menu).
final selectionUiProvider =
    StateNotifierProvider<SelectionUiNotifier, SelectionUiState>((ref) {
  return SelectionUiNotifier();
});
