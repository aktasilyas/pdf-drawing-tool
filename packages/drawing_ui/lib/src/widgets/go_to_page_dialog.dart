import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';

/// Asks for a page number of a [pageCount]-page document.
///
/// Returns the chosen page as a 0-based index, or null when cancelled.
Future<int?> showGoToPageDialog(
  BuildContext context, {
  required int pageCount,
}) =>
    showDialog<int>(
      context: context,
      builder: (_) => GoToPageDialog(pageCount: pageCount),
    );

/// Go-to-page dialog: digits only, inline range error, Go disabled while empty.
class GoToPageDialog extends StatefulWidget {
  const GoToPageDialog({super.key, required this.pageCount});

  final int pageCount;

  @override
  State<GoToPageDialog> createState() => _GoToPageDialogState();
}

class _GoToPageDialogState extends State<GoToPageDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Rebuild for the Go button state; editing clears a shown error.
    setState(() => _showError = false);
  }

  void _submit() {
    final page = int.tryParse(_controller.text);
    if (page == null) return;
    if (page < 1 || page > widget.pageCount) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(page - 1);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.drawingStrings.pages;
    final theme = Theme.of(context);
    final canSubmit = _controller.text.isNotEmpty;
    return AlertDialog(
      title: Text(strings.goToPage),
      content: TextField(
        key: const ValueKey('go-to-page-field'),
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autofocus: true,
        decoration: InputDecoration(
          hintText: '1 – ${widget.pageCount}',
          errorText:
              _showError ? strings.goToPageOutOfRange(widget.pageCount) : null,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.drawingStrings.panels.cancel,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          key: const ValueKey('go-to-page-go'),
          onPressed: canSubmit ? _submit : null,
          child: Text(strings.go),
        ),
      ],
    );
  }
}
