/// ElyaNotes Documents Sidebar - Design system sidebar component
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
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
  final VoidCallback? onCollapse; // Sidebar collapse/close callback
  final bool isDrawer; // true = phone drawer, false = tablet sidebar

  const DocumentsSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
    this.selectedFolderId,
    this.onFolderSelected,
    this.onCreateFolder,
    this.onCollapse,
    this.isDrawer = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: AppSpacing.sidebarWidth,
      color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.xs),
          // Sabit menü öğeleri
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
                ? AppColors.accent
                : null,
          ),
          SidebarItem(
            icon: Icons.delete_outline,
            selectedIcon: Icons.delete,
            label: 'Son Silinenler',
            isSelected: selectedSection == SidebarSection.trash,
            onTap: () => onSectionChanged(SidebarSection.trash),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppDivider(),
          ),
          // Klasörler başlığı (sabit)
          _buildFoldersHeader(context),
          // Klasör listesi (sadece burası scroll)
          Expanded(
            child: SingleChildScrollView(
              child: _buildFoldersList(context, foldersAsync),
            ),
          ),
          // Alt bölüm (sabit)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AppDivider(),
          ),
          _buildTagsPlaceholder(context),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              isDark
                  ? 'assets/images/elyanotes_logo_transparent.png'
                  : 'assets/images/elyanotes_logo.png',
              height: 72,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) => Text(
                'ElyaNotes',
                style: GoogleFonts.lobsterTwo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
          ),
          // Collapse/Close button instead of Settings
          if (onCollapse != null)
            AppIconButton(
              icon: isDrawer ? Icons.close : Icons.chevron_left,
              variant: AppIconButtonVariant.ghost,
              size: AppIconButtonSize.small,
              tooltip: isDrawer ? 'Kapat' : 'Daralt',
              onPressed: onCollapse,
            ),
        ],
      ),
    );
  }

  Widget _buildFoldersHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppSectionHeader(
      title: 'Klasörler',
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
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
                style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.accent : AppColors.primary)),
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

  Widget _buildFoldersList(
      BuildContext context, AsyncValue<List<dynamic>> foldersAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tertiaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return foldersAsync.when(
      data: (folders) {
        final rootFolders = folders.where((f) => f.parentId == null).toList();
        if (rootFolders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Text('Klasör yok',
                style: AppTypography.caption.copyWith(color: tertiaryColor)),
          );
        }
        final widgets = <Widget>[];
        for (final folder in rootFolders) {
          widgets.add(_buildFolderItem(context, folder, false));
          final subs = folders.where((f) => f.parentId == folder.id).toList();
          for (final sub in subs) {
            widgets.add(_buildFolderItem(context, sub, true));
          }
        }
        return Column(mainAxisSize: MainAxisSize.min, children: widgets);
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFolderItem(BuildContext context, dynamic folder, bool isSub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSel = selectedSection == SidebarSection.folder &&
        selectedFolderId == folder.id;
    final tertiaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return SidebarItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: folder.name,
      isSelected: isSel,
      isSubfolder: isSub,
      iconColor: Color(folder.colorValue),
      trailing: Text('${folder.documentCount}',
          style: AppTypography.caption.copyWith(
              color: isSel
                  ? (isDark ? AppColors.accent : AppColors.primary)
                  : tertiaryColor)),
      onTap: () => onFolderSelected?.call(folder.id),
    );
  }

  Widget _buildTagsPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tertiaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Etiketler',
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(Icons.label_outline,
                  size: AppIconSize.sm, color: tertiaryColor),
              const SizedBox(width: AppSpacing.sm),
              Text('Yakında...',
                  style: AppTypography.caption.copyWith(color: tertiaryColor)),
            ],
          ),
        ),
      ],
    );
  }
}
