import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/responsive.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_sidebar.dart';
import 'package:example_app/features/documents/presentation/widgets/breadcrumb_navigation.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_card.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_header.dart';
import 'package:example_app/features/documents/presentation/widgets/new_document_dialog.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_empty_states.dart';
import 'package:example_app/features/documents/presentation/widgets/document_card_helpers.dart';
import 'package:example_app/features/documents/presentation/widgets/document_preview.dart';
import 'package:example_app/features/documents/presentation/widgets/document_thumbnail_painter.dart';
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
  String? _selectedFolderId; // For folder filtering
  bool _isSidebarCollapsed = false; // Tablet sidebar collapse state

  @override
  void dispose() {
    // Clean up selection state when screen is disposed
    ref.read(selectionModeProvider.notifier).state = false;
    ref.read(selectedDocumentsProvider.notifier).state = {};
    ref.read(selectedFoldersProvider.notifier).state = {};
    super.dispose();
  }

  /// Helper method to sort documents based on current sort options
  List<DocumentInfo> _sortDocuments(List<DocumentInfo> documents) {
    final sortOption = ref.watch(sortOptionProvider);
    final sortDirection = ref.watch(sortDirectionProvider);
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

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = Responsive.isPhone(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isPhone ? _buildSidebarDrawer() : null,
      body: SafeArea(
        child: isPhone ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  // Mobile layout - no persistent sidebar, use drawer
  Widget _buildMobileLayout() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mobile header with hamburger menu
          Builder(
            builder: (ctx) {
              final isDark = Theme.of(ctx).brightness == Brightness.dark;
              final textPrimary = isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: Icons.menu,
                      variant: AppIconButtonVariant.ghost,
                      tooltip: 'Menü',
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _getSectionTitle(),
                        style: AppTypography.headlineMedium.copyWith(
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Settings icon in mobile header
                    AppIconButton(
                      icon: Icons.settings_outlined,
                      variant: AppIconButtonVariant.ghost,
                      tooltip: 'Ayarlar',
                      onPressed: () => ctx.push('/settings'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Breadcrumb (only when inside a folder)
          if (_selectedSection == SidebarSection.folder &&
              _selectedFolderId != null)
            _buildBreadcrumb(),

          // Header
          DocumentsHeader(
            title: _getSectionTitle(),
            newButtonKey: _addButtonKey,
            onNewPressed: _showNewDocumentDialog,
            sortOption: ref.watch(sortOptionProvider),
            onSortChanged: (option) {
              ref.read(sortOptionProvider.notifier).set(option);
            },
            allDocumentIds: _getCurrentDocumentIds(),
            allFolderIds: _getCurrentFolderIds(),
            isTrashSection: _selectedSection == SidebarSection.trash,
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: AppDivider(),
          ),

          // Document grid
          Expanded(
            child: _buildDocumentGrid(),
          ),
        ],
      ),
    );
  }

  // Desktop/Tablet layout - persistent sidebar
  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Sidebar with collapse animation
        // OverflowBox keeps child at full width so content doesn't
        // squeeze during the width animation, preventing layout overflow.
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: _isSidebarCollapsed ? 0 : AppSpacing.sidebarWidth,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: OverflowBox(
            maxWidth: AppSpacing.sidebarWidth,
            minWidth: AppSpacing.sidebarWidth,
            alignment: Alignment.centerLeft,
            child: DocumentsSidebar(
              selectedSection: _selectedSection,
              selectedFolderId: _selectedFolderId,
              isDrawer: false,
              onCollapse: () => setState(() => _isSidebarCollapsed = true),
              onSectionChanged: (section) {
                setState(() {
                  _selectedSection = section;
                  _selectedFolderId = null;
                });
                ref.read(currentFolderIdProvider.notifier).state = null;
              },
              onFolderSelected: (folderId) {
                setState(() {
                  _selectedSection = SidebarSection.folder;
                  _selectedFolderId = folderId;
                });
                ref.read(currentFolderIdProvider.notifier).state = folderId;
              },
              onCreateFolder: _showCreateFolderDialog,
            ),
          ),
        ),

        // Vertical divider (hidden when collapsed)
        if (!_isSidebarCollapsed)
          Container(
            width: 1,
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),

        // Main content
        Expanded(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              color:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expand button + spacing when sidebar is collapsed
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.sm, top: AppSpacing.lg),
                    child: Row(
                      children: [
                        if (_isSidebarCollapsed)
                          AppIconButton(
                            icon: Icons.menu,
                            variant: AppIconButtonVariant.ghost,
                            tooltip: 'Kenar çubuğunu aç',
                            onPressed: () =>
                                setState(() => _isSidebarCollapsed = false),
                          ),
                      ],
                    ),
                  ),

                  // Breadcrumb (only when inside a folder)
                  if (_selectedSection == SidebarSection.folder &&
                      _selectedFolderId != null)
                    _buildBreadcrumb(),

                  // Header
                  DocumentsHeader(
                    title: _getSectionTitle(),
                    newButtonKey: _addButtonKey,
                    onNewPressed: _showNewDocumentDialog,
                    sortOption: ref.watch(sortOptionProvider),
                    onSortChanged: (option) {
                      ref.read(sortOptionProvider.notifier).set(option);
                    },
                    allDocumentIds: _getCurrentDocumentIds(),
                    allFolderIds: _getCurrentFolderIds(),
                    isTrashSection: _selectedSection == SidebarSection.trash,
                  ),

                  // Divider
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: AppDivider(),
                  ),

                  // Document grid
                  Expanded(
                    child: _buildDocumentGrid(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Sidebar drawer for mobile
  Widget _buildSidebarDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        child: DocumentsSidebar(
          selectedSection: _selectedSection,
          selectedFolderId: _selectedFolderId,
          isDrawer: true, // Phone drawer mode
          onCollapse: () => Navigator.pop(context), // Close drawer
          onSectionChanged: (section) {
            setState(() {
              _selectedSection = section;
              _selectedFolderId = null;
            });
            ref.read(currentFolderIdProvider.notifier).state = null;
            Navigator.pop(context);
          },
          onFolderSelected: (folderId) {
            setState(() {
              _selectedSection = SidebarSection.folder;
              _selectedFolderId = folderId;
            });
            ref.read(currentFolderIdProvider.notifier).state = folderId;
            Navigator.pop(context);
          },
          onCreateFolder: () {
            Navigator.pop(context);
            _showCreateFolderDialog();
          },
        ),
      ),
    );
  }

  // Breadcrumb navigation for folder path
  Widget _buildBreadcrumb() {
    if (_selectedFolderId == null) return const SizedBox.shrink();

    final folderPathAsync = ref.watch(folderPathProvider(_selectedFolderId!));

    return folderPathAsync.when(
      data: (folders) {
        if (folders.isEmpty) return const SizedBox.shrink();

        // Build breadcrumb items: Root + folder path
        final items = <BreadcrumbItem>[
          const BreadcrumbItem(folderId: null, label: 'Belgelerim'),
          ...folders.map(
            (f) => BreadcrumbItem(folderId: f.id, label: f.name),
          ),
        ];

        return BreadcrumbNavigation(
          items: items,
          onItemTap: (item) {
            if (item.folderId == null) {
              // Navigate to root (documents)
              setState(() {
                _selectedSection = SidebarSection.documents;
                _selectedFolderId = null;
              });
              ref.read(currentFolderIdProvider.notifier).state = null;
            } else {
              // Navigate to specific folder
              setState(() {
                _selectedSection = SidebarSection.folder;
                _selectedFolderId = item.folderId;
              });
              ref.read(currentFolderIdProvider.notifier).state = item.folderId;
            }
          },
          onBackPressed: () {
            // Go one level up
            if (folders.length > 1) {
              // Go to parent folder
              final parentFolder = folders[folders.length - 2];
              setState(() {
                _selectedFolderId = parentFolder.id;
              });
              ref.read(currentFolderIdProvider.notifier).state =
                  parentFolder.id;
            } else {
              // Go to root
              setState(() {
                _selectedSection = SidebarSection.documents;
                _selectedFolderId = null;
              });
              ref.read(currentFolderIdProvider.notifier).state = null;
            }
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // Document grid (shared by both layouts)
  Widget _buildDocumentGrid() {
    return _buildContent();
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case SidebarSection.documents:
        // Show folders + documents for root level
        return _buildDocumentsWithFolders();
      case SidebarSection.favorites:
        return _buildDocumentGridContent(ref.watch(favoriteDocumentsProvider));
      case SidebarSection.trash:
        return _buildDocumentGridContent(ref.watch(trashDocumentsProvider));
      case SidebarSection.folder:
        // Show subfolders + documents in the selected folder
        return _buildFolderContents(_selectedFolderId);
      case SidebarSection.shared:
      case SidebarSection.store:
        return const DocumentsComingSoon();
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
      case SidebarSection.folder:
        // Get folder name from provider
        if (_selectedFolderId != null) {
          final folderAsync = ref.watch(folderByIdProvider(_selectedFolderId!));
          return folderAsync.when(
            data: (folder) => folder?.name ?? 'Klasör',
            loading: () => 'Klasör',
            error: (_, __) => 'Klasör',
          );
        }
        return 'Klasör';
    }
  }

  List<String> _getCurrentDocumentIds() {
    final documentsAsync = switch (_selectedSection) {
      SidebarSection.documents => ref.watch(documentsProvider(null)),
      SidebarSection.favorites => ref.watch(favoriteDocumentsProvider),
      SidebarSection.trash => ref.watch(trashDocumentsProvider),
      SidebarSection.folder => ref.watch(documentsProvider(_selectedFolderId)),
      _ => const AsyncValue<List<DocumentInfo>>.data([]),
    };

    final searchQuery = ref.watch(searchQueryProvider);

    return documentsAsync.when(
      data: (docs) {
        // Apply search filter (same as displayed documents)
        var filteredDocs = docs;
        if (searchQuery.isNotEmpty) {
          filteredDocs = docs
              .where((doc) =>
                  doc.title.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
        }
        return filteredDocs.map((d) => d.id).toList();
      },
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );
  }

  List<String> _getCurrentFolderIds() {
    final foldersAsync = ref.watch(foldersProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return foldersAsync.when(
      data: (folders) {
        List<Folder> visibleFolders;

        if (_selectedSection == SidebarSection.documents) {
          // In documents section: show only root folders
          visibleFolders = folders.where((f) => f.parentId == null).toList();
        } else if (_selectedSection == SidebarSection.folder) {
          // In folder section: show subfolders of current folder
          visibleFolders =
              folders.where((f) => f.parentId == _selectedFolderId).toList();
        } else {
          // Other sections: no folders
          return <String>[];
        }

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          visibleFolders = visibleFolders
              .where((folder) =>
                  folder.name.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
        }

        return visibleFolders.map((f) => f.id).toList();
      },
      loading: () => <String>[],
      error: (e, s) => <String>[],
    );
  }

  Widget _buildDocumentsWithFolders() {
    final foldersAsync = ref.watch(foldersProvider);
    final documentsAsync = ref.watch(documentsProvider(null));

    return foldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Hata: $error'),
          ],
        ),
      ),
      data: (folders) {
        return documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Hata: $error'),
              ],
            ),
          ),
          data: (documents) {
            // Apply search filter
            final searchQuery = ref.watch(searchQueryProvider);
            final filteredDocs = searchQuery.isEmpty
                ? documents
                : documents
                    .where((doc) => doc.title
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();

            // Filter folders: only root level folders in documents section
            var filteredFolders =
                folders.where((f) => f.parentId == null).toList();
            if (searchQuery.isNotEmpty) {
              filteredFolders = filteredFolders
                  .where((folder) => folder.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();
            }

            // Show empty state if both are empty
            if (filteredFolders.isEmpty && filteredDocs.isEmpty) {
              if (searchQuery.isNotEmpty) {
                return DocumentsEmptySearchResult(query: searchQuery);
              }
              return const DocumentsEmptyState();
            }

            // Build combined grid/list with folders first
            return _buildCombinedView(filteredFolders, filteredDocs);
          },
        );
      },
    );
  }

  // Build folder contents (subfolders + documents)
  Widget _buildFolderContents(String? folderId) {
    final foldersAsync = ref.watch(foldersProvider);
    final documentsAsync = ref.watch(documentsProvider(folderId));

    return foldersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Hata: $error'),
          ],
        ),
      ),
      data: (allFolders) {
        return documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Hata: $error'),
              ],
            ),
          ),
          data: (documents) {
            // Apply search filter
            final searchQuery = ref.watch(searchQueryProvider);
            final filteredDocs = searchQuery.isEmpty
                ? documents
                : documents
                    .where((doc) => doc.title
                        .toLowerCase()
                        .contains(searchQuery.toLowerCase()))
                    .toList();

            // Filter folders: only subfolders of current folder
            var subfolders =
                allFolders.where((f) => f.parentId == folderId).toList();
            if (searchQuery.isNotEmpty) {
              subfolders = subfolders
                  .where((folder) => folder.name
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();
            }

            // Show empty state if both are empty
            if (subfolders.isEmpty && filteredDocs.isEmpty) {
              if (searchQuery.isNotEmpty) {
                return DocumentsEmptySearchResult(query: searchQuery);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bu klasör boş',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            // Build combined grid/list with subfolders first
            return _buildCombinedView(subfolders, filteredDocs);
          },
        );
      },
    );
  }

  Widget _buildCombinedView(
      List<Folder> folders, List<DocumentInfo> documents) {
    final viewMode = ref.watch(viewModeProvider);

    if (viewMode == ViewMode.grid) {
      return _buildCombinedGridView(folders, documents);
    } else {
      return _buildCombinedListView(folders, documents);
    }
  }

  Widget _buildCombinedGridView(
      List<Folder> folders, List<DocumentInfo> documents) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width < 600 ? 160.0 : 180.0;
        final spacing = width < 600 ? 16.0 : 24.0;
        final padding = width < 600 ? 16.0 : 32.0;

        // Selection state
        final isSelectionMode = ref.watch(selectionModeProvider);
        final selectedDocuments = ref.watch(selectedDocumentsProvider);
        final selectedFolders = ref.watch(selectedFoldersProvider);

        // Sort documents using helper method
        final sortedDocs = _sortDocuments(documents);

        // On phones, fix 2 columns to prevent tiny cells that overflow
        final isPhone = width < 600;
        final gridDelegate = isPhone
            ? SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 0.75,
              )
            : SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: cardWidth,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: 0.75,
              );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: GridView.builder(
            gridDelegate: gridDelegate,
            itemCount: folders.length + sortedDocs.length,
            itemBuilder: (context, index) {
              // Show folders first
              if (index < folders.length) {
                final folder = folders[index];
                final isSelected = selectedFolders.contains(folder.id);

                return FolderCard(
                  folder: folder,
                  isSelectionMode: isSelectionMode,
                  isSelected: isSelected,
                  onTap: () {
                    // Re-read current state to avoid closure issue
                    final currentSelection = ref.read(selectedFoldersProvider);
                    final isCurrentlySelected =
                        currentSelection.contains(folder.id);

                    if (isSelectionMode) {
                      // Toggle folder selection
                      final newSelection = Set<String>.from(currentSelection);

                      if (isCurrentlySelected) {
                        newSelection.remove(folder.id);
                      } else {
                        newSelection.add(folder.id);
                      }

                      ref.read(selectedFoldersProvider.notifier).state =
                          newSelection;
                    } else {
                      // Navigate into folder
                      setState(() {
                        _selectedSection = SidebarSection.folder;
                        _selectedFolderId = folder.id;
                      });
                      // Update current folder provider
                      ref.read(currentFolderIdProvider.notifier).state =
                          folder.id;
                    }
                  },
                  onMorePressed: () {
                    _showFolderMenu(folder);
                  },
                );
              }

              // Then show documents
              final docIndex = index - folders.length;
              final doc = sortedDocs[docIndex];
              final isSelected = selectedDocuments.contains(doc.id);

              return DocumentCard(
                document: doc,
                isSelectionMode: isSelectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (isSelectionMode) {
                    // Toggle selection
                    final newSelection = Set<String>.from(selectedDocuments);
                    if (isSelected) {
                      newSelection.remove(doc.id);
                    } else {
                      newSelection.add(doc.id);
                    }
                    ref.read(selectedDocumentsProvider.notifier).state =
                        newSelection;
                  } else {
                    _openDocument(doc.id);
                  }
                },
                onMorePressed: () => _showDocumentMenu(doc),
              );
            },
          ),
        );
      },
    );
  }

  /// Modern combined list view (Notion/Apple Notes tarzı)
  Widget _buildCombinedListView(
      List<Folder> folders, List<DocumentInfo> documents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = Responsive.isPhone(context);
    final padding = isPhone ? AppSpacing.md : AppSpacing.lg;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    // Sort documents using helper method
    final sortedDocs = _sortDocuments(documents);

    // Calculate total items including section headers
    final hasFolders = folders.isNotEmpty;
    final hasDocs = sortedDocs.isNotEmpty;
    int totalItems = folders.length + sortedDocs.length;
    if (hasFolders) totalItems++; // Folders header
    if (hasDocs) totalItems++; // Documents header

    return ListView.builder(
      padding:
          EdgeInsets.symmetric(horizontal: padding, vertical: AppSpacing.sm),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        int currentIndex = index;

        // Folders section header
        if (hasFolders && currentIndex == 0) {
          return Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              'Klasörler',
              style: AppTypography.caption.copyWith(
                color: textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        // Adjust index for folders header
        if (hasFolders) currentIndex--;

        // Folder items
        if (currentIndex < folders.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _buildFolderListTile(folders[currentIndex], isDark),
          );
        }
        currentIndex -= folders.length;

        // Documents section header
        if (hasDocs && currentIndex == 0) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.sm,
              top: hasFolders ? AppSpacing.lg : AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              'Belgeler',
              style: AppTypography.caption.copyWith(
                color: textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          );
        }

        // Adjust index for documents header
        if (hasDocs) currentIndex--;

        // Document items
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _buildListTile(sortedDocs[currentIndex]),
        );
      },
    );
  }

  /// Modern folder list tile (~56dp yükseklik)
  Widget _buildFolderListTile(Folder folder, bool isDark) {
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedFolders = ref.watch(selectedFoldersProvider);
    final isSelected = selectedFolders.contains(folder.id);

    // Theme-aware colors
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final hoverColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return Material(
      color: surfaceColor,
      child: InkWell(
        onTap: () {
          final currentSelection = ref.read(selectedFoldersProvider);
          final isCurrentlySelected = currentSelection.contains(folder.id);

          if (isSelectionMode) {
            final newSelection = Set<String>.from(currentSelection);
            if (isCurrentlySelected) {
              newSelection.remove(folder.id);
            } else {
              newSelection.add(folder.id);
            }
            ref.read(selectedFoldersProvider.notifier).state = newSelection;
          } else {
            setState(() {
              _selectedSection = SidebarSection.folder;
              _selectedFolderId = folder.id;
            });
            ref.read(currentFolderIdProvider.notifier).state = folder.id;
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            ref.read(selectionModeProvider.notifier).state = true;
            ref.read(selectedFoldersProvider.notifier).state = {folder.id};
          } else {
            _showFolderMenu(folder);
          }
        },
        hoverColor: hoverColor,
        splashColor: hoverColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              // Selection checkbox OR Folder icon with background
              if (isSelectionMode)
                _buildSelectionCheckbox(isSelected, isDark)
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(folder.colorValue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    size: 20,
                    color: Color(folder.colorValue),
                  ),
                ),

              const SizedBox(width: AppSpacing.md),

              // Folder name
              Expanded(
                child: Text(
                  folder.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Document count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${folder.documentCount}',
                  style: AppTypography.caption.copyWith(
                    color: textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Chevron (hidden in selection mode)
              if (!isSelectionMode) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentGridContent(
      AsyncValue<List<DocumentInfo>> documentsAsync) {
    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Hata: $error'),
          ],
        ),
      ),
      data: (documents) {
        if (documents.isEmpty) {
          return const DocumentsEmptyState();
        }

        // Sort documents using helper method
        final viewMode = ref.watch(viewModeProvider);
        final searchQuery = ref.watch(searchQueryProvider);
        final sorted = _sortDocuments(documents);

        // Filter by search query
        final filtered = searchQuery.isEmpty
            ? sorted
            : sorted
                .where((doc) =>
                    doc.title.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

        // Show empty search result if filtered is empty but search is active
        if (filtered.isEmpty && searchQuery.isNotEmpty) {
          return DocumentsEmptySearchResult(query: searchQuery);
        }

        // Render based on view mode
        return viewMode == ViewMode.grid
            ? _buildGridView(filtered)
            : _buildListView(filtered);
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
              return _buildListTile(doc);
            },
          ),
        );
      },
    );
  }

  /// Modern document list tile (Notion/Apple Notes tarzı)
  Widget _buildListTile(DocumentInfo doc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedDocuments = ref.watch(selectedDocumentsProvider);
    final isSelected = selectedDocuments.contains(doc.id);

    // Theme-aware colors
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final hoverColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return Material(
      color: surfaceColor,
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            final newSelection = Set<String>.from(selectedDocuments);
            if (isSelected) {
              newSelection.remove(doc.id);
            } else {
              newSelection.add(doc.id);
            }
            ref.read(selectedDocumentsProvider.notifier).state = newSelection;
          } else {
            _openDocument(doc.id);
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            ref.read(selectionModeProvider.notifier).state = true;
            ref.read(selectedDocumentsProvider.notifier).state = {doc.id};
          } else {
            _showDocumentMenu(doc);
          }
        },
        hoverColor: hoverColor,
        splashColor: hoverColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              // Selection checkbox OR Thumbnail
              if (isSelectionMode)
                _buildSelectionCheckbox(isSelected, isDark)
              else
                _buildCompactThumbnail(doc, isDark),

              const SizedBox(width: AppSpacing.md),

              // Document info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      doc.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date + page count
                    Text(
                      doc.pageCount > 1
                          ? '${DocumentDateFormatter.format(doc.updatedAt)} · ${doc.pageCount} sayfa'
                          : DocumentDateFormatter.format(doc.updatedAt),
                      style:
                          AppTypography.caption.copyWith(color: textTertiary),
                    ),
                  ],
                ),
              ),

              // Favorite star (hidden in selection mode)
              if (!isSelectionMode && doc.isFavorite)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(doc.id),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),

              // Chevron (hidden in selection mode)
              if (!isSelectionMode)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selection checkbox widget
  Widget _buildSelectionCheckbox(bool isSelected, bool isDark) {
    final outlineColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      width: 36,
      height: 44,
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : outlineColor,
            width: 1.5,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.onPrimary,
              )
            : null,
      ),
    );
  }

  /// Compact thumbnail for list view (40x48, rounded 6dp)
  ///
  /// Uses same thumbnail logic as DocumentCard: cover > PDF/image > template.
  Widget _buildCompactThumbnail(DocumentInfo doc, bool isDark) {
    final paperColor = DocumentPaperColors.fromName(doc.paperColor);
    final outlineColor =
        isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        color: paperColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outlineColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.5),
        child: _buildCompactThumbnailContent(doc),
      ),
    );
  }

  /// Builds actual content for compact thumbnail (same priority as DocumentCard)
  Widget _buildCompactThumbnailContent(DocumentInfo doc) {
    // 1. Cover
    if (doc.hasCover && doc.coverId != null) {
      final cover = core.CoverRegistry.byId(doc.coverId!);
      if (cover != null) {
        return CoverPreviewWidget(
          cover: cover,
          title: '',
          width: 40,
          height: 48,
        );
      }
    }
    // 2. PDF / Image preview
    if (doc.documentType == core.DocumentType.pdf ||
        doc.documentType == core.DocumentType.image) {
      return DocumentPreview(document: doc);
    }
    // 3. Template pattern + notebook binding
    return Stack(
      children: [
        CustomPaint(
          painter: DocumentThumbnailPainter(doc.templateId),
          size: const Size(40, 48),
        ),
        if (doc.documentType == core.DocumentType.notebook)
          _buildCompactSpiralBinding(),
      ],
    );
  }

  Widget _buildCompactSpiralBinding() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: 0,
      top: 4,
      bottom: 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          5,
          (i) => Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ),
      ),
    );
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

  void _showNewDocumentDialog() {
    showNewDocumentDropdown(context, _addButtonKey);
  }

  void _showCreateFolderDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => const MoveToFolderDialog(
        documentIds: [], // Empty list = folder management mode
      ),
    ).then((result) {
      // Refresh folders list when dialog closes
      if (result == true) {
        ref.invalidate(foldersProvider);
      }
    });
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
    // Different menu for trash section
    final isTrash = _selectedSection == SidebarSection.trash;

    if (isTrash) {
      _showTrashDocumentMenu(document);
    } else {
      _showNormalDocumentMenu(document);
    }
  }

  void _showTrashDocumentMenu(DocumentInfo document) {
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
              leading: const Icon(Icons.restore_from_trash),
              title: const Text('Kurtar'),
              onTap: () async {
                Navigator.pop(context);
                final controller =
                    ref.read(documentsControllerProvider.notifier);
                final result = await controller.restoreFromTrash(document.id);
                if (mounted) {
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belge geri yüklendi'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belge geri yüklenemedi'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
            const AppDivider(),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
              title: Text('Kalıcı Sil',
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(context);

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Kalıcı Olarak Sil'),
                    content: const Text(
                      'Bu belge kalıcı olarak silinecek. Bu işlem geri alınamaz!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: const Text('Kalıcı Sil'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  final controller =
                      ref.read(documentsControllerProvider.notifier);
                  await controller.permanentlyDeleteDocument(document.id);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNormalDocumentMenu(DocumentInfo document) {
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
              leading: const Icon(Icons.content_copy),
              title: const Text('Çoğalt'),
              onTap: () async {
                Navigator.pop(context);
                final controller =
                    ref.read(documentsControllerProvider.notifier);
                final result = await controller.duplicateDocument(document.id);
                if (mounted) {
                  if (result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belge çoğaltıldı'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Belge çoğaltılamadı'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Taşı'),
              onTap: () async {
                Navigator.pop(context);

                // Save scaffold messenger before async gap
                final messenger = ScaffoldMessenger.of(context);

                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => MoveToFolderDialog(
                    documentIds: [document.id],
                  ),
                );

                // Refresh providers and show success message if moved
                if (result == true) {
                  // Refresh providers to update folder counts and document lists
                  ref.invalidate(foldersProvider);
                  ref.invalidate(documentsProvider);

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Belge taşındı'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
            const AppDivider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Çöpe Taşı',
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(documentsControllerProvider.notifier)
                    .moveToTrash(document.id);
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

  void _showFolderMenu(Folder folder) {
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
                _showRenameFolderDialog(folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Taşı'),
              onTap: () async {
                Navigator.pop(context);

                // Save scaffold messenger before async gap
                final messenger = ScaffoldMessenger.of(context);

                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => MoveToFolderDialog(
                    folderIds: [folder.id],
                  ),
                );

                // Refresh providers if moved
                if (result == true) {
                  ref.invalidate(foldersProvider);
                  ref.invalidate(documentsProvider);

                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Klasör taşındı'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: const Text('Renk Değiştir'),
              onTap: () {
                Navigator.pop(context);
                _showFolderColorPicker(folder);
              },
            ),
            const AppDivider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Sil', style: TextStyle(color: Colors.red.shade400)),
              onTap: () async {
                Navigator.pop(context);

                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Klasörü Sil'),
                    content: Text(
                      folder.documentCount > 0
                          ? 'Bu klasörde ${folder.documentCount} belge var. Klasörü silmek belgelerini de siler. Devam etmek istiyor musunuz?'
                          : 'Bu klasörü silmek istediğinize emin misiniz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  final controller =
                      ref.read(foldersControllerProvider.notifier);
                  final success = await controller.deleteFolder(folder.id);

                  if (mounted) {
                    if (success) {
                      // If we're in the deleted folder, go back to documents
                      if (_selectedFolderId == folder.id) {
                        setState(() {
                          _selectedSection = SidebarSection.documents;
                          _selectedFolderId = null;
                        });
                        ref.read(currentFolderIdProvider.notifier).state = null;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Klasör silindi'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Klasör silinemedi'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(Folder folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Klasörü Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Klasör Adı',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              controller.dispose();

              if (newName.isNotEmpty && newName != folder.name) {
                Navigator.pop(context);
                final folderController =
                    ref.read(foldersControllerProvider.notifier);
                final success =
                    await folderController.renameFolder(folder.id, newName);

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Klasör "$newName" olarak yeniden adlandırıldı'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Klasör adı değiştirilemedi'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showFolderColorPicker(Folder folder) {
    // TODO: Implement color picker dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Renk değiştirme özelliği yakında eklenecek'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
