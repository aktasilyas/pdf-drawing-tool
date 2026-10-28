import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/theme/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/document_sort.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/entities/library_text.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_combined_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_list_view.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/trash_content_view.dart';
import 'package:example_app/l10n/l10n.dart';

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
    this.onTrashedPageTap,
    this.onCreateNew,
  });

  final SidebarSection section;
  final String? folderId;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;
  final ValueChanged<TrashedPage>? onTrashedPageTap;

  /// Call to action of the root empty state.
  final VoidCallback? onCreateNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (section) {
      case SidebarSection.documents:
        return _DocumentsWithFolders(
          parentFolderId: null,
          onCreateNew: onCreateNew,
          onFolderTap: onFolderTap,
          onDocumentTap: onDocumentTap,
          onFolderMore: onFolderMore,
          onDocumentMore: onDocumentMore,
        );
      case SidebarSection.favorites:
        return _FavoritesView(
          onFolderTap: onFolderTap,
          onDocumentTap: onDocumentTap,
          onFolderMore: onFolderMore,
          onDocumentMore: onDocumentMore,
        );
      case SidebarSection.trash:
        return TrashContentView(
          onDocumentTap: onDocumentTap,
          onDocumentMore: onDocumentMore,
          onTrashedPageTap: onTrashedPageTap ?? (_) {},
        );
      case SidebarSection.folder:
        return _DocumentsWithFolders(
          parentFolderId: folderId,
          onFolderTap: onFolderTap,
          onDocumentTap: onDocumentTap,
          onFolderMore: onFolderMore,
          onDocumentMore: onDocumentMore,
        );
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
    this.onCreateNew,
  });

  final VoidCallback? onCreateNew;
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
      error: (error, st) => libraryLoadErrorView(
        'Folders',
        error,
        st,
        message: context.l10n.libraryFoldersLoadFailed,
        onRetry: () => ref.invalidate(foldersProvider),
      ),
      data: (folders) {
        return documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, st) => libraryLoadErrorView(
            'Documents',
            error,
            st,
            message: context.l10n.libraryLoadFailed,
            onRetry: () => ref.invalidate(documentsProvider(parentFolderId)),
          ),
          data: (documents) {
            final searchQuery = ref.watch(searchQueryProvider);
            // Filter documents
            final filteredDocs = searchQuery.isEmpty
                ? documents
                : documents
                    .where((doc) => matchesSearch(doc.title, searchQuery))
                    .toList();
            // Filter folders by parent
            var filteredFolders =
                folders.where((f) => f.parentId == parentFolderId).toList();
            if (searchQuery.isNotEmpty) {
              filteredFolders = filteredFolders
                  .where((f) => matchesSearch(f.name, searchQuery))
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
              return DocumentsEmptyState(onCreateNew: onCreateNew);
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
    return _ViewModeSwitcher(
      folders: folders,
      documents: documents,
      onFolderTap: onFolderTap,
      onDocumentTap: onDocumentTap,
      onFolderMore: onFolderMore,
      onDocumentMore: onDocumentMore,
    );
  }
}

/// Favorites view - shows both favorite folders and favorite documents.
class _FavoritesView extends ConsumerWidget {
  const _FavoritesView({
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favFoldersAsync = ref.watch(favoriteFoldersProvider);
    final favDocsAsync = ref.watch(favoriteDocumentsProvider);

    return favFoldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => libraryLoadErrorView(
        'Favorite folders',
        error,
        st,
        message: context.l10n.libraryFoldersLoadFailed,
        onRetry: () => ref.invalidate(favoriteFoldersProvider),
      ),
      data: (folders) {
        return favDocsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, st) => libraryLoadErrorView(
            'Favorite documents',
            error,
            st,
            message: context.l10n.libraryLoadFailed,
            onRetry: () => ref.invalidate(favoriteDocumentsProvider),
          ),
          data: (documents) {
            if (folders.isEmpty && documents.isEmpty) {
              return const FavoritesEmptyState();
            }
            final sorted = _sortDocuments(ref, documents);
            return _ViewModeSwitcher(
              folders: folders,
              documents: sorted,
              onFolderTap: onFolderTap,
              onDocumentTap: onDocumentTap,
              onFolderMore: onFolderMore,
              onDocumentMore: onDocumentMore,
            );
          },
        );
      },
    );
  }
}

/// Grid or list for the current [ViewMode], cross-faded on change.
class _ViewModeSwitcher extends ConsumerWidget {
  const _ViewModeSwitcher({
    required this.folders,
    required this.documents,
    required this.onFolderTap,
    required this.onDocumentTap,
    required this.onFolderMore,
    required this.onDocumentMore,
  });

  final List<Folder> folders;
  final List<DocumentInfo> documents;
  final ValueChanged<Folder> onFolderTap;
  final ValueChanged<DocumentInfo> onDocumentTap;
  final ValueChanged<Folder> onFolderMore;
  final ValueChanged<DocumentInfo> onDocumentMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppCurves.fade,
      switchOutCurve: AppCurves.fade,
      child: KeyedSubtree(
        key: ValueKey(viewMode),
        child: viewMode == ViewMode.grid
            ? DocumentsCombinedGridView(
                folders: folders,
                documents: documents,
                onFolderTap: onFolderTap,
                onDocumentTap: onDocumentTap,
                onFolderMore: onFolderMore,
                onDocumentMore: onDocumentMore,
              )
            : DocumentsCombinedListView(
                folders: folders,
                documents: documents,
                onFolderTap: onFolderTap,
                onDocumentTap: onDocumentTap,
                onFolderMore: onFolderMore,
                onDocumentMore: onDocumentMore,
              ),
      ),
    );
  }
}

/// Sorts documents by the sort menu state; "Favorileri üste sabitle" puts
/// favourites first.
List<DocumentInfo> _sortDocuments(
  WidgetRef ref,
  List<DocumentInfo> documents,
) =>
    sortDocuments(
      documents,
      option: ref.watch(sortOptionProvider),
      direction: ref.watch(sortDirectionProvider),
      pinFavorites: ref.watch(pinFavoritesProvider),
    );
