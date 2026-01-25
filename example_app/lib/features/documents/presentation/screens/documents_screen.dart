import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart'
    show DocumentsHeader, SortOption;
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
  SortOption _sortOption = SortOption.date;
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
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
            color: const Color(0xFFE0E0E0),
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
                        // TODO: Open settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ayarlar yakında eklenecek'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Header
                DocumentsHeader(
                  title: _getSectionTitle(),
                  newButtonKey: _addButtonKey,
                  onNewPressed: _showNewDocumentDialog,
                  sortOption: _sortOption,
                  onSortChanged: (option) {
                    setState(() => _sortOption = option);
                  },
                  isSelectionMode: _isSelectionMode,
                  onSelectionToggle: () {
                    setState(() => _isSelectionMode = !_isSelectionMode);
                  },
                ),

                // Content
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

  Widget _buildContent() {
    switch (_selectedSection) {
      case SidebarSection.documents:
        return _buildDocumentGrid(ref.watch(documentsProvider(null)));
      case SidebarSection.favorites:
        return _buildDocumentGrid(ref.watch(favoriteDocumentsProvider));
      case SidebarSection.trash:
        return _buildDocumentGrid(ref.watch(trashDocumentsProvider));
      case SidebarSection.shared:
      case SidebarSection.store:
        return _buildComingSoon();
    }
  }

  Widget _buildDocumentGrid(AsyncValue<List<DocumentInfo>> documentsAsync) {
    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
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
        final sorted = List<DocumentInfo>.from(documents);
        switch (_sortOption) {
          case SortOption.date:
            sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            break;
          case SortOption.name:
            sorted.sort((a, b) => a.title.compareTo(b.title));
            break;
          case SortOption.size:
            sorted.sort((a, b) => b.pageCount.compareTo(a.pageCount));
            break;
        }

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
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final doc = sorted[index];
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
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz belge yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir belge oluşturmak için "Yeni" butonuna tıklayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
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
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Yakında',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewDocumentDialog() {
    showNewDocumentDropdown(context, _addButtonKey);
  }

  /// Opens a document, prefetching PDF pages if necessary
  Future<void> _openDocument(String documentId) async {
    // Load document to check if it has PDF pages
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
      (document) async {
        // Check if document has PDF pages
        final hasPdfPages = document.pages.any((page) =>
            page.background.type == core.BackgroundType.pdf &&
            page.background.pdfFilePath != null &&
            page.background.pdfPageIndex != null);

        if (!hasPdfPages) {
          // No PDF pages, navigate immediately
          if (mounted) {
            context.push('/editor/$documentId');
          }
          return;
        }

        // Has PDF pages - prefetch first 3 pages before navigation
        if (mounted) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Sayfalar hazırlanıyor...'),
                ],
              ),
            ),
          );

          try {
            // Prefetch first 3 PDF pages (await)
            final pdfPages = document.pages
                .where((p) =>
                    p.background.type == core.BackgroundType.pdf &&
                    p.background.pdfFilePath != null &&
                    p.background.pdfPageIndex != null)
                .toList();

            final pagesToPrefetch = min<int>(3, pdfPages.length);
            for (int i = 0; i < pagesToPrefetch; i++) {
              final page = pdfPages[i];
              final cacheKey =
                  '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
              await ref.read(pdfPageRenderProvider(cacheKey).future);
            }

            // Background prefetch for pages 4-10 (fire and forget)
            if (pdfPages.length > 3) {
              final backgroundPrefetchCount = min<int>(10, pdfPages.length);
              for (int i = 3; i < backgroundPrefetchCount; i++) {
                final page = pdfPages[i];
                final cacheKey =
                    '${page.background.pdfFilePath}|${page.background.pdfPageIndex}';
                ref.read(pdfPageRenderProvider(cacheKey));
              }
            }
          } catch (e) {
            debugPrint('❌ Prefetch error: $e');
          } finally {
            // Close loading dialog
            if (mounted) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          }

          // Navigate to editor
          if (mounted) {
            context.push('/editor/$documentId');
          }
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
