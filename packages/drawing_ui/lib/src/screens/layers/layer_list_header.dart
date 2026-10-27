import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:drawing_ui/src/providers/providers.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Header of the layers panel: title and the "add layer" button (48dp tall).
class LayerListHeader extends ConsumerWidget {
  const LayerListHeader({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final layerCount = ref.watch(allLayersProvider).length;
    return Container(
      height: ChromeSizes.minTouchTarget,
      padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.md),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
          child: Text(
            'Katmanlar',
            style: textTheme.titleSmall
                ?.copyWith(fontSize: 13, color: cs.onSurface),
          ),
        ),
        SizedBox(
          height: ChromeSizes.minTouchTarget,
          child: TextButton.icon(
            key: const ValueKey('layer-add'),
            onPressed: () =>
                ref.read(layerActionsProvider).add('Katman ${layerCount + 1}'),
            icon: PhosphorIcon(
              ElyanotesIcons.plus,
              size: ChromeIconSizes.md,
              color: cs.primary,
            ),
            label: Text(
              'Katman Ekle',
              style: textTheme.bodySmall?.copyWith(color: cs.primary),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.sm),
              minimumSize: const Size(
                ChromeSizes.minTouchTarget,
                ChromeSizes.minTouchTarget,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
