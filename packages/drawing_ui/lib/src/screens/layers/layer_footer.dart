import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Footer of the layers panel: opacity slider and delete/duplicate buttons.
class LayerFooter extends ConsumerWidget {
  const LayerFooter({
    super.key,
    required this.cs,
    required this.activeIndex,
    required this.opacity,
    required this.layerCount,
  });
  final ColorScheme cs;
  final int activeIndex;
  final double opacity;
  final int layerCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final canDelete = layerCount > 1;
    final border = BorderSide(color: cs.outlineVariant, width: 0.5);
    const touch = BoxConstraints(
      minWidth: ChromeSizes.minTouchTarget,
      minHeight: ChromeSizes.minTouchTarget,
    );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Opacity slider
      Container(
        height: ChromeSizes.minTouchTarget,
        padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.sm),
        decoration: BoxDecoration(border: Border(top: border)),
        child: Row(children: [
          Text(
            '${(opacity * 100).round()}%',
            style: textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
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
                key: const ValueKey('layer-opacity'),
                value: opacity,
                onChanged: (v) => ref
                    .read(documentProvider.notifier)
                    .setLayerOpacity(activeIndex, v),
              ),
            ),
          ),
        ]),
      ),
      // Action buttons
      Container(
        height: ChromeSizes.minTouchTarget,
        decoration: BoxDecoration(border: Border(top: border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            key: const ValueKey('layer-delete'),
            onPressed: canDelete
                ? () => ref.read(layerActionsProvider).remove(activeIndex)
                : null,
            icon: PhosphorIcon(
              ElyanotesIcons.trash,
              size: ChromeIconSizes.md,
              color: canDelete
                  ? cs.error
                  : cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            tooltip: 'Katmani Sil',
            constraints: touch,
          ),
          const SizedBox(width: ChromeSpacing.lg),
          IconButton(
            key: const ValueKey('layer-duplicate'),
            onPressed: () =>
                ref.read(layerActionsProvider).duplicate(activeIndex),
            icon: PhosphorIcon(
              ElyanotesIcons.duplicate,
              size: ChromeIconSizes.md,
              color: cs.onSurface,
            ),
            tooltip: 'Katmani Kopyala',
            constraints: touch,
          ),
        ]),
      ),
    ]);
  }
}
