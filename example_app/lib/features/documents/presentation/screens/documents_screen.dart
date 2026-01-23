import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/constants/documents_strings.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/document_grid.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_dialog.dart';
import 'package:example_app/features/documents/presentation/widgets/document_context_menu.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  SidebarSection _selectedSection = SidebarSection.allDocuments;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewMode = ref.watch(viewModeProvider);
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedSection: _selectedSection,
            onSectionTap: (section) {
              setState(() {
                _selectedSection = section;
              });
            },
            onFolderTap: (folderId) {
              // TODO: Handle folder tap
            },
            onNewFolderPressed: _showNewFolderDialog,
          ),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // App bar
                _buildAppBar(theme, viewMode),
                
                // Documents content
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, ViewMode viewMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Text(
            _getSectionTitle(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Search bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: DocumentsStrings.searchDocuments,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  // Update search query
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // View mode toggle
          IconButton(
            icon: Icon(
              viewMode == ViewMode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () {
              ref.read(viewModeProvider.notifier).state =
                  viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
            },
            tooltip: viewMode == ViewMode.grid
                ? 'Liste görünümü'
                : 'Grid görünümü',
          ),
          
          const SizedBox(width: 8),
          
          // New document button
          FilledButton.icon(
            onPressed: _showNewDocumentDialog,
            icon: const Icon(Icons.add),
            label: const Text(DocumentsStrings.newDocument),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // If searching, show search results
    final searchQuery = ref.watch(searchQueryProvider);
    if (searchQuery.isNotEmpty) {
      return _buildSearchResults(searchQuery);
    }

    // Otherwise show section content
    switch (_selectedSection) {
      case SidebarSection.allDocuments:
        return _buildAllDocuments();
      case SidebarSection.favorites:
        return _buildFavorites();
      case SidebarSection.recent:
        return _buildRecent();
      case SidebarSection.trash:
        return _buildTrash();
    }
  }

  Widget _buildAllDocuments() {
    final folderId = ref.watch(currentFolderIdProvider);
    final documentsAsync = ref.watch(documentsProvider(folderId));
    
    return documentsAsync.when(
      data: (documents) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(documentsProvider(folderId));
        },
        child: DocumentGrid(
          documents: documents,
          emptyTitle: DocumentsStrings.noDocuments,
          emptyDescription: DocumentsStrings.noDocumentsDescription,
          onDocumentTap: _openDocument,
          onFavoriteToggle: (document) => _toggleFavorite(document.id),
          onMorePressed: (document) => _showContextMenu(document),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          DocumentsStrings.errorLoadingDocuments,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildFavorites() {
    final favoritesAsync = ref.watch(favoriteDocumentsProvider);
    
    return favoritesAsync.when(
      data: (documents) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(favoriteDocumentsProvider);
        },
        child: DocumentGrid(
          documents: documents,
          emptyTitle: DocumentsStrings.noFavorites,
          emptyDescription: DocumentsStrings.noFavoritesDescription,
          onDocumentTap: _openDocument,
          onFavoriteToggle: (document) => _toggleFavorite(document.id),
          onMorePressed: (document) => _showContextMenu(document),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          DocumentsStrings.errorLoadingDocuments,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildRecent() {
    final recentAsync = ref.watch(recentDocumentsProvider);
    
    return recentAsync.when(
      data: (documents) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentDocumentsProvider);
        },
        child: DocumentGrid(
          documents: documents,
          emptyTitle: DocumentsStrings.noRecent,
          emptyDescription: DocumentsStrings.noRecentDescription,
          onDocumentTap: _openDocument,
          onFavoriteToggle: (document) => _toggleFavorite(document.id),
          onMorePressed: (document) => _showContextMenu(document),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          DocumentsStrings.errorLoadingDocuments,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildTrash() {
    final trashAsync = ref.watch(trashDocumentsProvider);
    
    return trashAsync.when(
      data: (documents) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trashDocumentsProvider);
        },
        child: DocumentGrid(
          documents: documents,
          emptyTitle: DocumentsStrings.noTrash,
          emptyDescription: DocumentsStrings.noTrashDescription,
          onDocumentTap: _openDocument,
          onMorePressed: (document) => _showTrashContextMenu(document),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          DocumentsStrings.errorLoadingDocuments,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    final searchAsync = ref.watch(searchResultsProvider);
    
    return searchAsync.when(
      data: (documents) => DocumentGrid(
        documents: documents,
        emptyTitle: DocumentsStrings.noSearchResults,
        emptyDescription: DocumentsStrings.noSearchResultsDescription,
        onDocumentTap: _openDocument,
        onFavoriteToggle: (document) => _toggleFavorite(document.id),
        onMorePressed: (document) => _showContextMenu(document),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          DocumentsStrings.errorLoadingDocuments,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  String _getSectionTitle() {
    switch (_selectedSection) {
      case SidebarSection.allDocuments:
        return DocumentsStrings.myDocuments;
      case SidebarSection.favorites:
        return DocumentsStrings.favorites;
      case SidebarSection.recent:
        return DocumentsStrings.recent;
      case SidebarSection.trash:
        return DocumentsStrings.trash;
    }
  }

  void _openDocument(DocumentInfo document) {
    context.push('/editor/${document.id}');
  }

  Future<void> _toggleFavorite(String documentId) async {
    try {
      await ref
          .read(documentsControllerProvider.notifier)
          .toggleFavorite(documentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _showContextMenu(DocumentInfo document) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DocumentContextMenu(
        document: document,
        onRename: () => _renameDocument(document),
        onMove: () => _moveDocument(document),
        onToggleFavorite: () => _toggleFavorite(document.id),
        onMoveToTrash: () => _moveToTrash(document.id),
      ),
    );
  }

  void _showTrashContextMenu(DocumentInfo document) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DocumentContextMenu(
        document: document,
        isInTrash: true,
        onRestore: () => _restoreFromTrash(document.id),
        onDeletePermanently: () => _deletePermanently(document.id),
      ),
    );
  }

  void _showNewDocumentDialog() {
    showNewDocumentSheet(context);
  }

  void _showNewFolderDialog() {
    // TODO: Implement new folder dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Klasör oluşturma yakında eklenecek')),
    );
  }

  void _renameDocument(DocumentInfo document) {
    // TODO: Implement rename dialog
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yeniden adlandırma yakında eklenecek')),
    );
  }

  void _moveDocument(DocumentInfo document) {
    // TODO: Implement move dialog
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Taşıma yakında eklenecek')),
    );
  }

  Future<void> _moveToTrash(String documentId) async {
    Navigator.pop(context);
    
    try {
      await ref
          .read(documentsControllerProvider.notifier)
          .moveToTrash(documentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge çöpe taşındı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _restoreFromTrash(String documentId) async {
    Navigator.pop(context);
    
    try {
      await ref
          .read(documentsControllerProvider.notifier)
          .restoreFromTrash(documentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge geri yüklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _deletePermanently(String documentId) async {
    Navigator.pop(context);
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalıcı Olarak Sil'),
        content: const Text(
          'Bu belge kalıcı olarak silinecek ve geri getirilemeyecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(DocumentsStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(DocumentsStrings.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    
    try {
      await ref
          .read(documentsControllerProvider.notifier)
          .deleteDocument(documentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge kalıcı olarak silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
