import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Rename dialog of the open document. Pops the trimmed, non-empty new
/// title on confirm, `null` on cancel.
class RenameDocumentDialog extends StatefulWidget {
  const RenameDocumentDialog({required this.initialTitle, super.key});

  final String initialTitle;

  @override
  State<RenameDocumentDialog> createState() => _RenameDocumentDialogState();
}

class _RenameDocumentDialogState extends State<RenameDocumentDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialTitle);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) Navigator.pop(context, title);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fieldStyle = TextStyle(
      fontFamily: AppTypography.headingFontFamily,
      color: colorScheme.onSurface,
    );
    return AlertDialog(
      backgroundColor: context.palette.surfaceElevated,
      title: Text(context.l10n.commonRename, style: fieldStyle),
      content: TextField(
        controller: _controller,
        style: fieldStyle,
        decoration: InputDecoration(
          labelText: context.l10n.editorDocumentNameLabel,
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}

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
