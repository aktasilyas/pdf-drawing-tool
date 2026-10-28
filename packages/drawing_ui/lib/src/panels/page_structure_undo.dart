import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drawing_ui/src/l10n/l10n.dart';
import 'package:drawing_ui/src/providers/providers.dart';

/// Shows [message] with an [undoLabel] action that reverts [change].
///
/// Same pattern as the page delete SnackBar: a new page change replaces the
/// previous SnackBar, which makes the previous change final.
void showPageUndoSnackBar(
  ScaffoldMessengerState? messenger,
  PageStructureActions actions,
  PageStructureChange? change,
  String message, {
  required String undoLabel,
  required String undoFailedMessage,
}) {
  if (messenger == null || change == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: undoLabel,
          onPressed: () async {
            final undone = await actions.undo(change);
            if (!undone) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(undoFailedMessage)));
            }
          },
        ),
      ),
    );
}

/// Moves the page at [from] to [to] and offers undo.
void movePageWithUndo(WidgetRef ref, BuildContext context, int from, int to) {
  final actions = ref.read(pageStructureActionsProvider);
  final strings = context.drawingStrings;
  final change = actions.movePage(from, to);
  showPageUndoSnackBar(
    ScaffoldMessenger.maybeOf(context),
    actions,
    change,
    strings.pages.pageMoved,
    undoLabel: strings.toolbar.undo,
    undoFailedMessage: strings.pages.cannotUndo,
  );
}
