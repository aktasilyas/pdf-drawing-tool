/// StarNote Manage Folder List Item
///
/// Klasör yönetimi ekranında kullanılan liste elemanı.
library;

import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(
        left: isSub ? AppSpacing.xxl : AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
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
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
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
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
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
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Yeniden Adlandır'),
                ),
                const PopupMenuItem(
                  value: 'color',
                  child: Text('Renk Değiştir'),
                ),
                if (onAddSubfolder != null)
                  const PopupMenuItem(
                    value: 'subfolder',
                    child: Text('Alt Klasör Ekle'),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Sil',
                    style: TextStyle(color: AppColors.error),
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
