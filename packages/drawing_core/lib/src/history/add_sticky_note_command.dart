import 'package:drawing_core/drawing_core.dart';

/// Command for adding a sticky note to a layer.
class AddStickyNoteCommand implements DrawingCommand {
  final int layerIndex;
  final StickyNote stickyNote;

  AddStickyNoteCommand({
    required this.layerIndex,
    required this.stickyNote,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addStickyNote(stickyNote);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final updatedLayer = layer.removeStickyNote(stickyNote.id);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Add sticky note';
}
