import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/l10n/l10n.dart';

/// Longest title a document may be renamed to.
const int kMaxTitleLength = 120;

/// Rename dialog shared by the library and the editor. Pops the trimmed,
/// non-empty new title on confirm (Save or Enter), `null` on cancel. Save is
/// disabled while the input is blank.
class RenameDialog extends StatefulWidget {
  const RenameDialog({
    required this.initialTitle,
    required this.labelText,
    super.key,
  });

  final String initialTitle;
  final String labelText;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
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
        maxLength: kMaxTitleLength,
        decoration: InputDecoration(
          labelText: widget.labelText,
          counterText: '',
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(context.l10n.commonSave),
          ),
        ),
      ],
    );
  }
}
