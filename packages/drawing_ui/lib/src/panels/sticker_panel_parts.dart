import 'package:flutter/material.dart';
import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/panels/sticker_catalog.dart';
import 'package:drawing_ui/src/theme/theme.dart';

/// Largest sticker cell edge; the grid fits as many columns as this allows,
/// so cells stay at least [ChromeSizes.minTouchTarget] in a 300dp panel.
const double _maxCellExtent = 56;

/// Full-width action button of the sticker panel, at least 48dp tall.
class StickerActionButton extends StatelessWidget {
  const StickerActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = enabled ? cs.primary : cs.onSurfaceVariant;
    final radius = BorderRadius.circular(ChromeRadius.sm);
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          child: _content(context, color, radius),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color color, BorderRadius radius) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: ChromeSizes.minTouchTarget,
      ),
      padding: const EdgeInsets.symmetric(horizontal: ChromeSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: enabled ? 0.1 : 0.05),
        borderRadius: radius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: ChromeIconSizes.sm, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// Grid of the stickers of [category].
class StickerGrid extends StatelessWidget {
  const StickerGrid({
    super.key,
    required this.category,
    required this.selectedIndex,
    required this.onStickerSelected,
    this.onStickerDoubleTap,
  });

  final StickerCategory category;
  final int selectedIndex;
  final ValueChanged<int> onStickerSelected;
  final ValueChanged<String>? onStickerDoubleTap;

  @override
  Widget build(BuildContext context) {
    final stickers = stickersForCategory(category);
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: _maxCellExtent,
        mainAxisSpacing: ChromeSpacing.xs,
        crossAxisSpacing: ChromeSpacing.xs,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) => StickerCell(
        emoji: stickers[index],
        selected: index == selectedIndex,
        onTap: () => onStickerSelected(index),
        onDoubleTap: () => onStickerDoubleTap?.call(stickers[index]),
      ),
    );
  }
}

/// One sticker in the [StickerGrid].
///
/// Announced as a selectable button labelled with the emoji. Screen-reader
/// users select it with a double tap (semantic tap) and insert it with the
/// "add sticker" custom action, so the visual double tap is not required.
class StickerCell extends StatelessWidget {
  const StickerCell({
    super.key,
    required this.emoji,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final insert = CustomSemanticsAction(
      label: context.drawingStrings.catalog.addSticker,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: emoji,
      onTap: onTap,
      customSemanticsActions: {insert: onDoubleTap},
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.12)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(ChromeRadius.sm),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: textTheme.titleMedium?.copyWith(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
