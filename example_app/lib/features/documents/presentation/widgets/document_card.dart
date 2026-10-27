/// ElyaNotes Document Card
///
/// Library tile for a document: the cover (or page thumbnail) sits on the
/// background with the title and meta line underneath.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart' show CoverPreviewWidget;

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';
import 'package:example_app/features/documents/presentation/widgets/library_page_thumbnail.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_frame.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import 'package:example_app/l10n/l10n.dart';

class DocumentCard extends ConsumerWidget {
  final DocumentInfo document;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onMorePressed;
  final bool isSelectionMode;
  final bool isSelected;
  final bool isInTrash;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onMorePressed,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isInTrash = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LibraryTileFrame(
      cover: _buildCover(),
      info: LibraryTileInfo(
        title: document.title,
        meta: LibraryMeta.document(document, context.l10n),
        onTap: isSelectionMode ? onTap : onMorePressed,
        showCaret: onMorePressed != null && !isSelectionMode,
      ),
      onTap: onTap,
      onLongPress: () => _handleLongPress(ref),
      semanticLabel: document.title,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      overlays: _buildOverlays,
      artRect: _artRect(),
    );
  }

  void _handleLongPress(WidgetRef ref) {
    if (!isSelectionMode) {
      ref.read(selectionModeProvider.notifier).state = true;
      ref.read(selectedDocumentsProvider.notifier).state = {document.id};
    } else {
      onLongPress?.call();
    }
  }

  Rect Function(Size)? _artRect() {
    if (_coverOrNull() != null) return null;
    return (box) => LibraryPageThumbnail.pageRect(document, box);
  }

  core.Cover? _coverOrNull() {
    final coverId = document.coverId;
    if (!document.hasCover || coverId == null) return null;
    return core.CoverRegistry.byId(coverId);
  }

  Widget _buildCover() {
    final cover = _coverOrNull();
    if (cover != null) {
      return CoverPreviewWidget(
        cover: cover,
        title: document.title,
        showBorder: false,
      );
    }
    return LibraryPageThumbnail(document: document);
  }

  List<Widget> _buildOverlays(Rect board) {
    const hit = LibraryFavoriteBadge.hitSize;
    const disc = LibraryFavoriteBadge.discSize;
    const inset = AppSpacing.sm;
    final deletedAt = document.deletedAt;
    return [
      if (document.isFavorite && !isSelectionMode)
        Positioned(
          left: board.right - inset - disc - (hit - disc) / 2,
          top: board.bottom - inset - disc - (hit - disc) / 2,
          child: LibraryFavoriteBadge(onTap: onFavoriteToggle),
        ),
      if (isInTrash && deletedAt != null)
        Positioned.fromRect(
          rect: board.deflate(inset),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: DocumentDaysLeftBadge(deletedAt: deletedAt),
          ),
        ),
    ];
  }
}
