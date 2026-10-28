import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/l10n/l10n.dart';

/// Target list of the move dialog: the root option followed by [folders].
class MoveToFolderList extends StatelessWidget {
  const MoveToFolderList({
    super.key,
    required this.folders,
    required this.selectedFolderId,
    required this.isMovingFolder,
    required this.onSelected,
  });

  final List<Folder> folders;
  final String? selectedFolderId;
  final bool isMovingFolder;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty && !isMovingFolder) {
      final l10n = context.l10n;
      return AppEmptyState(
          icon: Icons.folder_outlined,
          title: l10n.libraryNoFoldersYet,
          description: l10n.libraryNoFoldersStartHint);
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: folders.length + 1,
      itemBuilder: (ctx, i) => i == 0
          ? _rootOption(context)
          : _folderOption(context, folders[i - 1]),
    );
  }

  Widget _rootOption(BuildContext context) {
    final palette = context.palette;
    final sel = selectedFolderId == null;
    return ListTile(
      leading: Icon(Icons.home_outlined,
          color: sel ? palette.accent : palette.textMuted),
      title: Text(
          isMovingFolder
              ? context.l10n.libraryRootFolders
              : context.l10n.libraryNoFolderRoot,
          style: AppTypography.bodyLarge.copyWith(
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              color: sel ? palette.accent : palette.textPrimary)),
      trailing: sel ? Icon(Icons.check, color: palette.accent) : null,
      onTap: () => onSelected(null),
    );
  }

  Widget _folderOption(BuildContext context, Folder folder) {
    final palette = context.palette;
    final sel = selectedFolderId == folder.id;
    return ListTile(
      leading: Icon(Icons.folder,
          color: sel ? palette.accent : Color(folder.colorValue)),
      title: Text(folder.name,
          style: AppTypography.bodyLarge
              .copyWith(color: sel ? palette.accent : palette.textPrimary)),
      subtitle: Text(context.l10n.libraryDocumentCount(folder.documentCount),
          style: AppTypography.caption.copyWith(color: palette.textMuted)),
      trailing: sel ? Icon(Icons.check, color: palette.accent) : null,
      onTap: () => onSelected(folder.id),
    );
  }
}
