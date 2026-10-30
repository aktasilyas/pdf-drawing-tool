import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';

/// The modal "Opening PDF..." progress dialog of a PDF import. [close] is
/// idempotent so error and cancel paths cannot pop the route twice.
class PdfImportLoadingDialog {
  PdfImportLoadingDialog(this._context, this._label);

  final BuildContext _context;
  final String _label;
  bool _open = false;

  bool get isOpen => _open;

  /// Shows the dialog unless it is already open or the context is gone.
  void show() {
    if (_open || !_context.mounted) return;
    _open = true;
    showDialog<void>(
      context: _context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              _label,
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  /// Pops the dialog if it is open.
  void close() {
    if (!_open || !_context.mounted) return;
    _open = false;
    Navigator.of(_context, rootNavigator: true).pop();
  }
}
