import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menu_common.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';

/// Menu for a document in the trash (restore / delete forever).
void showTrashDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
  showMenuSheet(context, (ctx) {
    final actions = ref.read(documentMenuActionsProvider);
    return [
      MenuTile(
        icon: Icons.restore_from_trash,
        label: 'Kurtar',
        onTap: () async {
          Navigator.pop(ctx);
          final restored = await actions.restore(document);
          // Failures are shown by LibraryErrorListener.
          if (restored && context.mounted) {
            showMenuSnackBar(context, 'Belge geri yüklendi');
          }
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.delete_forever,
        label: 'Kalıcı Sil',
        isDestructive: true,
        onTap: () async {
          Navigator.pop(ctx);
          final confirmed = await showDeleteConfirmDialog(
            context,
            title: 'Kalıcı Olarak Sil',
            message:
                'Bu belge kalıcı olarak silinecek. Bu işlem geri alınamaz!',
          );
          if (confirmed == true && context.mounted) {
            await actions.deleteForever(document);
          }
        },
      ),
    ];
  });
}
