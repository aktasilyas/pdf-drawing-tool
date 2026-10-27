import 'package:flutter/material.dart';

import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/widgets/color_picker_logic.dart';

/// Colour preview + hex + RGB read-out under the picker tabs.
class ColorPickerInfoBar extends StatelessWidget {
  const ColorPickerInfoBar({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rgb = ColorPickerLogic.rgb(color);
    final hex = '#${ColorPickerLogic.hex(color)}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ChromeSpacing.lg,
        vertical: 6,
      ),
      child: Row(children: [
        Container(
          key: const ValueKey('colorPickerPreview'),
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(ChromeRadius.md),
          ),
        ),
        const SizedBox(width: ChromeSpacing.sm),
        _InfoColumn('Altıgen', hex, cs, textTheme),
        _InfoColumn('Kırmızı', '${rgb.r}', cs, textTheme),
        _InfoColumn('Yeşil', '${rgb.g}', cs, textTheme),
        _InfoColumn('Mavi', '${rgb.b}', cs, textTheme),
      ]),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn(this.label, this.value, this.cs, this.textTheme);

  final String label;
  final String value;
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(label,
            style: textTheme.labelSmall
                ?.copyWith(fontSize: 9, color: cs.onSurfaceVariant)),
        const SizedBox(height: ChromeSpacing.xxs),
        Text(value,
            style: textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
      ]),
    );
  }
}

/// Dotted line separator between the read-out and the recent colours.
class ColorPickerDottedDivider extends StatelessWidget {
  const ColorPickerDottedDivider({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ChromeSpacing.lg,
        vertical: ChromeSpacing.xs,
      ),
      child: LayoutBuilder(builder: (_, c) {
        final count = (c.maxWidth / 5).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        );
      }),
    );
  }
}
