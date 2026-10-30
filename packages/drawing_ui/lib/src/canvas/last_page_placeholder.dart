import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// Placeholder shown when there is no next page in dual-page mode.
class LastPagePlaceholder extends StatelessWidget {
  const LastPagePlaceholder({super.key, required this.surroundingColor});
  final Color surroundingColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: surroundingColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(ElyanotesIcons.page,
                size: 40, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Text(context.drawingStrings.pageList.lastPage,
                style: textTheme.bodySmall
                    ?.copyWith(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
