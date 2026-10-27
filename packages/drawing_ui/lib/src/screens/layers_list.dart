/// Procreate/GoodNotes-style layer management panel for the page sidebar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' show Layer;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/screens/layers/layer_footer.dart';
import 'package:drawing_ui/src/screens/layers/layer_list_header.dart';
import 'package:drawing_ui/src/screens/layers/layer_row.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Layer management panel shown when the layers filter is selected.
class LayersList extends ConsumerWidget {
  const LayersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(allLayersProvider);
    final activeIndex = ref.watch(activeLayerIndexProvider);
    final cs = Theme.of(context).colorScheme;
    final activeOpacity = activeIndex >= 0 && activeIndex < layers.length
        ? layers[activeIndex].opacity
        : 1.0;
    return Column(
      children: [
        LayerListHeader(cs: cs),
        Expanded(child: _buildList(ref, layers, activeIndex, cs)),
        LayerFooter(
            cs: cs,
            activeIndex: activeIndex,
            opacity: activeOpacity,
            layerCount: layers.length),
      ],
    );
  }

  Widget _buildList(
      WidgetRef ref, List<Layer> layers, int activeIndex, ColorScheme cs) {
    if (layers.isEmpty) return const SizedBox.shrink();
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: ChromeSpacing.xs),
      itemCount: layers.length,
      onReorder: (oldIdx, newIdx) {
        // Flutter's convention: newIdx is in pre-removal space.
        if (newIdx > oldIdx) newIdx--;
        // Convert reversed display indices to data indices.
        final dataOld = layers.length - 1 - oldIdx;
        final dataNew = layers.length - 1 - newIdx;
        ref.read(layerActionsProvider).reorder(dataOld, dataNew);
      },
      itemBuilder: (context, displayIndex) {
        final dataIndex = layers.length - 1 - displayIndex;
        final layer = layers[dataIndex];
        return LayerRow(
          key: ValueKey(layer.id),
          layer: layer,
          dataIndex: dataIndex,
          displayIndex: displayIndex,
          isActive: dataIndex == activeIndex,
          cs: cs,
        );
      },
    );
  }
}
