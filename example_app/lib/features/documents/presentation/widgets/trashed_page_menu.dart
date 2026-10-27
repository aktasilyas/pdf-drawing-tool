import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/document_menu_actions.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_menu_common.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';

/// Shows context menu for a trashed page (Kurtar / Kalıcı Sil).
void showTrashedPageMenu(
  BuildContext context,
  WidgetRef ref,
  TrashedPage trashedPage,
) {
  final textPrimary = context.palette.textPrimary;

  showMenuSheet(context, (ctx) {
    final actions = ref.read(documentMenuActionsProvider);
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          '${trashedPage.sourceDocumentTitle} — Sayfa ${trashedPage.originalPageIndex + 1}',
          style: AppTypography.titleLarge.copyWith(color: textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      softDivider(context),
      MenuTile(
        icon: Icons.restore_from_trash,
        label: 'Kurtar',
        onTap: () async {
          Navigator.pop(ctx);
          final outcome = await actions.restorePage(trashedPage);
          if (!context.mounted) return;
          switch (outcome) {
            case PageRestoreOutcome.sourceMissing:
              showMenuSnackBar(context, 'Kaynak belge bulunamadı');
            case PageRestoreOutcome.restored:
              showMenuSnackBar(context, 'Sayfa geri yüklendi');
            case PageRestoreOutcome.failed:
              showMenuSnackBar(
                context,
                'Sayfa geri yüklenemedi',
                backgroundColor: Theme.of(context).colorScheme.error,
              );
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
                'Bu sayfa kalıcı olarak silinecek. Bu işlem geri alınamaz!',
          );
          if (confirmed == true) await actions.deletePageForever(trashedPage);
        },
      ),
    ];
  });
}
