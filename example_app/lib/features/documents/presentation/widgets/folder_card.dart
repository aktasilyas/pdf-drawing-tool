/// ElyaNotes Folder Card
///
/// Library tile for a folder: same footprint and info block as DocumentCard,
/// with an original drawn folder as the art.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_tile_art.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_frame.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import 'package:example_app/l10n/l10n.dart';

class FolderCard extends ConsumerWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;
  final bool isSelected;
  final bool isSelectionMode;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    this.onMorePressed,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LibraryTileFrame(
      cover: CustomPaint(
        painter: FolderTileArt(
          color: Color(folder.colorValue),
          palette: context.palette,
        ),
      ),
      info: LibraryTileInfo(
        title: folder.name,
        meta: LibraryMeta.folder(folder, context.l10n),
        onTap: isSelectionMode ? onTap : onMorePressed,
        showCaret: onMorePressed != null && !isSelectionMode,
        caretKey: const Key('folder_card_more_button'),
      ),
      onTap: onTap,
      onLongPress: () => _handleLongPress(ref),
      semanticLabel: folder.name,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      overlays: (board) => _buildOverlays(ref, board),
      artRect: FolderTileArt.bodyRect,
    );
  }

  List<Widget> _buildOverlays(WidgetRef ref, Rect board) {
    const hit = LibraryFavoriteBadge.hitSize;
    const disc = LibraryFavoriteBadge.discSize;
    const inset = AppSpacing.sm;
    return [
      if (folder.isFavorite && !isSelectionMode)
        Positioned(
          left: board.right - inset - disc - (hit - disc) / 2,
          top: board.bottom - inset - disc - (hit - disc) / 2,
          child: LibraryFavoriteBadge(
            onTap: () => ref
                .read(foldersControllerProvider.notifier)
                .toggleFavorite(folder.id),
          ),
        ),
    ];
  }

  void _handleLongPress(WidgetRef ref) {
    if (!isSelectionMode) {
      ref.read(selectionModeProvider.notifier).state = true;
      ref.read(selectedFoldersProvider.notifier).state = {folder.id};
    }
  }
}
