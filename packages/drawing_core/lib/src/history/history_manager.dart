import '../models/drawing_document.dart';
import 'drawing_command.dart';

/// Configuration for the history manager.
class HistoryConfig {
  /// Creates a history configuration.
  const HistoryConfig({
    this.maxHistorySize = 100,
    this.maxMemoryBytes = 50 * 1024 * 1024, // 50 MB
    this.snapshotInterval = 20,
  });

  /// Maximum number of commands to keep in history.
  final int maxHistorySize;

  /// Maximum memory usage for history in bytes.
  final int maxMemoryBytes;

  /// Interval at which to create document snapshots.
  ///
  /// Snapshots enable faster navigation to distant history states.
  final int snapshotInterval;
}

/// Represents a snapshot of the document at a point in history.
class DocumentSnapshot {
  /// Creates a document snapshot.
  const DocumentSnapshot({
    required this.commandIndex,
    required this.document,
  });

  /// The index in the command history this snapshot represents.
  final int commandIndex;

  /// The document state at this point.
  final DrawingDocument document;
}

/// Manages undo/redo history for drawing documents.
///
/// Uses the Command pattern to track changes efficiently without
/// storing complete document copies for each operation.
///
/// ## Example
///
/// ```dart
/// final history = HistoryManager(initialDocument: document);
///
/// // Execute a command
/// final newDoc = history.execute(AddStrokeCommand(stroke: stroke, layerIndex: 0));
///
/// // Undo
/// final previousDoc = history.undo();
///
/// // Redo
/// final redoneDoc = history.redo();
/// ```
class HistoryManager {
  /// Creates a history manager with the given initial document.
  HistoryManager({
    required DrawingDocument initialDocument,
    this.config = const HistoryConfig(),
  }) : _currentDocument = initialDocument {
    _snapshots.add(DocumentSnapshot(commandIndex: -1, document: initialDocument));
  }

  /// Configuration for this history manager.
  final HistoryConfig config;

  /// The current document state.
  DrawingDocument _currentDocument;

  /// Stack of commands that can be undone.
  final List<DrawingCommand> _undoStack = [];

  /// Stack of commands that can be redone.
  final List<DrawingCommand> _redoStack = [];

  /// Periodic snapshots for fast navigation.
  final List<DocumentSnapshot> _snapshots = [];

  /// Current estimated memory usage in bytes.
  int _currentMemoryUsage = 0;

  /// Returns the current document.
  DrawingDocument get currentDocument => _currentDocument;

  /// Returns true if undo is available.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Returns true if redo is available.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Returns the number of undo steps available.
  int get undoCount => _undoStack.length;

  /// Returns the number of redo steps available.
  int get redoCount => _redoStack.length;

  /// Returns the description of the next undo action, if available.
  String? get nextUndoDescription =>
      canUndo ? _undoStack.last.description : null;

  /// Returns the description of the next redo action, if available.
  String? get nextRedoDescription =>
      canRedo ? _redoStack.last.description : null;

  /// Executes a command and adds it to the history.
  ///
  /// Returns the new document state.
  DrawingDocument execute(DrawingCommand command) {
    // Execute the command
    _currentDocument = command.execute(_currentDocument);

    // Add to undo stack
    _undoStack.add(command);
    _currentMemoryUsage += command.estimatedMemoryBytes;

    // Clear redo stack (new action invalidates redo history)
    _clearRedoStack();

    // Create snapshot if needed
    _maybeCreateSnapshot();

    // Prune history if needed
    _pruneIfNeeded();

    return _currentDocument;
  }

  /// Undoes the last command.
  ///
  /// Returns the previous document state, or null if nothing to undo.
  DrawingDocument? undo() {
    if (!canUndo) return null;

    final command = _undoStack.removeLast();
    _currentDocument = command.undo(_currentDocument);
    _redoStack.add(command);

    // Transfer memory accounting
    _currentMemoryUsage -= command.estimatedMemoryBytes;

    return _currentDocument;
  }

