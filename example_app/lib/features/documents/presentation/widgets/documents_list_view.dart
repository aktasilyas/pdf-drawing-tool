import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_list_tile.dart';

/// Combined list view showing folders then documents.
class DocumentsCombinedListView extends ConsumerWidget {
  const DocumentsCombinedListView({
    super.key,
    required this.folders,
    required this.documents,
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final List<Folder> folders;
  final List<DocumentInfo> documents;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = Responsive.isPhone(context);
    final padding = isPhone ? AppSpacing.md : AppSpacing.lg;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    final hasFolders = folders.isNotEmpty;
    final hasDocs = documents.isNotEmpty;
    int totalItems = folders.length + documents.length;
    if (hasFolders) totalItems++;
    if (hasDocs) totalItems++;

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: AppSpacing.sm,
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        int currentIndex = index;

        // Folders section header
        if (hasFolders && currentIndex == 0) {
          return _SectionHeader(label: 'Klasörler', color: textTertiary);
        }
        if (hasFolders) currentIndex--;

        // Folder items
        if (currentIndex < folders.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: FolderListTile(
              folder: folders[currentIndex],
              onTap: () => onFolderTap(folders[currentIndex]),
              onLongPress: () => onFolderMore(folders[currentIndex]),
            ),
          );
        }
        currentIndex -= folders.length;

        // Documents section header
        if (hasDocs && currentIndex == 0) {
          return _SectionHeader(
            label: 'Belgeler',
            color: textTertiary,
            topPadding: hasFolders ? AppSpacing.lg : AppSpacing.sm,
          );
        }
        if (hasDocs) currentIndex--;

        // Document items
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: DocumentListTile(
            document: documents[currentIndex],
            onTap: () => onDocumentTap(documents[currentIndex]),
            onLongPress: () => onDocumentMore(documents[currentIndex]),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.color,
    this.topPadding = AppSpacing.sm,
  });

  final String label;
  final Color color;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.sm,
        top: topPadding,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// List tile for a folder row.
class FolderListTile extends ConsumerWidget {
  const FolderListTile({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedFolders = ref.watch(selectedFoldersProvider);
    final isSelected = selectedFolders.contains(folder.id);

    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final hoverColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return Material(
      color: surfaceColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        hoverColor: hoverColor,
        splashColor: hoverColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              if (isSelectionMode)
                SelectionCheckbox(isSelected: isSelected)
              else
                _FolderIcon(folder: folder),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  folder.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _FolderCountBadge(
                count: folder.documentCount,
                isDark: isDark,
              ),
              if (!isSelectionMode) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderIcon extends StatelessWidget {
  const _FolderIcon({required this.folder});
  final Folder folder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Color(folder.colorValue).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(
        Icons.folder_rounded,
        size: 20,
        color: Color(folder.colorValue),
      ),
    );
  }
}

class _FolderCountBadge extends StatelessWidget {
  const _FolderCountBadge({required this.count, required this.isDark});
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$count',
        style: AppTypography.caption.copyWith(
          color: textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
