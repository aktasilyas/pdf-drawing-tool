import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'document_provider.dart';
import 'page_provider.dart';

// =============================================================================
// HISTORY PROVIDER
// =============================================================================

/// HistoryManager instance - manages undo/redo for the entire application.
///
/// This provider wraps the drawing_core HistoryManager and syncs with
/// DocumentProvider for state management.
final historyManagerProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

// =============================================================================
// HISTORY STATE
// =============================================================================

/// History state - tracks undo/redo availability.
class HistoryState {
  /// Whether undo is available.
  final bool canUndo;

  /// Whether redo is available.
  final bool canRedo;

  /// Number of actions that can be undone.
  final int undoCount;

  /// Number of actions that can be redone.
  final int redoCount;

  /// Creates a history state.
  const HistoryState({
    this.canUndo = false,
    this.canRedo = false,
    this.undoCount = 0,
    this.redoCount = 0,
  });

  /// Creates a copy with updated values.
  HistoryState copyWith({
    bool? canUndo,
    bool? canRedo,
    int? undoCount,
    int? redoCount,
  }) {
    return HistoryState(
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      undoCount: undoCount ?? this.undoCount,
      redoCount: redoCount ?? this.redoCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryState &&
        other.canUndo == canUndo &&
        other.canRedo == canRedo &&
        other.undoCount == undoCount &&
        other.redoCount == redoCount;
  }

  @override
  int get hashCode {
    return Object.hash(canUndo, canRedo, undoCount, redoCount);
  }
}

// =============================================================================
// HISTORY NOTIFIER
// =============================================================================

/// State notifier for undo/redo history management.
///
/// Wraps [HistoryManager] from drawing_core and synchronizes with
/// [DocumentProvider] for document state updates.
class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;
  final HistoryManager _historyManager;

  /// Creates a history notifier.
  HistoryNotifier(this._ref)
      : _historyManager = HistoryManager(maxHistorySize: 100),
        super(const HistoryState());

  /// Execute a command and update document.
  ///
  /// This is the main method for executing drawing commands.
  /// It updates both the document and the history state.
  void execute(DrawingCommand command) {
    final document = _ref.read(documentProvider);
    final newDocument = _historyManager.execute(command, document);
    _ref.read(documentProvider.notifier).updateDocument(newDocument);
    _syncPageManager(newDocument);
    _updateState();
  }

  /// Add stroke to active layer (convenience method).
  ///
  /// Creates an [AddStrokeCommand] and executes it.
  /// This enables undo/redo for the stroke addition.
  void addStroke(Stroke stroke, {int? layerIndex}) {
    final document = _ref.read(documentProvider);
    final targetLayer = layerIndex ?? document.activeLayerIndex;

    final command = AddStrokeCommand(
      layerIndex: targetLayer,
      stroke: stroke,
    );
    execute(command);
  }

  /// Remove stroke from active layer (convenience method).
  ///
  /// Creates a [RemoveStrokeCommand] and executes it.
  /// This enables undo/redo for the stroke removal.
  void removeStroke(String strokeId, {int? layerIndex}) {
    final document = _ref.read(documentProvider);
    final targetLayer = layerIndex ?? document.activeLayerIndex;

    final command = RemoveStrokeCommand(
      layerIndex: targetLayer,
      strokeId: strokeId,
    );
    execute(command);
  }

  /// Undo the last action.
  ///
  /// If there's nothing to undo, this method does nothing.
  void undo() {
    if (!_historyManager.canUndo) return;

    final document = _ref.read(documentProvider);
    final newDocument = _historyManager.undo(document);

    if (newDocument != null) {
      _ref.read(documentProvider.notifier).updateDocument(newDocument);
      _syncPageManager(newDocument);
      _updateState();
    }
  }

  /// Redo the last undone action.
  ///
  /// If there's nothing to redo, this method does nothing.
  void redo() {
    if (!_historyManager.canRedo) return;

    final document = _ref.read(documentProvider);
    final newDocument = _historyManager.redo(document);

    if (newDocument != null) {
      _ref.read(documentProvider.notifier).updateDocument(newDocument);
      _syncPageManager(newDocument);
      _updateState();
    }
  }

  /// Clear all history.
  ///
  /// This resets both undo and redo stacks.
  void clearHistory() {
    _historyManager.clear();
    _updateState();
  }

  /// Sync page manager with the latest document state.
  void _syncPageManager(DrawingDocument document) {
    _ref.read(pageManagerProvider.notifier).initializeFromDocument(
      document.pages,
      currentIndex: document.currentPageIndex,
    );
  }

  /// Update state from history manager.
  void _updateState() {
    state = HistoryState(
      canUndo: _historyManager.canUndo,
      canRedo: _historyManager.canRedo,
      undoCount: _historyManager.undoCount,
      redoCount: _historyManager.redoCount,
    );
  }
}

// =============================================================================
// CONVENIENCE PROVIDERS
// =============================================================================

/// Whether undo is available - convenience provider.
///
/// Use this to enable/disable undo buttons.
final canUndoProvider = Provider<bool>((ref) {
  return ref.watch(historyManagerProvider).canUndo;
});

/// Whether redo is available - convenience provider.
///
/// Use this to enable/disable redo buttons.
final canRedoProvider = Provider<bool>((ref) {
  return ref.watch(historyManagerProvider).canRedo;
});

/// Undo count - convenience provider.
final undoCountProvider = Provider<int>((ref) {
  return ref.watch(historyManagerProvider).undoCount;
});

/// Redo count - convenience provider.
final redoCountProvider = Provider<int>((ref) {
  return ref.watch(historyManagerProvider).redoCount;
});
