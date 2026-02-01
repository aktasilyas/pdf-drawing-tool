import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/sort_option.dart';
import 'package:example_app/features/documents/domain/entities/view_mode.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';

class DocumentsHeader extends ConsumerStatefulWidget {
  final String title;
  final VoidCallback onNewPressed;
  final SortOption sortOption;
  final ValueChanged<SortOption> onSortChanged;
  final GlobalKey? newButtonKey;
  final List<String> allDocumentIds; // For "select all"
  final List<String> allFolderIds; // For "select all" folders
  final bool isTrashSection; // To determine delete behavior

  const DocumentsHeader({
    super.key,
    required this.title,
    required this.onNewPressed,
    required this.sortOption,
    required this.onSortChanged,
    this.newButtonKey,
    this.allDocumentIds = const [],
    this.allFolderIds = const [],
    this.isTrashSection = false,
  });

  @override
  ConsumerState<DocumentsHeader> createState() => _DocumentsHeaderState();
}

class _DocumentsHeaderState extends ConsumerState<DocumentsHeader> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final sortDirection = ref.watch(sortDirectionProvider);
    final viewMode = ref.watch(viewModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final selectedDocuments = ref.watch(selectedDocumentsProvider);
    
    // Update controller only if text differs (avoid cursor reset)
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 32,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24, // Settings butonu ile tam hizalı (16+8 IconButton padding)
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selection header or normal header
          if (isSelectionMode)
            _buildSelectionHeader(context, isMobile, selectedDocuments)
          else
            _buildNormalHeader(context, isMobile, sortDirection, viewMode),

          // Second row: Search bar (always visible)
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
            decoration: InputDecoration(
              hintText: 'Belgelerde ara...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // Normal header (existing layout)
  Widget _buildNormalHeader(BuildContext context, bool isMobile, SortDirection sortDirection, ViewMode viewMode) {
    return Row(
      children: [
        // Title - Stays on the left
        Text(
          widget.title,
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),

        const Spacer(),

        // Buttons container - aligned to the right with equal spacing
        if (!isMobile)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New button (hidden in trash)
              if (!widget.isTrashSection) ...[
                FilledButton(
                  key: widget.newButtonKey,
                  onPressed: widget.onNewPressed,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18),
                      SizedBox(width: 6),
                      Text('Yeni'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),

                const SizedBox(width: 4),
              ],

              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SortOption>(
                    value: widget.sortOption,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                    items: const [
                      DropdownMenuItem(
                        value: SortOption.date,
                        child: Text('Tarih'),
                      ),
                      DropdownMenuItem(
                        value: SortOption.name,
                        child: Text('İsim'),
                      ),
                      DropdownMenuItem(
                        value: SortOption.size,
                        child: Text('Boyut'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.onSortChanged(value);
                    },
                  ),
                ),
              ),

              const SizedBox(width: 4),

              // View mode toggle (Grid/List)
              IconButton(
                onPressed: () {
                  final newMode = viewMode == ViewMode.grid
                      ? ViewMode.list
                      : ViewMode.grid;
                  ref.read(viewModeProvider.notifier).set(newMode);
                },
                icon: Icon(
                  viewMode == ViewMode.grid
                      ? Icons.view_list
                      : Icons.grid_view,
                  size: 20,
                ),
                tooltip: viewMode == ViewMode.grid
                    ? 'Liste görünümü'
                    : 'Grid görünümü',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),

              const SizedBox(width: 4),

              // Sort direction toggle
              IconButton(
                onPressed: () {
                  final newDirection = sortDirection == SortDirection.descending
                      ? SortDirection.ascending
                      : SortDirection.descending;
                  ref.read(sortDirectionProvider.notifier).set(newDirection);
                },
                icon: Icon(
                  sortDirection == SortDirection.descending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 18,
                ),
                tooltip: sortDirection.getDescription(widget.sortOption),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),

              const SizedBox(width: 4),

              // Selection mode toggle - Last button, no trailing space
              IconButton(
                onPressed: () {
                  ref.read(selectionModeProvider.notifier).state = true;
                },
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Seçim modu',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          )
        else
          // Mobile buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // New button - Compact on mobile (hidden in trash)
              if (!widget.isTrashSection) ...[
                FilledButton(
                  key: widget.newButtonKey,
                  onPressed: widget.onNewPressed,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),

                const SizedBox(width: 8),
              ],

              // Sort dropdown - Icon button on mobile
              PopupMenuButton<SortOption>(
                initialValue: widget.sortOption,
                icon: const Icon(Icons.sort, size: 20),
                tooltip: 'Sıralama',
                onSelected: widget.onSortChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: SortOption.date,
                    child: Text('Tarih'),
                  ),
                  PopupMenuItem(
                    value: SortOption.name,
                    child: Text('İsim'),
                  ),
                  PopupMenuItem(
                    value: SortOption.size,
                    child: Text('Boyut'),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // Selection mode header (new)
  Widget _buildSelectionHeader(BuildContext context, bool isMobile, Set<String> selectedDocuments) {
    final selectedFolders = ref.watch(selectedFoldersProvider);
    final hasSelection = selectedDocuments.isNotEmpty || selectedFolders.isNotEmpty;
    
    return Row(
      children: [
        // Close selection mode button
        IconButton(
          onPressed: () {
            ref.read(selectionModeProvider.notifier).state = false;
            ref.read(selectedDocumentsProvider.notifier).state = {};
            ref.read(selectedFoldersProvider.notifier).state = {};
          },
          icon: const Icon(Icons.close),
          tooltip: 'Kapat',
        ),

        const SizedBox(width: 4),

        // "Select all" button
        TextButton.icon(
          onPressed: () {
            if (!mounted) return;
            
            final selectedFolders = ref.read(selectedFoldersProvider);
            final allIds = widget.allDocumentIds.toSet();
            final allFolderIds = widget.allFolderIds.toSet();
            
            // Check if all items are selected
            final allDocsSelected = allIds.isEmpty || selectedDocuments.length == allIds.length;
            final allFoldersSelected = allFolderIds.isEmpty || selectedFolders.length == allFolderIds.length;
            
            if (allDocsSelected && allFoldersSelected && (allIds.isNotEmpty || allFolderIds.isNotEmpty)) {
              // Deselect all
              if (mounted) {
                ref.read(selectedDocumentsProvider.notifier).state = {};
                ref.read(selectedFoldersProvider.notifier).state = {};
              }
            } else {
              // Select all
              if (mounted) {
                ref.read(selectedDocumentsProvider.notifier).state = allIds;
                ref.read(selectedFoldersProvider.notifier).state = allFolderIds;
              }
            }
          },
          icon: Icon(
            (widget.allDocumentIds.isNotEmpty || widget.allFolderIds.isNotEmpty) &&
                (widget.allDocumentIds.isEmpty || selectedDocuments.length == widget.allDocumentIds.length) &&
                (widget.allFolderIds.isEmpty || ref.watch(selectedFoldersProvider).length == widget.allFolderIds.length)
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            size: 20,
          ),
          label: const Text('Tümünü seç'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        // Action buttons (disabled when no selection)
        if (!isMobile) ...[
          const SizedBox(width: 4),

          // Duplicate button (hidden in trash)
          if (!widget.isTrashSection) ...[
            TextButton.icon(
              onPressed: hasSelection ? () async {
                // Show loading
                final controller = ref.read(documentsControllerProvider.notifier);
                try {
                  await controller.duplicateDocuments(selectedDocuments.toList());
                  
                  // Exit selection mode
                  ref.read(selectionModeProvider.notifier).state = false;
                  ref.read(selectedDocumentsProvider.notifier).state = {};
                  ref.read(selectedFoldersProvider.notifier).state = {};
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${selectedDocuments.length} belge kopyalandı'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } : null,
              icon: const Icon(Icons.content_copy, size: 18),
              label: const Text('Çoğalt'),
            ),

            const SizedBox(width: 4),

            // Move button (hidden in trash)
            TextButton.icon(
              onPressed: hasSelection ? () async {
                final selectedFolders = ref.read(selectedFoldersProvider);
                
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => MoveToFolderDialog(
                    documentIds: selectedDocuments.toList(),
                    folderIds: selectedFolders.toList(),  // ✅ Add folders
                  ),
                );
                
                // If move was successful, refresh providers and exit selection mode
                if (result == true) {
                  ref.invalidate(foldersProvider);
                  ref.invalidate(documentsProvider);
                  ref.read(selectionModeProvider.notifier).state = false;
                  ref.read(selectedDocumentsProvider.notifier).state = {};
                  ref.read(selectedFoldersProvider.notifier).state = {};  // ✅ Clear folders too
                }
              } : null,
              icon: const Icon(Icons.drive_file_move_outline, size: 18),
              label: const Text('Taşı'),
            ),

            const SizedBox(width: 4),
          ],

          // Delete button
          TextButton.icon(
            onPressed: hasSelection ? () async {
              // Different messages for trash vs normal sections
              final isTrash = widget.isTrashSection;
              final dialogTitle = isTrash ? 'Belgeleri Kalıcı Olarak Sil' : 'Belgeleri Sil';
              final dialogContent = isTrash
                  ? '${selectedDocuments.length} belge kalıcı olarak silinecek. Bu işlem geri alınamaz!'
                  : '${selectedDocuments.length} belge çöp kutusuna taşınacak.';
              final successMessage = isTrash
                  ? '${selectedDocuments.length} belge kalıcı olarak silindi'
                  : '${selectedDocuments.length} belge çöp kutusuna taşındı';

              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(dialogTitle),
                  content: Text(dialogContent),
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
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                final controller = ref.read(documentsControllerProvider.notifier);
                try {
                  // Use appropriate delete method based on section
                  if (isTrash) {
                    await controller.permanentlyDeleteDocuments(selectedDocuments.toList());
                  } else {
                    await controller.moveDocumentsToTrash(selectedDocuments.toList());
                  }
                  
                  // Exit selection mode
                  ref.read(selectionModeProvider.notifier).state = false;
                  ref.read(selectedDocumentsProvider.notifier).state = {};
                  ref.read(selectedFoldersProvider.notifier).state = {};
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(successMessage),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            } : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(widget.isTrashSection ? 'Kalıcı Sil' : 'Sil'),
            style: TextButton.styleFrom(
              foregroundColor: hasSelection ? Theme.of(context).colorScheme.error : null,
            ),
          ),
        ] else ...[
          const SizedBox(width: 4),
          
          // Mobile: Icon-only buttons (Duplicate and Move hidden in trash)
          if (!widget.isTrashSection) ...[
            IconButton(
              onPressed: hasSelection ? () async {
                final controller = ref.read(documentsControllerProvider.notifier);
                await controller.duplicateDocuments(selectedDocuments.toList());
                ref.read(selectionModeProvider.notifier).state = false;
                ref.read(selectedDocumentsProvider.notifier).state = {};
              } : null,
              icon: const Icon(Icons.content_copy, size: 20),
              tooltip: 'Çoğalt',
            ),
            IconButton(
              onPressed: hasSelection ? () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => MoveToFolderDialog(
                    documentIds: selectedDocuments.toList(),
                  ),
                );
                
                // If move was successful, exit selection mode
                if (result == true) {
                  ref.read(selectionModeProvider.notifier).state = false;
                  ref.read(selectedDocumentsProvider.notifier).state = {};
                }
              } : null,
              icon: const Icon(Icons.drive_file_move_outline, size: 20),
              tooltip: 'Taşı',
            ),
          ],
          
          // Delete button (always visible)
          IconButton(
            onPressed: hasSelection ? () async {
              final isTrash = widget.isTrashSection;
              final dialogTitle = isTrash ? 'Kalıcı Sil' : 'Sil';
              final dialogContent = isTrash
                  ? '${selectedDocuments.length} belge kalıcı olarak silinecek. Geri alınamaz!'
                  : '${selectedDocuments.length} belge çöp kutusuna taşınacak.';
              
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(dialogTitle),
                  content: Text(dialogContent),
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
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final controller = ref.read(documentsControllerProvider.notifier);
                if (isTrash) {
                  await controller.permanentlyDeleteDocuments(selectedDocuments.toList());
                } else {
                  await controller.moveDocumentsToTrash(selectedDocuments.toList());
                }
                ref.read(selectionModeProvider.notifier).state = false;
                ref.read(selectedDocumentsProvider.notifier).state = {};
              }
            } : null,
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: widget.isTrashSection ? 'Kalıcı Sil' : 'Sil',
            color: hasSelection ? Theme.of(context).colorScheme.error : null,
          ),
        ],
      ],
    );
  }
}
