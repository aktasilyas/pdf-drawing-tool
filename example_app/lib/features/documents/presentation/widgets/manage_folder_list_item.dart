/// ElyaNotes Manage Folder List Item
///
/// List item of the manage-folders screen.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/l10n/l10n.dart';

/// Folder list item widget for ManageFoldersScreen
class ManageFolderListItem extends StatelessWidget {
  final Folder folder;
  final int index;
  final VoidCallback onRename;
  final VoidCallback onChangeColor;
  final VoidCallback? onAddSubfolder;
  final VoidCallback onDelete;

  const ManageFolderListItem({
    super.key,
    required this.folder,
    required this.index,
    required this.onRename,
    required this.onChangeColor,
    this.onAddSubfolder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isSub = folder.isSubfolder;

    return Container(
      margin: EdgeInsets.only(
        left: isSub ? AppSpacing.xxl : AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(folder.colorValue),
          ),
        ),
        title: Text(
          folder.name,
          style: AppTypography.titleMedium.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.drag_handle,
                    color: context.palette.textDisabled),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: context.palette.textMuted),
              onSelected: (value) {
                switch (value) {
                  case 'rename':
                    onRename();
                  case 'color':
                    onChangeColor();
                  case 'subfolder':
                    onAddSubfolder?.call();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(ctx.l10n.commonRename),
                ),
                PopupMenuItem(
                  value: 'color',
                  child: Text(ctx.l10n.libraryChangeColor),
                ),
                if (onAddSubfolder != null)
                  PopupMenuItem(
                    value: 'subfolder',
                    child: Text(ctx.l10n.libraryAddSubfolder),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    ctx.l10n.commonDelete,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
