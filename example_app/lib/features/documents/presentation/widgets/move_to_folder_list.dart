import 'package:flutter/material.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';

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
      return const AppEmptyState(
          icon: Icons.folder_outlined,
          title: 'Henüz klasör yok',
          description: 'Yeni klasör oluşturarak başlayın');
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
      title: Text(isMovingFolder ? 'Ana Klasörler' : 'Belgeler (Klasörsüz)',
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
      subtitle: Text('${folder.documentCount} belge',
          style: AppTypography.caption.copyWith(color: palette.textMuted)),
      trailing: sel ? Icon(Icons.check, color: palette.accent) : null,
      onTap: () => onSelected(folder.id),
    );
  }
}