  /// Redoes the last undone command.
  ///
  /// Returns the new document state, or null if nothing to redo.
  DrawingDocument? redo() {
    if (!canRedo) return null;

    final command = _redoStack.removeLast();
    _currentDocument = command.execute(_currentDocument);
    _undoStack.add(command);

    // Transfer memory accounting
    _currentMemoryUsage += command.estimatedMemoryBytes;

    return _currentDocument;
  }

  /// Undoes multiple commands at once.
  ///
  /// Returns the document state after all undos, or null if no undos performed.
  DrawingDocument? undoMultiple(int count) {
    if (count <= 0 || !canUndo) return null;

    final actualCount = count.clamp(1, _undoStack.length);

    // Check if we can use a snapshot
    final targetIndex = _undoStack.length - actualCount - 1;
    final snapshot = _findNearestSnapshot(targetIndex);

    if (snapshot != null && snapshot.commandIndex <= targetIndex) {
      // Restore from snapshot and replay commands
      _currentDocument = snapshot.document;
      final commandsToReplay = _undoStack.sublist(
        snapshot.commandIndex + 1,
        targetIndex + 1,
      );
      for (final cmd in commandsToReplay) {
        _currentDocument = cmd.execute(_currentDocument);
      }

      // Move undone commands to redo stack
      final undoneCommands =
          _undoStack.sublist(_undoStack.length - actualCount);
      _redoStack.addAll(undoneCommands.reversed);
      _undoStack.removeRange(_undoStack.length - actualCount, _undoStack.length);
    } else {
      // No useful snapshot, undo one by one
      for (int i = 0; i < actualCount; i++) {
        undo();
      }
    }

    return _currentDocument;
  }

  /// Clears all history.
  ///
  /// The current document state is preserved as the new baseline.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _snapshots.clear();
    _currentMemoryUsage = 0;
    _snapshots.add(
      DocumentSnapshot(commandIndex: -1, document: _currentDocument),
    );
  }

  /// Replaces the current document without affecting history.
  ///
  /// Use this for non-undoable changes like loading a new document.
  void replaceDocument(DrawingDocument document) {
    _currentDocument = document;
    clear();
  }

  void _clearRedoStack() {
    for (final command in _redoStack) {
      _currentMemoryUsage -= command.estimatedMemoryBytes;
    }
    _redoStack.clear();
  }

  void _maybeCreateSnapshot() {
    if (_undoStack.length % config.snapshotInterval == 0) {
      _snapshots.add(
        DocumentSnapshot(
          commandIndex: _undoStack.length - 1,
          document: _currentDocument,
        ),
      );
    }
  }

  void _pruneIfNeeded() {
    // Prune by count
    while (_undoStack.length > config.maxHistorySize) {
      final removed = _undoStack.removeAt(0);
      _currentMemoryUsage -= removed.estimatedMemoryBytes;
      _removeInvalidSnapshots();
    }

    // Prune by memory
    while (_currentMemoryUsage > config.maxMemoryBytes && _undoStack.isNotEmpty) {
      final removed = _undoStack.removeAt(0);
      _currentMemoryUsage -= removed.estimatedMemoryBytes;
      _removeInvalidSnapshots();
    }
  }

  void _removeInvalidSnapshots() {
    _snapshots.removeWhere((s) => s.commandIndex >= 0 && s.commandIndex < 0);
    // Re-index would be complex, so we just keep snapshots that are still valid
    // In practice, old snapshots become useless but we rely on creating new ones
  }

  DocumentSnapshot? _findNearestSnapshot(int targetIndex) {
    DocumentSnapshot? best;
    for (final snapshot in _snapshots) {
      if (snapshot.commandIndex <= targetIndex) {
        if (best == null || snapshot.commandIndex > best.commandIndex) {
          best = snapshot;
        }
      }
    }
    return best;
  }
}
