import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/theme/theme.dart';

/// "Salt okunur" badge shown next to the title in reader mode.
class ToolbarReaderBadge extends StatelessWidget {
  const ToolbarReaderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ChromePalette.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: 'Salt okunur mod aktif',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ChromeSpacing.sm,
          vertical: ChromeSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: palette.accentContainer,
          borderRadius: BorderRadius.circular(ChromeRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              ElyanotesIcons.readerMode,
              size: ChromeIconSizes.sm,
              color: palette.accent,
            ),
            const SizedBox(width: ChromeSpacing.xs),
            Text(
              'Salt okunur',
              style: textTheme.labelSmall?.copyWith(color: palette.accent),
            ),
          ],
        ),
      ),
    );
  }
}
