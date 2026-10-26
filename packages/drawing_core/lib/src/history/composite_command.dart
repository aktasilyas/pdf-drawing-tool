import 'package:drawing_core/src/internal.dart';

/// Runs several commands as one undo step.
///
/// [execute] applies [commands] in order; [undo] reverts them in reverse
/// order, so commands that cache state during execute (for example
/// [UpdateStickyNoteCommand]) restore it correctly.
class CompositeCommand implements DrawingCommand {
  /// The commands, in execution order.
  final List<DrawingCommand> commands;

  final String _description;

  CompositeCommand(List<DrawingCommand> commands, {String? description})
      : commands = List.unmodifiable(commands),
        _description = description ?? 'Group (${commands.length})';

  @override
  DrawingDocument execute(DrawingDocument document) {
    var doc = document;
    for (final command in commands) {
      doc = command.execute(doc);
    }
    return doc;
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var doc = document;
    for (final command in commands.reversed) {
      doc = command.undo(doc);
    }
    return doc;
  }

  @override
  String get description => _description;
}
