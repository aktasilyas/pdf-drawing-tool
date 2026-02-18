import 'package:drawing_core/drawing_core.dart';

/// Command for updating a sticky note in a layer.
class UpdateStickyNoteCommand implements DrawingCommand {
  final int layerIndex;
  final StickyNote newNote;

  StickyNote? _oldNote;

  UpdateStickyNoteCommand({
    required this.layerIndex,
    required this.newNote,
  });

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    _oldNote = layer.getStickyNoteById(newNote.id);
    final updatedLayer = layer.updateStickyNote(newNote);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_oldNote == null) return document;

    final layer = document.layers[layerIndex];
    final updatedLayer = layer.updateStickyNote(_oldNote!);
    return document.updateLayer(layerIndex, updatedLayer);
  }

  @override
  String get description => 'Update sticky note';
}
