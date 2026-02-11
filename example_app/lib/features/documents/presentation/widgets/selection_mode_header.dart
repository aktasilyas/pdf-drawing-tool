/// StarNote Selection Mode Header
///
/// Seçim modunda gösterilen header widget'ı.
/// Tümünü seç, çoğalt, taşı, sil işlemleri içerir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';

class SelectionModeHeader extends ConsumerWidget {
  final List<String> allDocumentIds;
  final List<String> allFolderIds;
  final bool isTrashSection;

  const SelectionModeHeader({
    super.key,
    this.allDocumentIds = const [],
    this.allFolderIds = const [],
    this.isTrashSection = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPhone = Responsive.isPhone(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final selectedFolders = ref.watch(selectedFoldersProvider);
    final hasSelection = selectedDocs.isNotEmpty || selectedFolders.isNotEmpty;
    final totalSelected = selectedDocs.length + selectedFolders.length;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? AppSpacing.lg : AppSpacing.xxl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Close button
          AppIconButton(
            icon: Icons.close,
            variant: AppIconButtonVariant.ghost,
            tooltip: 'Kapat',
            onPressed: () => _exitSelectionMode(ref),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Selection count
          Text(
            '$totalSelected seçildi',
            style: AppTypography.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Select all button
          _SelectAllButton(
            allDocumentIds: allDocumentIds,
            allFolderIds: allFolderIds,
          ),
          const SizedBox(width: AppSpacing.xs),
          // Actions
          if (!isTrashSection) ...[
            AppIconButton(
              icon: Icons.content_copy,
              variant: AppIconButtonVariant.ghost,
              tooltip: 'Çoğalt',
              onPressed: hasSelection
                  ? () => _duplicateSelected(context, ref, selectedDocs)
                  : null,
            ),
            AppIconButton(
              icon: Icons.drive_file_move_outline,
              variant: AppIconButtonVariant.ghost,
              tooltip: 'Taşı',
              onPressed: hasSelection
                  ? () =>
                      _moveSelected(context, ref, selectedDocs, selectedFolders)
                  : null,
            ),
          ],
          AppIconButton(
            icon: Icons.delete_outline,
            variant: AppIconButtonVariant.ghost,
            tooltip: isTrashSection ? 'Kalıcı Sil' : 'Sil',
            onPressed: hasSelection
                ? () => _deleteSelected(context, ref, selectedDocs)
                : null,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  void _exitSelectionMode(WidgetRef ref) {
    ref.read(selectionModeProvider.notifier).state = false;
    ref.read(selectedDocumentsProvider.notifier).state = {};
    ref.read(selectedFoldersProvider.notifier).state = {};
  }

  Future<void> _duplicateSelected(
      BuildContext context, WidgetRef ref, Set<String> selectedDocs) async {
    if (selectedDocs.isEmpty) return;
    final controller = ref.read(documentsControllerProvider.notifier);
    try {
      await controller.duplicateDocuments(selectedDocs.toList());
      _exitSelectionMode(ref);
      if (context.mounted) {
        AppToast.success(context, '${selectedDocs.length} belge kopyalandı');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Kopyalama başarısız: $e');
      }
    }
  }

  Future<void> _moveSelected(BuildContext context, WidgetRef ref,
      Set<String> selectedDocs, Set<String> selectedFolders) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MoveToFolderDialog(
        documentIds: selectedDocs.toList(),
        folderIds: selectedFolders.toList(),
      ),
    );
    if (result == true) {
      ref.invalidate(foldersProvider);
      ref.invalidate(documentsProvider);
      _exitSelectionMode(ref);
    }
  }

  Future<void> _deleteSelected(
      BuildContext context, WidgetRef ref, Set<String> selectedDocs) async {
    if (selectedDocs.isEmpty) return;

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: isTrashSection ? 'Kalıcı Olarak Sil' : 'Belgeleri Sil',
      message: isTrashSection
          ? '${selectedDocs.length} belge kalıcı olarak silinecek. Bu işlem geri alınamaz!'
          : '${selectedDocs.length} belge çöp kutusuna taşınacak.',
      confirmLabel: 'Sil',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      final controller = ref.read(documentsControllerProvider.notifier);
      try {
        if (isTrashSection) {
          await controller.permanentlyDeleteDocuments(selectedDocs.toList());
        } else {
          await controller.moveDocumentsToTrash(selectedDocs.toList());
        }
        _exitSelectionMode(ref);
        if (context.mounted) {
          AppToast.success(
            context,
            isTrashSection
                ? '${selectedDocs.length} belge silindi'
                : '${selectedDocs.length} belge çöpe taşındı',
          );
        }
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, 'Silme başarısız: $e');
        }
      }
    }
  }
}

/// Select all button
class _SelectAllButton extends ConsumerWidget {
  final List<String> allDocumentIds;
  final List<String> allFolderIds;

  const _SelectAllButton({
    required this.allDocumentIds,
    required this.allFolderIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final selectedFolders = ref.watch(selectedFoldersProvider);

    final allDocsSelected =
        allDocumentIds.isEmpty || selectedDocs.length == allDocumentIds.length;
    final allFoldersSelected =
        allFolderIds.isEmpty || selectedFolders.length == allFolderIds.length;
    final allSelected = allDocsSelected &&
        allFoldersSelected &&
        (allDocumentIds.isNotEmpty || allFolderIds.isNotEmpty);

    return TextButton.icon(
      onPressed: () {
        if (allSelected) {
          ref.read(selectedDocumentsProvider.notifier).state = {};
          ref.read(selectedFoldersProvider.notifier).state = {};
        } else {
          ref.read(selectedDocumentsProvider.notifier).state =
              allDocumentIds.toSet();
          ref.read(selectedFoldersProvider.notifier).state =
              allFolderIds.toSet();
        }
      },
      icon: Icon(
        allSelected ? Icons.check_box : Icons.check_box_outline_blank,
        size: AppIconSize.md,
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
      ),
      label: Text(
        'Tümü',
        style: AppTypography.labelMedium.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
