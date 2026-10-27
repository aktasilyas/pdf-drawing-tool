import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menu_common.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';
import 'package:example_app/l10n/l10n.dart';

/// Menu for a document in the trash (restore / delete forever).
void showTrashDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
  showMenuSheet(context, (ctx) {
    final actions = ref.read(documentMenuActionsProvider);
    final l10n = context.l10n;
    return [
      MenuTile(
        icon: Icons.restore_from_trash,
        label: l10n.commonRestore,
        onTap: () async {
          Navigator.pop(ctx);
          final restored = await actions.restore(document);
          // Failures are shown by LibraryErrorListener.
          if (restored && context.mounted) {
            showMenuSnackBar(context, l10n.libraryDocumentRestored);
          }
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.delete_forever,
        label: l10n.libraryDeleteForever,
        isDestructive: true,
        onTap: () async {
          Navigator.pop(ctx);
          final confirmed = await showDeleteConfirmDialog(
            context,
            title: l10n.libraryDeleteForeverTitle,
            message: l10n.libraryDeleteDocumentForeverMessage,
          );
          if (confirmed == true && context.mounted) {
            await actions.deleteForever(document);
          }
        },
      ),
    ];
  });
}
