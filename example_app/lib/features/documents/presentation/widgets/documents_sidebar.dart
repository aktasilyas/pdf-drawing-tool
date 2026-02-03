/// StarNote Documents Sidebar - Design system sidebar component
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar_item.dart';

/// Sidebar bölüm tipleri
enum SidebarSection { documents, favorites, shared, store, trash, folder }

/// Documents sidebar widget
class DocumentsSidebar extends ConsumerWidget {
  final SidebarSection selectedSection;
  final ValueChanged<SidebarSection> onSectionChanged;
  final String? selectedFolderId;
  final ValueChanged<String>? onFolderSelected;
  final VoidCallback? onCreateFolder;

  const DocumentsSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
    this.selectedFolderId,
    this.onFolderSelected,
    this.onCreateFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: AppSpacing.sidebarWidth,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: AppSearchField(
              hint: 'Ara...',
              onChanged: (q) => ref.read(searchQueryProvider.notifier).state = q,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SidebarItem(
                    icon: Icons.description_outlined,
                    selectedIcon: Icons.description,
                    label: 'Tüm Notlar',
                    isSelected: selectedSection == SidebarSection.documents,
                    onTap: () => onSectionChanged(SidebarSection.documents),
                  ),
                  SidebarItem(
                    icon: Icons.star_outline,
                    selectedIcon: Icons.star,
                    label: 'Favoriler',
                    isSelected: selectedSection == SidebarSection.favorites,
                    onTap: () => onSectionChanged(SidebarSection.favorites),
                    iconColor: selectedSection == SidebarSection.favorites
                        ? AppColors.accent : null,
                  ),
                  SidebarItem(
                    icon: Icons.delete_outline,
                    selectedIcon: Icons.delete,
                    label: 'Son Silinenler',
                    isSelected: selectedSection == SidebarSection.trash,
                    onTap: () => onSectionChanged(SidebarSection.trash),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: AppDivider(),
                  ),
                  _buildFoldersHeader(context),
                  _buildFoldersList(foldersAsync),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: AppDivider(),
                  ),
                  _buildTagsPlaceholder(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.md, AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.edit_note,
                color: AppColors.onPrimary, size: AppIconSize.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('StarNote',
              style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryLight, fontWeight: FontWeight.w700),
            ),
          ),
          AppIconButton(
            icon: Icons.settings_outlined,
            variant: AppIconButtonVariant.ghost,
            size: AppIconButtonSize.small,
            tooltip: 'Ayarlar',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersHeader(BuildContext context) {
    return AppSectionHeader(
      title: 'Klasörler',
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => context.push('/manage-folders'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Yönet',
              style: AppTypography.caption.copyWith(color: AppColors.primary)),
          ),
          AppIconButton(
            icon: Icons.add,
            variant: AppIconButtonVariant.ghost,
            size: AppIconButtonSize.small,
            tooltip: 'Yeni Klasör',
            onPressed: onCreateFolder,
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersList(AsyncValue<List<dynamic>> foldersAsync) {
    return foldersAsync.when(
      data: (folders) {
        final rootFolders = folders.where((f) => f.parentId == null).toList();
        if (rootFolders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Text('Klasör yok',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiaryLight)),
          );
        }
        final widgets = <Widget>[];
        for (final folder in rootFolders) {
          widgets.add(_buildFolderItem(folder, false));
          final subs = folders.where((f) => f.parentId == folder.id).toList();
          for (final sub in subs) widgets.add(_buildFolderItem(sub, true));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: widgets);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFolderItem(dynamic folder, bool isSub) {
    final isSel = selectedSection == SidebarSection.folder &&
        selectedFolderId == folder.id;
    return SidebarItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: folder.name,
      isSelected: isSel,
      isSubfolder: isSub,
      iconColor: Color(folder.colorValue),
      trailing: Text('${folder.documentCount}',
        style: AppTypography.caption.copyWith(
            color: isSel ? AppColors.primary : AppColors.textTertiaryLight)),
      onTap: () => onFolderSelected?.call(folder.id),
    );
  }

  Widget _buildTagsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Etiketler',
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.label_outline,
                  size: AppIconSize.md, color: AppColors.textTertiaryLight),
              const SizedBox(width: AppSpacing.sm),
              Text('Yakında...',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiaryLight)),
            ],
          ),
        ),
      ],
    );
  }
}
