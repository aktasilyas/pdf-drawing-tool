import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_ui/drawing_ui.dart' show CoverPreviewWidget;

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/library_list_row.dart';
import 'package:example_app/features/documents/presentation/widgets/library_page_thumbnail.dart';
import 'package:example_app/features/documents/presentation/widgets/library_tile_parts.dart';
import 'package:example_app/l10n/l10n.dart';

/// List tile for a document row.
class DocumentListTile extends ConsumerWidget {
  const DocumentListTile({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
  });

  final DocumentInfo document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelectionMode = ref.watch(selectionModeProvider);
    final isSelected =
        ref.watch(selectedDocumentsProvider).contains(document.id);

    return LibraryListRow(
      thumbnail: _thumbnail(),
      title: document.title,
      meta: LibraryMeta.document(document, context.l10n),
      onTap: onTap,
      onLongPress: onLongPress,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      isFavorite: document.isFavorite,
      onFavoriteTap: () => ref
          .read(documentsControllerProvider.notifier)
          .toggleFavorite(document.id),
    );
  }

  Widget _thumbnail() {
    final coverId = document.coverId;
    final cover = document.hasCover && coverId != null
        ? core.CoverRegistry.byId(coverId)
        : null;
    if (cover != null) {
      return CoverPreviewWidget(cover: cover, title: '', showBorder: false);
    }
    return LibraryPageThumbnail(document: document);
  }
}
