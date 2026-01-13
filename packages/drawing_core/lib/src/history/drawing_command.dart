import '../models/drawing_document.dart';
import '../models/layer.dart';
import '../models/stroke.dart';

/// Base interface for all drawing commands.
///
/// Commands encapsulate operations on a [DrawingDocument] that can be
/// executed and undone. This enables efficient undo/redo without
/// storing complete document copies.
///
/// ## Example
///
/// ```dart
/// class AddStrokeCommand extends DrawingCommand {
///   final Stroke stroke;
///   final int layerIndex;
///
///   @override
///   DrawingDocument execute(DrawingDocument document) {
///     return document.addStrokeToLayer(layerIndex, stroke);
///   }
///
///   @override
///   DrawingDocument undo(DrawingDocument document) {
///     final layer = document.layers[layerIndex];
///     return document.updateLayer(layerIndex, layer.removeLastStroke());
///   }
/// }
/// ```
abstract class DrawingCommand {
  /// A human-readable description of this command.
  String get description;

  /// Executes this command and returns the updated document.
  DrawingDocument execute(DrawingDocument document);

  /// Undoes this command and returns the previous document state.
  DrawingDocument undo(DrawingDocument document);

  /// Estimated memory footprint of this command in bytes.
  ///
  /// Used for memory management and history pruning.
  int get estimatedMemoryBytes => 0;

  /// Whether this command can be merged with [other].
  ///
  /// Used to combine rapid successive commands (e.g., many small edits).
  bool canMergeWith(DrawingCommand other) => false;

  /// Merges this command with [other] and returns the combined command.
  ///
  /// Only called if [canMergeWith] returns true.
  DrawingCommand mergeWith(DrawingCommand other) {
    throw UnsupportedError('Cannot merge commands');
  }
}

/// Command to add a stroke to a layer.
class AddStrokeCommand extends DrawingCommand {
  /// Creates a command to add a stroke.
  AddStrokeCommand({
    required this.stroke,
    required this.layerIndex,
  });

  /// The stroke to add.
  final Stroke stroke;

  /// The index of the layer to add the stroke to.
  final int layerIndex;

  @override
  String get description => 'Add stroke';

  @override
  DrawingDocument execute(DrawingDocument document) {
    return document.addStrokeToLayer(layerIndex, stroke);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    return document.updateLayer(layerIndex, layer.removeLastStroke());
  }

  @override
  int get estimatedMemoryBytes {
    // Rough estimate: 24 bytes per point (x, y, pressure, tilt, timestamp)
    // Plus stroke overhead
    return stroke.points.length * 24 + 100;
  }
}

/// Command to remove a stroke from a layer.
class RemoveStrokeCommand extends DrawingCommand {
  /// Creates a command to remove a stroke.
  RemoveStrokeCommand({
    required this.stroke,
    required this.layerIndex,
    required this.strokeIndex,
  });

  /// The stroke being removed (needed for undo).
  final Stroke stroke;

  /// The index of the layer containing the stroke.
  final int layerIndex;

  /// The index of the stroke within the layer.
  final int strokeIndex;

  @override
  String get description => 'Remove stroke';

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    return document.updateLayer(layerIndex, layer.removeStrokeAt(strokeIndex));
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    final newStrokes = List<Stroke>.from(layer.strokes)
      ..insert(strokeIndex, stroke);
    return document.updateLayer(layerIndex, layer.copyWith(strokes: newStrokes));
  }

  @override
  int get estimatedMemoryBytes {
    return stroke.points.length * 24 + 100;
  }
}

/// Command to remove multiple strokes.
class RemoveStrokesCommand extends DrawingCommand {
  /// Creates a command to remove multiple strokes.
  RemoveStrokesCommand({
    required this.removedStrokes,
  });

  /// Map of layer index to list of (stroke index, stroke) pairs.
  final Map<int, List<(int, Stroke)>> removedStrokes;

  @override
  String get description => 'Remove strokes';

  @override
  DrawingDocument execute(DrawingDocument document) {
    var doc = document;
    // Remove in reverse order to preserve indices
    for (final entry in removedStrokes.entries) {
      final layerIndex = entry.key;
      final strokePairs = entry.value..sort((a, b) => b.$1.compareTo(a.$1));
      for (final (strokeIndex, _) in strokePairs) {
        final layer = doc.layers[layerIndex];
        doc = doc.updateLayer(layerIndex, layer.removeStrokeAt(strokeIndex));
      }
    }
    return doc;
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    var doc = document;
    // Re-add in forward order
    for (final entry in removedStrokes.entries) {
      final layerIndex = entry.key;
      final strokePairs = entry.value..sort((a, b) => a.$1.compareTo(b.$1));
      for (final (strokeIndex, stroke) in strokePairs) {
        final layer = doc.layers[layerIndex];
        final newStrokes = List<Stroke>.from(layer.strokes)
          ..insert(strokeIndex, stroke);
        doc = doc.updateLayer(layerIndex, layer.copyWith(strokes: newStrokes));
      }
    }
    return doc;
  }

