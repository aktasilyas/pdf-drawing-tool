import '../models/document.dart';

/// Abstract base class for all drawing commands.
///
/// Commands implement the Command pattern for undo/redo functionality.
/// Each command can be executed and undone, returning a new document state.
///
/// Commands should be immutable where possible, though some commands
/// may need to cache state for undo operations.
abstract class DrawingCommand {
  /// Executes this command on the given document.
  ///
  /// Returns a new [DrawingDocument] with the command applied.
  /// The original document is not modified.
  DrawingDocument execute(DrawingDocument document);

  /// Undoes this command on the given document.
  ///
  /// Returns a new [DrawingDocument] with the command reversed.
  /// The original document is not modified.
  DrawingDocument undo(DrawingDocument document);

  /// A human-readable description of this command.
  ///
  /// Useful for debugging and displaying in UI (e.g., undo history).
  String get description;
}
