import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/trashed_page_card.dart';

/// Renders combined trash items (documents + pages) in a grid.
class TrashContentView extends ConsumerWidget {
  const TrashContentView({
    super.key,
    required this.onDocumentTap,
    required this.onDocumentMore,
    required this.onTrashedPageTap,
  });

  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<DocumentInfo> onDocumentMore;
  final ValueChanged<TrashedPage> onTrashedPageTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(trashItemsProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => DocumentsErrorView(error: error),
      data: (items) {
        if (items.isEmpty) return const DocumentsEmptyState();
        return _buildGrid(ref, items);
      },
    );
  }

  Widget _buildGrid(WidgetRef ref, List<TrashItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width < 600 ? 160.0 : 180.0;
        final spacing = width < 600 ? 16.0 : 24.0;
        final padding = width < 600 ? 16.0 : 32.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: cardWidth,
              childAspectRatio: 0.68,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return switch (item) {
                TrashDocumentItem(:final document) => DocumentCard(
                    document: document,
                    isInTrash: true,
                    onTap: () => onDocumentTap(document),
                    onMorePressed: () => onDocumentMore(document),
                  ),
                TrashPageItem(:final page) => TrashedPageCard(
                    trashedPage: page,
                    onTap: () => onTrashedPageTap(page),
                  ),
              };
            },
          ),
        );
      },
    );
  }
}