  @override
  int get estimatedMemoryBytes {
    int total = 0;
    for (final pairs in removedStrokes.values) {
      for (final (_, stroke) in pairs) {
        total += stroke.points.length * 24 + 100;
      }
    }
    return total;
  }
}

/// Command to add a new layer.
class AddLayerCommand extends DrawingCommand {
  /// Creates a command to add a layer.
  AddLayerCommand({
    required this.layer,
    this.atIndex,
  });

  /// The layer to add.
  final Layer layer;

  /// The index to insert at (null = end).
  final int? atIndex;

  /// The actual index where the layer was inserted.
  int? _insertedIndex;

  @override
  String get description => 'Add layer';

  @override
  DrawingDocument execute(DrawingDocument document) {
    final newLayers = List<Layer>.from(document.layers);
    final index = atIndex ?? newLayers.length;
    newLayers.insert(index, layer);
    _insertedIndex = index;
    return document.copyWith(
      layers: newLayers,
      activeLayerIndex: index,
    );
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    final index = _insertedIndex ?? document.layers.length - 1;
    final newLayers = List<Layer>.from(document.layers)..removeAt(index);
    return document.copyWith(
      layers: newLayers,
      activeLayerIndex:
          document.activeLayerIndex.clamp(0, newLayers.length - 1),
    );
  }
}

/// Command to remove a layer.
class RemoveLayerCommand extends DrawingCommand {
  /// Creates a command to remove a layer.
  RemoveLayerCommand({
    required this.layerIndex,
  });

  /// The index of the layer to remove.
  final int layerIndex;

  /// The removed layer (captured on execute for undo).
  Layer? _removedLayer;

  /// The active layer index before removal.
  int? _previousActiveIndex;

  @override
  String get description => 'Remove layer';

  @override
  DrawingDocument execute(DrawingDocument document) {
    _removedLayer = document.layers[layerIndex];
    _previousActiveIndex = document.activeLayerIndex;

    final newLayers = List<Layer>.from(document.layers)..removeAt(layerIndex);
    final newActiveIndex =
        document.activeLayerIndex.clamp(0, newLayers.length - 1);

    return document.copyWith(
      layers: newLayers,
      activeLayerIndex: newActiveIndex,
    );
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    if (_removedLayer == null) {
      throw StateError('Cannot undo: layer not captured');
    }

    final newLayers = List<Layer>.from(document.layers)
      ..insert(layerIndex, _removedLayer!);

    return document.copyWith(
      layers: newLayers,
      activeLayerIndex: _previousActiveIndex ?? layerIndex,
    );
  }

  @override
  int get estimatedMemoryBytes {
    if (_removedLayer == null) return 0;
    int total = 100; // Layer overhead
    for (final stroke in _removedLayer!.strokes) {
      total += stroke.points.length * 24 + 100;
    }
    return total;
  }
}

/// Command to change layer visibility.
class ToggleLayerVisibilityCommand extends DrawingCommand {
  /// Creates a command to toggle layer visibility.
  ToggleLayerVisibilityCommand({
    required this.layerIndex,
  });

  /// The index of the layer to toggle.
  final int layerIndex;

  @override
  String get description => 'Toggle layer visibility';

  @override
  DrawingDocument execute(DrawingDocument document) {
    final layer = document.layers[layerIndex];
    return document.updateLayer(
      layerIndex,
      layer.copyWith(isVisible: !layer.isVisible),
    );
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    // Toggle is its own inverse
    return execute(document);
  }
}

/// Command to reorder layers.
class ReorderLayersCommand extends DrawingCommand {
  /// Creates a command to reorder layers.
  ReorderLayersCommand({
    required this.oldIndex,
    required this.newIndex,
  });

  /// The original index of the layer.
  final int oldIndex;

  /// The new index for the layer.
  final int newIndex;

  @override
  String get description => 'Reorder layers';

  @override
  DrawingDocument execute(DrawingDocument document) {
    return document.reorderLayers(oldIndex, newIndex);
  }

  @override
  DrawingDocument undo(DrawingDocument document) {
    return document.reorderLayers(newIndex, oldIndex);
  }
}

/// Compound command that groups multiple commands as one undoable action.
class CompoundCommand extends DrawingCommand {
  /// Creates a compound command from a list of commands.
  CompoundCommand({
    required this.commands,
    required this.description,
  });

  /// The commands to execute in order.
  final List<DrawingCommand> commands;

  @override
  final String description;

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
  int get estimatedMemoryBytes {
    return commands.fold(0, (sum, cmd) => sum + cmd.estimatedMemoryBytes);
  }
}
