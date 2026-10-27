import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_tile_art.dart';
import 'package:example_app/features/documents/presentation/widgets/library_list_row.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import 'package:example_app/l10n/l10n.dart';

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
    final isSelectionMode = ref.watch(selectionModeProvider);
    final isSelected = ref.watch(selectedFoldersProvider).contains(folder.id);

    return LibraryListRow(
      thumbnail: CustomPaint(
        painter: FolderTileArt(
          color: Color(folder.colorValue),
          palette: context.palette,
        ),
      ),
      title: folder.name,
      meta: LibraryMeta.folder(folder, context.l10n),
      onTap: onTap,
      onLongPress: onLongPress,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
    );
  }
}
