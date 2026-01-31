import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_dialog.dart';
import 'package:example_app/features/editor/presentation/providers/editor_provider.dart';
import 'package:drawing_ui/drawing_ui.dart';
import 'package:drawing_core/drawing_core.dart' as core;

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final GlobalKey _addButtonKey = GlobalKey();
  SidebarSection _selectedSection = SidebarSection.documents;
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      drawer: isMobile ? _buildSidebarDrawer() : null,
      body: isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  // Mobile layout - no persistent sidebar, use drawer
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mobile header with hamburger menu
        Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSectionTitle(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    context.push('/settings');
                  },
                ),
              ],
            ),
          ),
        ),

        // Header
        DocumentsHeader(
          title: _getSectionTitle(),
          newButtonKey: _addButtonKey,
          onNewPressed: _showNewDocumentDialog,
          sortOption: ref.watch(sortOptionProvider),
          onSortChanged: (option) {
            ref.read(sortOptionProvider.notifier).set(option);
          },
          isSelectionMode: _isSelectionMode,
          onSelectionToggle: () {
            setState(() => _isSelectionMode = !_isSelectionMode);
          },
        ),

        // Divider
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).dividerColor.withValues(alpha: 0.0),
                Theme.of(context).dividerColor.withValues(alpha: 0.3),
                Theme.of(context).dividerColor.withValues(alpha: 0.3),
                Theme.of(context).dividerColor.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.1, 0.9, 1.0],
            ),
          ),
        ),

        // Document grid
        Expanded(
          child: _buildDocumentGrid(),
        ),
      ],
    );
  }

  // Desktop layout - persistent sidebar
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar
        Sidebar(
          selectedSection: _selectedSection,
          onSectionChanged: (section) {
            setState(() => _selectedSection = section);
          },
        ),

        // Vertical divider
        Container(
          width: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).dividerColor.withValues(alpha: 0.0),
                Theme.of(context).dividerColor.withValues(alpha: 0.5),
                Theme.of(context).dividerColor.withValues(alpha: 0.5),
                Theme.of(context).dividerColor.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.1, 0.9, 1.0],
            ),
          ),
        ),

        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Settings icon (top right)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      context.push('/settings');
                    },
                  ),
                ),
              ),

              // Header
              DocumentsHeader(
                title: _getSectionTitle(),
                newButtonKey: _addButtonKey,
                onNewPressed: _showNewDocumentDialog,
                sortOption: ref.watch(sortOptionProvider),
                onSortChanged: (option) {
                  ref.read(sortOptionProvider.notifier).set(option);
                },
                isSelectionMode: _isSelectionMode,
                onSelectionToggle: () {
                  setState(() => _isSelectionMode = !_isSelectionMode);
                },
              ),

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).dividerColor.withValues(alpha: 0.0),
                      Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      Theme.of(context).dividerColor.withValues(alpha: 0.3),
                      Theme.of(context).dividerColor.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.1, 0.9, 1.0],
                  ),
                ),
              ),

              // Document grid
              Expanded(
                child: _buildDocumentGrid(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Sidebar drawer for mobile
  Widget _buildSidebarDrawer() {
    return Drawer(
      child: Sidebar(
        selectedSection: _selectedSection,
        onSectionChanged: (section) {
          setState(() => _selectedSection = section);
          Navigator.pop(context); // Close drawer after selection
        },
      ),
    );
  }

  // Document grid (shared by both layouts)
  Widget _buildDocumentGrid() {
    return _buildContent();
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case SidebarSection.documents:
        return _buildDocumentGridContent(ref.watch(documentsProvider(null)));
      case SidebarSection.favorites:
        return _buildDocumentGridContent(ref.watch(favoriteDocumentsProvider));
      case SidebarSection.trash:
        return _buildDocumentGridContent(ref.watch(trashDocumentsProvider));
      case SidebarSection.shared:
      case SidebarSection.store:
        return _buildComingSoon();
    }
  }

  String _getSectionTitle() {
    switch (_selectedSection) {
      case SidebarSection.documents:
        return 'Belgeler';
      case SidebarSection.favorites:
        return 'Sık Kullanılanlar';
      case SidebarSection.shared:
        return 'Paylaşılan';
      case SidebarSection.store:
        return 'Mağaza';
      case SidebarSection.trash:
        return 'Çöp';
    }
  }

  Widget _buildDocumentGridContent(AsyncValue<List<DocumentInfo>> documentsAsync) {
    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Hata: $error'),
          ],
        ),
      ),
      data: (documents) {
        if (documents.isEmpty) {
          return _buildEmptyState();
        }

        // Sort documents
        final sortOption = ref.watch(sortOptionProvider);
        final sortDirection = ref.watch(sortDirectionProvider);
        final viewMode = ref.watch(viewModeProvider);
        final sorted = List<DocumentInfo>.from(documents);
        
        switch (sortOption) {
          case SortOption.date:
            sorted.sort((a, b) => sortDirection == SortDirection.descending
                ? b.updatedAt.compareTo(a.updatedAt)
                : a.updatedAt.compareTo(b.updatedAt));
            break;
          case SortOption.name:
            sorted.sort((a, b) => sortDirection == SortDirection.descending
                ? b.title.compareTo(a.title)
                : a.title.compareTo(b.title));
            break;
          case SortOption.size:
            sorted.sort((a, b) => sortDirection == SortDirection.descending
                ? b.pageCount.compareTo(a.pageCount)
                : a.pageCount.compareTo(b.pageCount));
            break;
        }

        // Render based on view mode
        return viewMode == ViewMode.grid
            ? _buildGridView(sorted)
            : _buildListView(sorted);
      },
    );
  }

  // Grid view layout
  Widget _buildGridView(List<DocumentInfo> documents) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive card size based on available width
        final width = constraints.maxWidth;
        final cardWidth = width < 600 ? 160.0 : 180.0;
        final spacing = width < 600 ? 16.0 : 24.0;
        final padding = width < 600 ? 16.0 : 32.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: cardWidth,
              childAspectRatio: 0.68, // Slightly shorter for mobile
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return DocumentCard(
                document: doc,
                onTap: () => _openDocument(doc.id),
                onFavoriteToggle: () => _toggleFavorite(doc.id),
                onMorePressed: () => _showDocumentMenu(doc),
              );
            },
          ),
        );
      },
    );
  }

  // List view layout
  Widget _buildListView(List<DocumentInfo> documents) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final padding = width < 600 ? 16.0 : 32.0;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openDocument(doc.id),
                  onLongPress: () => _showDocumentMenu(doc),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Thumbnail preview (same as grid view)
                        DocumentCard(
                          document: doc,
                          onTap: () => _openDocument(doc.id),
                          onFavoriteToggle: () => _toggleFavorite(doc.id),
                          onMorePressed: () => _showDocumentMenu(doc),
                        ).build(context, ref)
                            .runtimeType == Column
                            ? _buildCompactThumbnail(doc)
                            : Container(
                                width: 64,
                                height: 85,
                                decoration: BoxDecoration(
                                  color: _getPaperColor(doc.paperColor),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Stack(
                                    children: [
                                      // Thumbnail
                                      _buildListThumbnail(doc),
                                      
                                      // Page count badge
                                      if (doc.pageCount > 1)
                                        Positioned(
                                          bottom: 3,
                                          right: 3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              '${doc.pageCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                        
                        const SizedBox(width: 12),
                        
                        // Document info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(doc.updatedAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Favorite star and chevron
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (doc.isFavorite)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Build thumbnail for list view (compact version)
  Widget _buildListThumbnail(DocumentInfo doc) {
    // Cover preview if available
    if (doc.hasCover && doc.coverId != null) {
      final cover = core.CoverRegistry.byId(doc.coverId!);
      if (cover != null) {
        return CoverPreviewWidget(
          cover: cover,
          title: doc.title,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }
    
    // Template placeholder
    return Container(
      color: _getPaperColor(doc.paperColor),
      child: Center(
        child: Icon(
          Icons.description_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _getPaperColor(String paperColor) {
    switch (paperColor) {
      case 'Beyaz kağıt':
        return const Color(0xFFFFFFFF);
      case 'Sarı kağıt':
      case 'Krem kağıt':
        return const Color(0xFFFFFDE7);
      case 'Gri kağıt':
      case 'Açık Gri':
        return const Color(0xFFF5F5F5);
      case 'Siyah kağıt':
        return const Color(0xFF212121);
      case 'Açık Yeşil':
        return const Color(0xFFE8F5E9);
      case 'Açık Mavi':
        return const Color(0xFFE3F2FD);
      default:
        return const Color(0xFFFFFDE7);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz belge yok',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir belge oluşturmak için "Yeni" butonuna tıklayın',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Yakında',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewDocumentDialog() {
    showNewDocumentDropdown(context, _addButtonKey);
  }

  /// Opens a document with instant navigation
  Future<void> _openDocument(String documentId) async {
    final loadUseCase = ref.read(loadDocumentUseCaseProvider);
    final result = await loadUseCase(documentId);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Belge açılamadı: ${failure.message}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      (document) {
        // PDF sayfaları için sadece state güncelle
        final pdfPages = document.pages
            .where((p) =>
                p.background.type == core.BackgroundType.pdf &&
                p.background.pdfFilePath != null &&
                p.background.pdfPageIndex != null)
            .toList();

        if (pdfPages.isNotEmpty) {
          final pdfFilePath = pdfPages.first.background.pdfFilePath!;
          ref.read(currentPdfFilePathProvider.notifier).state = pdfFilePath;
          ref.read(totalPdfPagesProvider.notifier).state = pdfPages.length;
          ref.read(visiblePdfPageProvider.notifier).state = 0;
          
          // PREFETCH YOK - Canvas açılınca kendi render edecek
        }

        // Editor'e HEMEN git
        if (mounted) {
          context.push('/editor/$documentId');
        }
      },
    );
  }

  void _toggleFavorite(String documentId) {
    ref.read(documentsControllerProvider.notifier).toggleFavorite(documentId);
  }

  void _showDocumentMenu(DocumentInfo document) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Yeniden Adlandır'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(document);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Taşı'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Taşıma özelliği yakında eklenecek'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                document.isFavorite ? Icons.star : Icons.star_outline,
              ),
              title: Text(
                document.isFavorite ? 'Favorilerden Kaldır' : 'Favorilere Ekle',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(document.id);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Çöpe Taşı', style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(context);
                ref.read(documentsControllerProvider.notifier).moveToTrash(document.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(DocumentInfo document) {
    final controller = TextEditingController(text: document.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Belge Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(documentsControllerProvider.notifier).renameDocument(
                      document.id,
                      newTitle,
                    );
              }
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
