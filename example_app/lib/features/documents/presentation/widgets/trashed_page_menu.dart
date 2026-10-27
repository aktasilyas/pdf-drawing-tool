import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menu_common.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';
import 'package:example_app/l10n/l10n.dart';

/// Shows context menu for a trashed page (restore / delete permanently).
void showTrashedPageMenu(
  BuildContext context,
  WidgetRef ref,
  TrashedPage trashedPage,
) {
  final textPrimary = context.palette.textPrimary;
  final l10n = context.l10n;

  showMenuSheet(context, (ctx) {
    final actions = ref.read(documentMenuActionsProvider);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          l10n.libraryTrashedPageTitle(
            trashedPage.sourceDocumentTitle,
            trashedPage.originalPageIndex + 1,
          ),
          style: AppTypography.titleLarge.copyWith(color: textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.restore_from_trash,
        label: l10n.commonRestore,
        onTap: () async {
          Navigator.pop(ctx);
          final outcome = await actions.restorePage(trashedPage);
          if (!context.mounted) return;
          switch (outcome) {
            case PageRestoreOutcome.sourceMissing:
              showMenuSnackBar(context, l10n.librarySourceDocumentMissing);
            case PageRestoreOutcome.restored:
              showMenuSnackBar(context, l10n.libraryPageRestored);
            case PageRestoreOutcome.failed:
              showMenuSnackBar(
                context,
                l10n.libraryPageRestoreFailed,
                backgroundColor: Theme.of(context).colorScheme.error,
              );
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
            message: l10n.libraryDeletePageForeverMessage,
          );
          if (confirmed == true) await actions.deletePageForever(trashedPage);
        },
      ),
    ];
  });
}
