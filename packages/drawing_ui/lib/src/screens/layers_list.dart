/// Procreate/GoodNotes-style layer management panel for the page sidebar.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:drawing_core/drawing_core.dart' show Layer;
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/starnote_icons.dart';

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
        _LayerListHeader(cs: cs),
        Expanded(child: _buildList(ref, layers, activeIndex, cs)),
        _LayerFooter(cs: cs, activeIndex: activeIndex, opacity: activeOpacity,
            layerCount: layers.length),
      ],
    );
  }

  Widget _buildList(WidgetRef ref, List<Layer> layers, int activeIndex, ColorScheme cs) {
    if (layers.isEmpty) return const SizedBox.shrink();
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: layers.length,
      onReorder: (oldIdx, newIdx) {
        // Flutter's convention: newIdx is in pre-removal space.
        if (newIdx > oldIdx) newIdx--;
        // Convert reversed display indices to data indices.
        final dataOld = layers.length - 1 - oldIdx;
        final dataNew = layers.length - 1 - newIdx;
        ref.read(documentProvider.notifier).reorderLayers(dataOld, dataNew);
      },
      itemBuilder: (context, displayIndex) {
        final dataIndex = layers.length - 1 - displayIndex;
        final layer = layers[dataIndex];
        return _LayerRow(
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

class _LayerListHeader extends ConsumerWidget {
  const _LayerListHeader({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layerCount = ref.watch(allLayersProvider).length;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(child: Text('Katmanlar', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface))),
        SizedBox(height: 48, child: TextButton.icon(
          onPressed: () =>
              ref.read(documentProvider.notifier).addLayer('Katman ${layerCount + 1}'),
          icon: PhosphorIcon(StarNoteIcons.plus, size: 18, color: cs.primary),
          label: Text('Katman Ekle', style: TextStyle(fontSize: 12, color: cs.primary)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(48, 48)),
        )),
      ]),
    );
  }
}

class _LayerRow extends ConsumerStatefulWidget {
  const _LayerRow({
    super.key,
    required this.layer, required this.dataIndex,
    required this.displayIndex, required this.isActive, required this.cs,
  });
  final Layer layer;
  final int dataIndex;
  final int displayIndex;
  final bool isActive;
  final ColorScheme cs;

  @override
  ConsumerState<_LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends ConsumerState<_LayerRow> {
  bool _isEditing = false;
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.layer.name);
  }

  @override
  void didUpdateWidget(covariant _LayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.layer.name != widget.layer.name) {
      _tc.text = widget.layer.name;
    }
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  void _submitRename() {
    final newName = _tc.text.trim();
    if (newName.isNotEmpty && newName != widget.layer.name) {
      ref.read(documentProvider.notifier).renameLayer(widget.dataIndex, newName);
    } else {
      _tc.text = widget.layer.name;
    }
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final layer = widget.layer;
    return GestureDetector(
      onTap: () => ref.read(documentProvider.notifier).setActiveLayer(widget.dataIndex),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: widget.isActive ? cs.primaryContainer : null,
          border: Border(
            bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3), width: 0.5),
          ),
        ),
        child: Row(children: [
          ReorderableDragStartListener(
            index: widget.displayIndex,
            child: SizedBox(
              width: 48, height: 48,
              child: Center(
                child: PhosphorIcon(StarNoteIcons.dragHandle, size: 18, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(child: _buildNameField(cs, layer)),
          _IconToggle(
            onPressed: () =>
                ref.read(documentProvider.notifier).toggleLayerVisibility(widget.dataIndex),
            icon: layer.isVisible ? PhosphorIconsLight.eye : PhosphorIconsLight.eyeSlash,
            color: layer.isVisible ? cs.onSurface : cs.onSurfaceVariant,
            tooltip: layer.isVisible ? 'Gizle' : 'Goster',
          ),
          _IconToggle(
            onPressed: () =>
                ref.read(documentProvider.notifier).toggleLayerLocked(widget.dataIndex),
            icon: layer.isLocked ? StarNoteIcons.lock : StarNoteIcons.lockOpen,
            color: layer.isLocked ? cs.primary : cs.onSurfaceVariant,
            tooltip: layer.isLocked ? 'Kilidi Ac' : 'Kilitle',
          ),
        ]),
      ),
    );
  }

  Widget _buildNameField(ColorScheme cs, Layer layer) {
    if (_isEditing) {
      return TextField(
        controller: _tc, autofocus: true,
        style: TextStyle(fontSize: 13, color: cs.onSurface),
        decoration: const InputDecoration(isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            border: InputBorder.none),
        onSubmitted: (_) => _submitRename(),
        onTapOutside: (_) => _submitRename(),
      );
    }
    return GestureDetector(
      onDoubleTap: () => setState(() => _isEditing = true),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(layer.name, overflow: TextOverflow.ellipsis, maxLines: 1,
            style: TextStyle(fontSize: 13, color: cs.onSurface,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    required this.onPressed, required this.icon,
    required this.color, required this.tooltip,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48, height: 48,
          child: Center(child: PhosphorIcon(icon, size: 18, color: color)),
        ),
      ),
    );
  }
}

class _LayerFooter extends ConsumerWidget {
  const _LayerFooter({
    required this.cs, required this.activeIndex,
    required this.opacity, required this.layerCount,
  });
  final ColorScheme cs;
  final int activeIndex;
  final double opacity;
  final int layerCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = layerCount > 1;
    final border = BorderSide(color: cs.outlineVariant, width: 0.5);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Opacity slider
      Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(border: Border(top: border)),
        child: Row(children: [
          Text('${(opacity * 100).round()}%',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.onSurface.withValues(alpha: 0.12),
                thumbColor: cs.primary,
              ),
              child: Slider(
                value: opacity,
                onChanged: (v) => ref.read(documentProvider.notifier)
                    .setLayerOpacity(activeIndex, v),
              ),
            ),
          ),
        ]),
      ),
      // Action buttons
      Container(
        height: 48,
        decoration: BoxDecoration(border: Border(top: border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: canDelete
                ? () => ref.read(documentProvider.notifier).removeLayer(activeIndex)
                : null,
            icon: PhosphorIcon(StarNoteIcons.trash, size: 18,
                color: canDelete ? cs.error : cs.onSurfaceVariant.withValues(alpha: 0.3)),
            tooltip: 'Katmani Sil',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => ref.read(documentProvider.notifier).duplicateLayer(activeIndex),
            icon: PhosphorIcon(StarNoteIcons.duplicate, size: 18, color: cs.onSurface),
            tooltip: 'Katmani Kopyala',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ]),
      ),
    ]);
  }
}
