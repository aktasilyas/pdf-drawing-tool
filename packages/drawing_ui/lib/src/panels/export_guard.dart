/// Single-export guard shared by every export entry point (#491).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Returns true, after showing the localized "export in progress" message,
/// when another export is still running; the caller then starts nothing.
///
/// Call it before closing the menu, while [context] is still mounted. The
/// export flows also refuse to start a second run on their own (see
/// [ExportProgressNotifier.tryBegin]); this adds the user-facing message.
bool rejectIfExportRunning(BuildContext context, WidgetRef ref) {
  if (!ref.read(exportProgressProvider.notifier).isBusy) return false;
  final message = context.drawingStrings.export.inProgress;
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  return true;
}
