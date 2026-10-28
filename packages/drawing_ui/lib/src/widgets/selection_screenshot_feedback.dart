import 'package:flutter/material.dart';
import 'package:drawing_ui/src/l10n/drawing_strings_scope.dart';
import 'package:drawing_ui/src/providers/selection_capture_actions.dart';

/// Shows the localized snackbar for a screenshot [outcome].
///
/// Does nothing when [context] is null or no longer mounted.
void showSelectionScreenshotFeedback(
  BuildContext? context,
  SelectionScreenshotOutcome outcome,
) {
  if (context == null || !context.mounted) return;
  final s = context.drawingStrings.selection;
  final message = switch (outcome) {
    SelectionScreenshotOutcome.captureFailed => s.screenshotCaptureFailed,
    SelectionScreenshotOutcome.savedAndCopied => s.screenshotSavedAndCopied,
    SelectionScreenshotOutcome.saved => s.screenshotSaved,
    SelectionScreenshotOutcome.copied => s.screenshotCopied,
    SelectionScreenshotOutcome.saveFailed => s.screenshotSaveFailed,
  };
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}
