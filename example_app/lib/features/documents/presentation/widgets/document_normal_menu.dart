import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/routing/route_names.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/document_export_actions.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menu_common.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/features/documents/presentation/widgets/rename_document_dialog.dart';
import 'package:example_app/features/editor/presentation/l10n/app_export_strings.dart';
import 'package:example_app/features/premium/premium.dart';
import 'package:example_app/l10n/l10n.dart';

/// Menu for a regular (non-trash) document.
void showNormalDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
  showMenuSheet(context, (ctx) {
    final actions = ref.read(documentMenuActionsProvider);
    final l10n = context.l10n;
    return [
      MenuTile(
        icon: Icons.edit_outlined,
        label: l10n.commonRename,
        onTap: () {
          Navigator.pop(ctx);
          showRenameDocumentDialog(context, ref, document);
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.content_copy,
        label: l10n.commonDuplicate,
        onTap: () async {
          Navigator.pop(ctx);
          final outcome = await actions.duplicate(
            document,
            copyTitle: l10n.libraryCopyTitle,
          );
          if (!context.mounted) return;
          final blocked = outcome.blockedBy;
          if (blocked != null) {
            await UpgradePromptSheet.show(
              context,
              access: blocked,
              featureIcon: Icons.note_add_outlined,
              featureTitle: l10n.libraryDocumentLimitReached,
              onUpgrade: () {
                Navigator.pop(context);
                GoRouter.of(context).push(RouteNames.paywall);
              },
            );
          } else if (outcome.duplicated) {
            // Failures are shown by LibraryErrorListener.
            showMenuSnackBar(context, l10n.libraryDocumentDuplicated);
          }
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.drive_file_move_outlined,
        label: l10n.commonMove,
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
              SnackBar(
                content: Text(l10n.libraryDocumentMoved),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
      softDivider(context),
      MenuTile(
        icon: document.isFavorite ? Icons.star : Icons.star_outline,
        label: document.isFavorite
            ? l10n.libraryRemoveFromFavorites
            : l10n.libraryAddToFavorites,
        onTap: () {
          Navigator.pop(ctx);
          actions.toggleFavorite(document);
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.ios_share,
        label: l10n.libraryExportAsPdf,
        onTap: () {
          Navigator.pop(ctx);
          // A failed load is shown by LibraryErrorListener.
          ref.read(documentExportActionsProvider).exportAsPdf(
                document.id,
                strings: AppExportStrings(l10n),
              );
        },
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.delete_outline,
        label: l10n.libraryMoveToTrash,
        isDestructive: true,
        onTap: () async {
          Navigator.pop(ctx);
          // The tile is removed once the notebook is trashed, so read
          // everything context-bound before awaiting.
          final messenger = ScaffoldMessenger.of(context);
          final keepUndoVisible = MediaQuery.accessibleNavigationOf(context);
          // Failures are shown by LibraryErrorListener.
          if (!await actions.moveToTrash(document)) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.libraryDocumentTrashed),
              behavior: SnackBarBehavior.floating,
              // Auto-dismiss unless a screen reader needs time to reach Undo.
              persist: keepUndoVisible,
              action: SnackBarAction(
                label: l10n.commonUndo,
                onPressed: () => actions.restore(document),
              ),
            ),
          );
        },
      ),
    ];
  });
}
