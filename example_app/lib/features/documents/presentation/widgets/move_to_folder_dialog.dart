import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';

/// Dialog for moving documents and folders
class MoveToFolderDialog extends ConsumerStatefulWidget {
  final List<String> documentIds;
  final List<String> folderIds;

  const MoveToFolderDialog({
    super.key,
    this.documentIds = const [],
    this.folderIds = const [],
  });

  @override
  ConsumerState<MoveToFolderDialog> createState() => _MoveToFolderDialogState();
}

class _MoveToFolderDialogState extends ConsumerState<MoveToFolderDialog> {
  String? _selectedFolderId;
  bool _isCreatingFolder = false;
  final _newFolderController = TextEditingController();

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersProvider);
    final theme = Theme.of(context);
    final isFolderManagementMode = widget.documentIds.isEmpty && widget.folderIds.isEmpty;
    final isMovingFolder = widget.folderIds.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Dialog(
          child: GestureDetector(
            onTap: () {}, // Prevent dialog from closing when tapped
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          isFolderManagementMode 
                              ? 'Klasör Yönetimi' 
                              : isMovingFolder
                                  ? 'Klasörü Taşı'
                                  : 'Klasöre Taşı',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Kapat',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // New folder section (moved to top)
                  if (_isCreatingFolder) ...[
                    const Divider(height: 1),
                    _buildNewFolderSection(),
                  ],
                  
                  const Divider(height: 1),

                  // Folder list or loading/error - flexible
                  Flexible(
                    child: foldersAsync.when(
                      data: (folders) => _buildFolderList(folders),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text('Klasörler yüklenemedi: $error'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Bottom actions (always visible)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // New Folder button
                        if (!_isCreatingFolder)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _isCreatingFolder = true);
                            },
                            icon: const Icon(Icons.create_new_folder, size: 18),
                            label: const Text('Yeni Klasör'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        const Spacer(),

                        // Cancel/Done button
                        if (isFolderManagementMode)
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Bitti'),
                          )
                        else ...[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Move button
                          FilledButton(
                            onPressed: _selectedFolderId != null ? _handleMove : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Taşı'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderList(List<Folder> folders) {
    final isFolderManagementMode = widget.documentIds.isEmpty && widget.folderIds.isEmpty;
    final isMovingFolder = widget.folderIds.isNotEmpty;
    
    // Filter out folders that can't be selected when moving a folder
    List<Folder> availableFolders = folders;
    if (isMovingFolder && widget.folderIds.isNotEmpty) {
      final movingFolderId = widget.folderIds.first;
      // Exclude the folder being moved and its descendants
      availableFolders = folders.where((folder) {
        // Can't move into itself
        if (folder.id == movingFolderId) return false;
        // Can't move into its own descendants (check parentId chain)
        // For now, simple check: exclude if parentId is the moving folder
        if (folder.parentId == movingFolderId) return false;
        return true;
      }).toList();
    }
    
    if (availableFolders.isEmpty && !isMovingFolder) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz klasör yok',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isFolderManagementMode
                  ? '"Yeni Klasör" butonuna tıklayarak\nklasör oluşturabilirsiniz'
                  : 'Yeni klasör oluşturarak başlayın',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: availableFolders.length + 1, // +1 for "Root" option
      itemBuilder: (context, index) {
        // First item: "Belgeler" (Root - no folder)
        if (index == 0) {
          final isSelected = _selectedFolderId == null;
          return ListTile(
            leading: Icon(
              Icons.home_outlined,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              isMovingFolder ? 'Ana Klasörler' : 'Belgeler (Klasörsüz)',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            selected: isSelected,
            onTap: () {
              setState(() => _selectedFolderId = null);
            },
          );
        }

        // Folder items
        final folder = availableFolders[index - 1];
        final isSelected = _selectedFolderId == folder.id;
        
        return ListTile(
          leading: Icon(
            Icons.folder,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Color(folder.colorValue),
          ),
          title: Text(folder.name),
          subtitle: Text('${folder.documentCount} belge'),
          trailing: isSelected
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
          selected: isSelected,
          onTap: () {
            setState(() => _selectedFolderId = folder.id);
          },
        );
      },
    );
  }

  Widget _buildNewFolderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.create_new_folder, size: 16),
              const SizedBox(width: 6),
              Text(
                'Yeni Klasör',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _newFolderController,
                  decoration: const InputDecoration(
                    labelText: 'Klasör Adı',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 14),
                  autofocus: true,
                  onSubmitted: (_) => _handleCreateFolder(),
                ),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _handleCreateFolder,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Oluştur', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isCreatingFolder = false;
                    _newFolderController.clear();
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('İptal', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateFolder() async {
    final name = _newFolderController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klasör adı boş olamaz'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = ref.read(foldersControllerProvider.notifier);
    final folderId = await controller.createFolder(name: name);

    if (folderId != null && mounted) {
      // Refresh folders provider to show the new folder
      ref.invalidate(foldersProvider);
      
      setState(() {
        _selectedFolderId = folderId;
        _isCreatingFolder = false;
        _newFolderController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Klasör "$name" oluşturuldu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klasör oluşturulamadı'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleMove() async {
    bool documentsSuccess = true;
    bool foldersSuccess = true;
    
    // Move documents if any
    if (widget.documentIds.isNotEmpty) {
      final docController = ref.read(documentsControllerProvider.notifier);
      documentsSuccess = await docController.moveDocumentsToFolder(
        widget.documentIds,
        _selectedFolderId,
      );
    }
    
    // Move folders if any
    if (widget.folderIds.isNotEmpty) {
      final folderController = ref.read(foldersControllerProvider.notifier);
      for (final folderId in widget.folderIds) {
        final folderSuccess = await folderController.moveFolder(
          folderId: folderId,
          newParentId: _selectedFolderId,
        );
        if (!folderSuccess) {
          foldersSuccess = false;
          break;
        }
      }
    }

    final success = documentsSuccess && foldersSuccess;

    if (mounted) {
      if (success) {
        // Just close the dialog with success result
        // Parent will handle refresh and snackbar
        Navigator.pop(context, true);
      } else {
        String errorMessage = 'Taşıma başarısız';
        if (!documentsSuccess && !foldersSuccess) {
          errorMessage = 'Belgeler ve klasörler taşınamadı';
        } else if (!documentsSuccess) {
          errorMessage = 'Belgeler taşınamadı';
        } else if (!foldersSuccess) {
          errorMessage = 'Klasörler taşınamadı';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
