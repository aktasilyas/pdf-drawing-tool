import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_combined_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_list_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';

/// Routes content based on the selected sidebar section.
class DocumentsContentView extends ConsumerWidget {
  const DocumentsContentView({
    super.key,
    required this.section,
    required this.folderId,
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final SidebarSection section;
  final String? folderId;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (section) {
      case SidebarSection.documents:
        return _DocumentsWithFolders(
          parentFolderId: null,
          onFolderTap: onFolderTap,
          onDocumentTap: onDocumentTap,
          onFolderMore: onFolderMore,
          onDocumentMore: onDocumentMore,
        );
      case SidebarSection.favorites:
        return _SimpleDocumentList(
          documentsAsync: ref.watch(favoriteDocumentsProvider),
          onDocumentTap: onDocumentTap,
          onDocumentMore: onDocumentMore,
        );
      case SidebarSection.trash:
        return _SimpleDocumentList(
          documentsAsync: ref.watch(trashDocumentsProvider),
          onDocumentTap: onDocumentTap,
          onDocumentMore: onDocumentMore,
        );
      case SidebarSection.folder:
        return _DocumentsWithFolders(
          parentFolderId: folderId,
          onFolderTap: onFolderTap,
          onDocumentTap: onDocumentTap,
          onFolderMore: onFolderMore,
          onDocumentMore: onDocumentMore,
        );
      case SidebarSection.shared:
      case SidebarSection.store:
        return const DocumentsComingSoon();
    }
  }
}

/// Loads and displays folders + documents for a given parent folder.
class _DocumentsWithFolders extends ConsumerWidget {
  const _DocumentsWithFolders({
    required this.parentFolderId,
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final String? parentFolderId;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final documentsAsync = ref.watch(documentsProvider(parentFolderId));
    return foldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => DocumentsErrorView(error: error),
      data: (folders) {
        return documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => DocumentsErrorView(error: error),
          data: (documents) {
            final searchQuery = ref.watch(searchQueryProvider);
            // Filter documents
            final filteredDocs = searchQuery.isEmpty
                ? documents
                : documents
                    .where((doc) => doc.title
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();
            // Filter folders by parent
            var filteredFolders = folders
                .where((f) => f.parentId == parentFolderId)
                .toList();
            if (searchQuery.isNotEmpty) {
              filteredFolders = filteredFolders
                  .where((f) => f.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();
            }
            // Empty states
            if (filteredFolders.isEmpty && filteredDocs.isEmpty) {
              if (searchQuery.isNotEmpty) {
                return DocumentsEmptySearchResult(query: searchQuery);
              }
              if (parentFolderId != null) {
                return const DocumentsEmptyFolderView();
              }
              return const DocumentsEmptyState();
            }
            // Sort documents
            final sortedDocs = _sortDocuments(ref, filteredDocs);
            return _buildCombinedView(
              ref,
              filteredFolders,
              sortedDocs,
            );
          },
        );
      },
    );
  }

  Widget _buildCombinedView(
    WidgetRef ref,
    List<Folder> folders,
    List<DocumentInfo> documents,
  ) {
    final viewMode = ref.watch(viewModeProvider);
    if (viewMode == ViewMode.grid) {
      return DocumentsCombinedGridView(
        folders: folders,
        documents: documents,
        onFolderTap: onFolderTap,
        onDocumentTap: onDocumentTap,
        onFolderMore: onFolderMore,
        onDocumentMore: onDocumentMore,
      );
    }
    return DocumentsCombinedListView(
      folders: folders,
      documents: documents,
      onFolderTap: onFolderTap,
      onDocumentTap: onDocumentTap,
      onFolderMore: onFolderMore,
      onDocumentMore: onDocumentMore,
    );
  }
}

/// Simple document list (for favorites, trash) without folders.
class _SimpleDocumentList extends ConsumerWidget {
  const _SimpleDocumentList({
    required this.documentsAsync,
    required this.onDocumentTap,
    required this.onDocumentMore,
  });

  final AsyncValue<List<DocumentInfo>> documentsAsync;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => DocumentsErrorView(error: error),
      data: (documents) {
        if (documents.isEmpty) return const DocumentsEmptyState();
        final viewMode = ref.watch(viewModeProvider);
        final searchQuery = ref.watch(searchQueryProvider);
        final sorted = _sortDocuments(ref, documents);
        final filtered = searchQuery.isEmpty
            ? sorted
            : sorted
                .where((doc) => doc.title
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
                .toList();
        if (filtered.isEmpty && searchQuery.isNotEmpty) {
          return DocumentsEmptySearchResult(query: searchQuery);
        }
        if (viewMode == ViewMode.grid) {
          return _buildSimpleGrid(ref, filtered);
        }
        return DocumentsCombinedListView(
          folders: const [],
          documents: filtered,
          onFolderTap: (_) {},
          onDocumentTap: onDocumentTap,
          onFolderMore: (_) {},
          onDocumentMore: onDocumentMore,
        );
      },
    );
  }

  Widget _buildSimpleGrid(WidgetRef ref, List<DocumentInfo> documents) {
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
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return DocumentCard(
                document: doc,
                onTap: () => onDocumentTap(doc),
                onFavoriteToggle: () => ref
                    .read(documentsControllerProvider.notifier)
                    .toggleFavorite(doc.id),
                onMorePressed: () => onDocumentMore(doc),
              );
            },
          ),
        );
      },
    );
  }
}

/// Sorts documents based on current sort provider state.
List<DocumentInfo> _sortDocuments(
  WidgetRef ref,
  List<DocumentInfo> documents,
) {
  final sortOption = ref.watch(sortOptionProvider);
  final sortDirection = ref.watch(sortDirectionProvider);
  final sorted = List<DocumentInfo>.from(documents);
  switch (sortOption) {
    case SortOption.date:
      sorted.sort((a, b) => sortDirection == SortDirection.descending
          ? b.updatedAt.compareTo(a.updatedAt)
          : a.updatedAt.compareTo(b.updatedAt));
    case SortOption.name:
      sorted.sort((a, b) => sortDirection == SortDirection.descending
          ? b.title.compareTo(a.title)
          : a.title.compareTo(b.title));
    case SortOption.size:
      sorted.sort((a, b) => sortDirection == SortDirection.descending
          ? b.pageCount.compareTo(a.pageCount)
          : a.pageCount.compareTo(b.pageCount));
  }
  return sorted;
}
