import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menu_common.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/features/documents/presentation/widgets/rename_document_dialog.dart';
import 'package:example_app/features/premium/premium.dart';

/// Menu for a regular (non-trash) document.
void showNormalDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
  showMenuSheet(context, (ctx) {
    final actions = ref.read(documentMenuActionsProvider);
    return [
      MenuTile(
        icon: Icons.edit_outlined,
        label: 'Yeniden Adlandır',
        onTap: () {
          Navigator.pop(ctx);
          showRenameDocumentDialog(context, ref, document);
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.content_copy,
        label: 'Çoğalt',
        onTap: () async {
          Navigator.pop(ctx);
          final outcome = await actions.duplicate(document);
          if (!context.mounted) return;
          final blocked = outcome.blockedBy;
          if (blocked != null) {
            await UpgradePromptSheet.show(
              context,
              access: blocked,
              featureIcon: Icons.note_add_outlined,
              featureTitle: 'Belge Limitine Ulaştınız',
              onUpgrade: () {
                Navigator.pop(context);
                GoRouter.of(context).push(RouteNames.paywall);
              },
            );
          } else if (outcome.duplicated) {
            // Failures are shown by LibraryErrorListener.
            showMenuSnackBar(context, 'Belge çoğaltıldı');
          }
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.drive_file_move_outlined,
        label: 'Taşı',
        onTap: () async {
          Navigator.pop(ctx);
          final messenger = ScaffoldMessenger.of(context);
          final moved = await showDialog<bool>(
            context: context,
            builder: (_) => MoveToFolderDialog(documentIds: [document.id]),
          );
          if (moved == true) {
            actions.onMoved();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Belge taşındı'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
      softDivider(context),
      MenuTile(
        icon: document.isFavorite ? Icons.star : Icons.star_outline,
        label: document.isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
        onTap: () {
          Navigator.pop(ctx);
          actions.toggleFavorite(document);
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.delete_outline,
        label: 'Çöpe Taşı',
        isDestructive: true,
        onTap: () {
          Navigator.pop(ctx);
          actions.moveToTrash(document);
        },
      ),
    ];
  });
}
