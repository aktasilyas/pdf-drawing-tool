import 'package:drawing_core/src/internal.dart';

/// Manages undo/redo history for drawing operations.
///
/// The [HistoryManager] maintains two stacks: one for undo operations
/// and one for redo operations. It enforces a maximum history size
/// to prevent unbounded memory growth.
class HistoryManager {
  /// The stack of commands that can be undone.
  final List<DrawingCommand> _undoStack = [];

  /// The stack of commands that can be redone.
  final List<DrawingCommand> _redoStack = [];

  /// The maximum number of commands to keep in history.
  final int maxHistorySize;

  /// Creates a new [HistoryManager].
  ///
  /// [maxHistorySize] defaults to 100. When exceeded, the oldest
  /// commands are removed to make room for new ones.
  HistoryManager({this.maxHistorySize = 100});

  /// Whether there are commands that can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether there are commands that can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// The number of commands in the undo stack.
  int get undoCount => _undoStack.length;

  /// The number of commands in the redo stack.
  int get redoCount => _redoStack.length;

  /// Executes a command and adds it to the history.
  ///
  /// The command is executed on the given [document], and the result
  /// is returned. The command is added to the undo stack, and the
  /// redo stack is cleared (since a new action invalidates any
  /// previously undone actions).
  ///
  /// If the undo stack exceeds [maxHistorySize], the oldest command
  /// is removed.
  DrawingDocument execute(DrawingCommand command, DrawingDocument document) {
    // Execute the command
    final newDocument = command.execute(document);

    // Add to undo stack
    _undoStack.add(command);

    // Clear redo stack (new action invalidates redo history)
    _redoStack.clear();

    // Enforce max history size
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0); // Remove oldest
    }

    return newDocument;
  }

  /// Undoes the most recent command.
  ///
  /// Returns the document with the last command undone, or null if
  /// there are no commands to undo.
  ///
  /// The undone command is moved to the redo stack.
  DrawingDocument? undo(DrawingDocument document) {
    if (!canUndo) {
      return null;
    }

    // Pop from undo stack
    final command = _undoStack.removeLast();

    // Undo the command
    final newDocument = command.undo(document);

    // Push to redo stack
    _redoStack.add(command);

    return newDocument;
  }

  /// Redoes the most recently undone command.
  ///
  /// Returns the document with the command re-executed, or null if
  /// there are no commands to redo.
  ///
  /// The redone command is moved back to the undo stack.
  DrawingDocument? redo(DrawingDocument document) {
    if (!canRedo) {
      return null;
    }

    // Pop from redo stack
    final command = _redoStack.removeLast();

    // Re-execute the command
    final newDocument = command.execute(document);

    // Push to undo stack
    _undoStack.add(command);

    return newDocument;
  }

  /// Clears all history.
  ///
  /// Both the undo and redo stacks are emptied.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Returns the descriptions of commands in the undo stack.
  ///
  /// The list is ordered from oldest to newest (first item is the
  /// oldest command that can be undone).
  ///
  /// Useful for displaying undo history in the UI.
  List<String> getUndoDescriptions() {
    return _undoStack.map((cmd) => cmd.description).toList();
  }

  /// Returns the descriptions of commands in the redo stack.
  ///
  /// The list is ordered from oldest to newest (first item is the
  /// oldest command that can be redone).
  ///
  /// Useful for displaying redo history in the UI.
  List<String> getRedoDescriptions() {
    return _redoStack.map((cmd) => cmd.description).toList();
  }
}
