import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Confirmation before moving the open document to the trash. Pops `true`
/// on confirm, `null` on cancel.
class MoveToTrashDialog extends StatelessWidget {
  const MoveToTrashDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: context.palette.surfaceElevated,
      title: Text(
        context.l10n.editorMoveToTrashTitle,
        style: TextStyle(
          fontFamily: AppTypography.headingFontFamily,
          color: colorScheme.onSurface,
        ),
      ),
      content: Text(
        context.l10n.editorMoveToTrashMessage,
        style: TextStyle(
          fontFamily: AppTypography.headingFontFamily,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.editorMoveToTrashTitle),
        ),
      ],
    );
  }
}
