import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'document_provider.dart';
import 'history_provider.dart';

/// Layer structure changes (add, remove, reorder, duplicate).
///
/// Every action runs through [historyManagerProvider] so it is one undo step.
/// Each method validates first, so a no-op records no history entry.
/// Rename, visibility, lock, opacity and the active layer stay on
/// `DocumentNotifier` and are not undoable.
class LayerActions {
  LayerActions(this._ref);

  final Ref _ref;

  /// Adds an empty layer named [name] on top and makes it active.
  void add(String name) {
    _execute(AddLayerCommand(layer: Layer.empty(name)));
  }

  /// Removes the layer at [index]. Does nothing for the last layer.
  void remove(int index) {
    final layers = _ref.read(documentProvider).layers;
    if (layers.length <= 1 || index < 0 || index >= layers.length) return;
    _execute(RemoveLayerCommand(layerIndex: index));
  }

  /// Moves the layer at [oldIndex] to [newIndex].
  ///
  /// Uses remove-then-insert semantics: [newIndex] is the position in the
  /// list after the layer has been removed.
  void reorder(int oldIndex, int newIndex) {
    final count = _ref.read(documentProvider).layers.length;
    if (oldIndex < 0 || oldIndex >= count) return;
    if (newIndex < 0 || newIndex >= count) return;
    if (oldIndex == newIndex) return;
    _execute(ReorderLayersCommand(oldIndex: oldIndex, newIndex: newIndex));
  }

  /// Copies the layer at [index] above it and makes the copy active.
  void duplicate(int index) {
    final layers = _ref.read(documentProvider).layers;
    if (index < 0 || index >= layers.length) return;

    final source = layers[index];
    final copy = source.copyWith(
      id: 'layer_${DateTime.now().microsecondsSinceEpoch}',
      name: _duplicateName(source.name),
    );
    _execute(AddLayerCommand(
      layer: copy,
      index: index + 1,
      description: 'Duplicate layer',
    ));
  }

  void _execute(DrawingCommand command) {
    _ref.read(historyManagerProvider.notifier).execute(command);
  }

  /// Smart duplicate name: "Foo" -> "Foo (2)", "Foo (2)" -> "Foo (3)".
  static String _duplicateName(String original) {
    final match = RegExp(r'^(.+?)\s*\((\d+)\)$').firstMatch(original);
    if (match != null) {
      final base = match.group(1)!;
      final num = int.parse(match.group(2)!) + 1;
      return '$base ($num)';
    }
    return '$original (2)';
  }
}

/// Provides [LayerActions].
final layerActionsProvider = Provider<LayerActions>(LayerActions.new);
