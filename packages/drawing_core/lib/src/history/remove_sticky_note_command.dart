import 'package:drawing_core/drawing_core.dart';

/// Command for removing a sticky note from a layer.
class RemoveStickyNoteCommand implements DrawingCommand {
  final int layerIndex;
  final String stickyNoteId;

  StickyNote? _removedNote;

  RemoveStickyNoteCommand({
    required this.layerIndex,
    required this.stickyNoteId,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _removedNote = layer.getStickyNoteById(stickyNoteId);
    final updatedLayer = layer.removeStickyNote(stickyNoteId);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedNote == null) return document;

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.addStickyNote(_removedNote!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Remove sticky note';
}
