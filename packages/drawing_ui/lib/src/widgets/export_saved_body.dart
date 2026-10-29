import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/export_progress_provider.dart';
import 'package:drawing_ui/src/theme/chrome_tokens.dart';
import 'package:drawing_ui/src/theme/elyanotes_icons.dart';

/// "Saved" line of the export progress overlay, plus a warning when some
/// pages were exported without their PDF background or inserted images.
class ExportSavedBody extends StatelessWidget {
  const ExportSavedBody({
    super.key,
    required this.state,
    required this.cs,
  });

  final ExportProgressState state;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final s = context.drawingStrings.export;
    final size = state.fileSize;
    final missing = state.pagesMissingBackground;
    final missingImages = state.pagesMissingImages;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PhosphorIcon(
              ElyanotesIcons.checkCircle,
              size: 18,
              color: Colors.green,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                size != null ? s.savedWithSize(size) : s.saved,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (missing > 0)
          _warning(s.pagesWithoutPdfBackground(missing), textTheme),
        if (missingImages > 0)
          _warning(s.pagesWithoutImages(missingImages), textTheme),
      ],
    );
  }

  Widget _warning(String text, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.only(top: ChromeSpacing.sm),
      child: Row(
        children: [
          PhosphorIcon(
            ElyanotesIcons.warningCircle,
            size: 18,
            color: cs.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
