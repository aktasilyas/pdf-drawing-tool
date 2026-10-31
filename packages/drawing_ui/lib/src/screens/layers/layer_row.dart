import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_core/drawing_core.dart' show Layer;
import 'package:drawing_ui/src/l10n/canvas_strings.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Divider line width; row heights add it so targets stay 48dp.
const double _line = 0.5;

/// One row of the layers panel: drag handle, name (double tap to rename),
/// visibility and lock toggles. Tapping the row activates the layer.
///
/// Semantics: the row is one button node (label = layer name, selected =
/// active, tap activates) with a custom "Rename" action next to the list's
/// reorder actions. The toggles are separate nodes that announce state.
class LayerRow extends ConsumerStatefulWidget {
  const LayerRow({
    super.key,
    required this.layer,
    required this.dataIndex,
    required this.displayIndex,
    required this.isActive,
    required this.cs,
  });
  final Layer layer;
  final int dataIndex;
  final int displayIndex;
  final bool isActive;
  final ColorScheme cs;

  @override
  ConsumerState<LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends ConsumerState<LayerRow> {
  bool _isEditing = false;
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.layer.name);
  }

  @override
  void didUpdateWidget(covariant LayerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.layer.name != widget.layer.name) {
      _tc.text = widget.layer.name;
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _submitRename() {
    final newName = _tc.text.trim();
    if (newName.isNotEmpty && newName != widget.layer.name) {
      ref
          .read(documentProvider.notifier)
          .renameLayer(widget.dataIndex, newName);
    } else {
      _tc.text = widget.layer.name;
    }
    setState(() => _isEditing = false);
  }

  void _activate() =>
      ref.read(documentProvider.notifier).setActiveLayer(widget.dataIndex);

  void _startEditing() => setState(() => _isEditing = true);

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final layer = widget.layer;
    final strings = context.drawingStrings.canvas;
    return GestureDetector(
      key: ValueKey('layer-row-${layer.id}'),
      // The name area below is the row's semantics node.
      excludeFromSemantics: true,
      onTap: _activate,
      child: Container(
        height: ChromeSizes.minTouchTarget + _line,
        padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.xs),
        decoration: BoxDecoration(
          color: widget.isActive ? cs.primaryContainer : null,
          border: Border(
            bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.3), width: _line),
          ),
        ),
        child: Row(children: [
          ReorderableDragStartListener(
            index: widget.displayIndex,
            child: SizedBox(
              width: ChromeSizes.minTouchTarget,
              height: ChromeSizes.minTouchTarget,
              child: Center(
                child: PhosphorIcon(
                  ElyanotesIcons.dragHandle,
                  size: ChromeIconSizes.md,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(child: _buildNameField(cs, layer, strings)),
          _IconToggle(
            key: ValueKey('layer-visibility-${layer.id}'),
            onPressed: () => ref
                .read(documentProvider.notifier)
                .toggleLayerVisibility(widget.dataIndex),
            icon: layer.isVisible
                ? PhosphorIconsLight.eye
                : PhosphorIconsLight.eyeSlash,
            color: layer.isVisible ? cs.onSurface : cs.onSurfaceVariant,
            toggled: layer.isVisible,
            tooltip: layer.isVisible ? strings.hideLayer : strings.showLayer,
          ),
          _IconToggle(
            key: ValueKey('layer-lock-${layer.id}'),
            onPressed: () => ref
                .read(documentProvider.notifier)
                .toggleLayerLocked(widget.dataIndex),
            icon:
                layer.isLocked ? ElyanotesIcons.lock : ElyanotesIcons.lockOpen,
            color: layer.isLocked ? cs.primary : cs.onSurfaceVariant,
            toggled: layer.isLocked,
            tooltip: layer.isLocked ? strings.unlockLayer : strings.lockLayer,
          ),
        ]),
      ),
    );
  }

  Widget _buildNameField(ColorScheme cs, Layer layer, CanvasStrings strings) {
    final textTheme = Theme.of(context).textTheme;
    if (_isEditing) {
      return TextField(
        key: ValueKey('layer-rename-${layer.id}'),
        controller: _tc,
        autofocus: true,
        style: textTheme.bodySmall?.copyWith(fontSize: 13, color: cs.onSurface),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: ChromeSpacing.xs,
            vertical: ChromeSpacing.sm,
          ),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => _submitRename(),
        onTapOutside: (_) => _submitRename(),
      );
    }
    final base = widget.isActive ? textTheme.titleSmall : textTheme.bodySmall;
    final nameStyle = base?.copyWith(fontSize: 13, color: cs.onSurface);
    // A screen reader's double tap is one activation, so rename gets a
    // custom action; the row tap (activate) is the node's default action.
    // Not a container: these properties merge into the list item's node, so
    // the row is one node that also carries the list's move up/down actions.
    return Semantics(
      key: ValueKey('layer-semantics-${layer.id}'),
      button: true,
      selected: widget.isActive,
      label: layer.name,
      excludeSemantics: true,
      onTap: _activate,
      customSemanticsActions: {
        CustomSemanticsAction(label: strings.renameLayer): _startEditing,
      },
      child: GestureDetector(
        key: ValueKey('layer-name-${layer.id}'),
        behavior: HitTestBehavior.opaque,
        onDoubleTap: _startEditing,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.xs),
            child: Text(
              layer.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: nameStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  const _IconToggle({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.toggled,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final String tooltip;

  /// Current on/off state announced to screen readers.
  final bool toggled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      toggled: toggled,
      label: tooltip,
      excludeSemantics: true,
      onTap: onPressed,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: ChromeSizes.minTouchTarget,
            height: ChromeSizes.minTouchTarget,
            child: Center(
              child: PhosphorIcon(
                icon,
                size: ChromeIconSizes.md,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
