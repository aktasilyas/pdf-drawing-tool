import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/internal.dart';

/// Widget for selection actions (delete, copy, etc.).
class SelectionActions extends ConsumerWidget {
  final Selection selection;
  final VoidCallback? onDeleted;

  const SelectionActions({
    super.key,
    required this.selection,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }

  void deleteSelection(WidgetRef ref) {
    final document = ref.read(documentProvider);
    final command = DeleteSelectionCommand(
      layerIndex: document.activeLayerIndex,
      strokeIds: selection.selectedStrokeIds,
      shapeIds: selection.selectedShapeIds,
    );
    ref.read(historyManagerProvider.notifier).execute(command);
    ref.read(selectionProvider.notifier).clearSelection();
    ref.read(selectionUiProvider.notifier).reset();
    onDeleted?.call();
  }
}
