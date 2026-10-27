import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/providers/providers.dart';

/// Shows [message] with a 'Geri al' action that reverts [change].
///
/// Same pattern as the page delete SnackBar: a new page change replaces the
/// previous SnackBar, which makes the previous change final.
void showPageUndoSnackBar(
  ScaffoldMessengerState? messenger,
  PageStructureActions actions,
  PageStructureChange? change,
  String message,
) {
  if (messenger == null || change == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () => actions.undo(change),
        ),
      ),
    );
}

/// Moves the page at [from] to [to] and offers undo.
void movePageWithUndo(WidgetRef ref, BuildContext context, int from, int to) {
  final actions = ref.read(pageStructureActionsProvider);
  final change = actions.movePage(from, to);
  showPageUndoSnackBar(
    ScaffoldMessenger.maybeOf(context),
    actions,
    change,
    'Sayfa taşındı',
  );
}
