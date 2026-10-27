/// ElyaNotes Documents Sidebar - flat nav rows and folder list
library;

import 'package:drawing_ui/drawing_ui.dart' show ElyanotesIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar_item.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_tile_art.dart';

/// Library sidebar sections.
///
/// Only sections shipped in v1.0 exist: no Shared/Store placeholders (#249).
/// Sharing (cloud sync) and a store (premium) get real sections when they
/// unfreeze.
enum SidebarSection { documents, favorites, trash, folder }

/// Documents sidebar widget
class DocumentsSidebar extends ConsumerWidget {
  final SidebarSection selectedSection;
  final ValueChanged<SidebarSection> onSectionChanged;
  final String? selectedFolderId;
  final ValueChanged<String>? onFolderSelected;
  final VoidCallback? onCreateFolder;
  final VoidCallback? onCollapse;
  final bool isDrawer;

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
    final palette = context.palette;

    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.xl),
          _navItem(
            icon: ElyanotesIcons.libraryNotebook,
            selectedIcon: ElyanotesIcons.libraryNotebookFill,
            label: 'Tüm Notlar',
            section: SidebarSection.documents,
          ),
          _navItem(
            icon: ElyanotesIcons.libraryStar,
            selectedIcon: ElyanotesIcons.libraryStarFill,
            label: 'Favoriler',
            section: SidebarSection.favorites,
          ),
          _navItem(
            icon: ElyanotesIcons.libraryTrash,
            selectedIcon: ElyanotesIcons.libraryTrashFill,
            label: 'Son Silinenler',
            section: SidebarSection.trash,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFoldersHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: _buildFoldersList(context, foldersAsync),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required SidebarSection section,
  }) {
    return SidebarItem(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      isSelected: selectedSection == section,
      onTap: () => onSectionChanged(section),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textPrimary = context.palette.textPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.lg, AppSpacing.sm, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/images/elyanotes_logo_transparent_logo.png',
                  height: 40,
                  width: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.edit_note_rounded,
                    size: 40,
                    color: context.palette.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'elyanotes',
                  style: TextStyle(
                    fontFamily: 'ComicRelief',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onCollapse != null)
            AppIconButton(
              icon: isDrawer
                  ? ElyanotesIcons.libraryClose
                  : ElyanotesIcons.librarySidebar,
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
    final palette = context.palette;

    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: Padding(
        padding:
            const EdgeInsets.only(left: AppSpacing.lg, right: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Klasörler',
                style: AppTypography.labelMedium
                    .copyWith(color: palette.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/manage-folders'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                'Yönet',
                style:
                    AppTypography.labelMedium.copyWith(color: palette.accent),
              ),
            ),
            AppIconButton(
              icon: ElyanotesIcons.libraryPlus,
              variant: AppIconButtonVariant.ghost,
              size: AppIconButtonSize.small,
              tooltip: 'Yeni Klasör',
              onPressed: onCreateFolder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersList(
      BuildContext context, AsyncValue<List<dynamic>> foldersAsync) {
    return foldersAsync.when(
      data: (folders) {
        final rootFolders = folders.where((f) => f.parentId == null).toList();
        if (rootFolders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Text('Klasör yok',
                style: AppTypography.caption
                    .copyWith(color: context.palette.textMuted)),
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
    final isSel = selectedSection == SidebarSection.folder &&
        selectedFolderId == folder.id;

    return SidebarItem(
      icon: ElyanotesIcons.libraryFolderFill,
      selectedIcon: ElyanotesIcons.libraryFolderFill,
      label: folder.name,
      isSelected: isSel,
      isSubfolder: isSub,
      iconColor: FolderTileArt.tame(Color(folder.colorValue)),
      trailing: Text(
        '${folder.documentCount}',
        style: AppTypography.caption.copyWith(
          color: context.palette.textMuted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      onTap: () => onFolderSelected?.call(folder.id),
    );
  }
}
