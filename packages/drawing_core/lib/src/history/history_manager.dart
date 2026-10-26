import 'package:drawing_core/src/internal.dart';

/// Manages undo/redo history for drawing operations.
///
/// The [HistoryManager] maintains two stacks: one for undo operations
/// and one for redo operations. It enforces a maximum history size
/// to prevent unbounded memory growth.
///
/// Every entry remembers the id of the page that was current when the command
/// ran. Undo and redo apply the command to that page and navigate to it, so a
/// step is never applied to (or consumed on) a different page.
class HistoryManager {
  /// The stack of commands that can be undone.
  final List<_Entry> _undoStack = [];

  /// The stack of commands that can be redone.
  final List<_Entry> _redoStack = [];

  /// The maximum number of commands to keep in history.
  final int maxHistorySize;

  /// Commands executed since [beginGroup], recorded as one step at
  /// [endGroup]. Null when no group is open.
  List<DrawingCommand>? _group;
  String? _groupPageId;
  int _groupDepth = 0;

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
  ///
  /// [pageId] runs the command on that page of a multi-page document
  /// instead of the current one; the current page stays the same. An unknown
  /// [pageId] returns [document] unchanged and records nothing.
  DrawingDocument execute(
    DrawingCommand command,
    DrawingDocument document, {
    String? pageId,
  }) {
    final DrawingDocument newDocument;
    final String? entryPageId;
    if (pageId != null && document.isMultiPage) {
      final index = document.pages.indexWhere((p) => p.id == pageId);
      if (index < 0) return document;
      final target = document.copyWith(currentPageIndex: index);
      final changed = command.execute(target);
      newDocument = changed.copyWith(
        currentPageIndex: document.currentPageIndex,
      );
      entryPageId = pageId;
    } else {
      newDocument = command.execute(document);
      entryPageId = _currentPageId(document);
    }

    // Clear redo stack (new action invalidates redo history)
    _redoStack.clear();

    final group = _group;
    if (group != null) {
      if (group.isEmpty) _groupPageId = entryPageId;
      group.add(command);
    } else {
      _push(_Entry(command, entryPageId));
    }

    return newDocument;
  }

  /// Whether a group opened by [beginGroup] is collecting commands.
  bool get isGrouping => _group != null;

  /// Starts collecting executed commands into one undo step.
  ///
  /// Commands still run immediately in [execute], so callers can read the
  /// updated document between them. [endGroup] records them as a single
  /// [CompositeCommand]. Groups may nest; only the outermost [endGroup]
  /// records the step.
  void beginGroup() {
    _groupDepth++;
    _group ??= [];
  }

  /// Ends the group started by [beginGroup].
  ///
  /// Records the collected commands as one undo step on the page of the
  /// first command. An empty group records nothing, and a group of one
  /// command records that command as is.
  void endGroup({String? description}) {
    if (_groupDepth == 0) return;
    _groupDepth--;
    if (_groupDepth > 0) return;
    final group = _group!;
    _group = null;
    if (group.isEmpty) return;
    final command = group.length == 1
        ? group.single
        : CompositeCommand(group, description: description);
    _push(_Entry(command, _groupPageId));
    _groupPageId = null;
  }

  void _push(_Entry entry) {
    _undoStack.add(entry);
    // Enforce max history size
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0); // Remove oldest
    }
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
    final entry = _undoStack.removeLast();

    // Undo the command on the page it was recorded on
    final target = _onPage(document, entry.pageId);
    final newDocument = target == null ? document : entry.command.undo(target);

    // Push to redo stack
    _redoStack.add(entry);

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
    final entry = _redoStack.removeLast();

    // Re-execute the command on the page it was recorded on
    final target = _onPage(document, entry.pageId);
    final newDocument =
        target == null ? document : entry.command.execute(target);

    // Push to undo stack
    _undoStack.add(entry);

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
    return _undoStack.map((e) => e.command.description).toList();
  }

  /// Returns the descriptions of commands in the redo stack.
  ///
  /// The list is ordered from oldest to newest (first item is the
  /// oldest command that can be redone).
  ///
  /// Useful for displaying redo history in the UI.
  List<String> getRedoDescriptions() {
    return _redoStack.map((e) => e.command.description).toList();
  }

  /// The id of the current page, or null for single-page (V1) documents.
  static String? _currentPageId(DrawingDocument document) =>
      document.isMultiPage ? document.currentPage?.id : null;

  /// Returns [document] with the page [pageId] made current, or null when the
  /// page no longer exists (the step is then consumed without any change).
  static DrawingDocument? _onPage(DrawingDocument document, String? pageId) {
    if (pageId == null || !document.isMultiPage) return document;
    final index = document.pages.indexWhere((p) => p.id == pageId);
    if (index < 0) return null;
    if (index == document.currentPageIndex) return document;
    return document.setCurrentPage(index);
  }
}

class _Entry {
  final DrawingCommand command;
  final String? pageId;

  const _Entry(this.command, this.pageId);
}
