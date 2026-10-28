/// ElyaNotes Manage Folders Screen
///
/// Folder management: drag-and-drop ordering, recolour, rename, delete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/utils/logger.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/documents_error_views.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_color_picker.dart';
import 'package:example_app/features/documents/presentation/widgets/manage_folder_list_item.dart';
import 'package:example_app/l10n/l10n.dart';

class ManageFoldersScreen extends ConsumerStatefulWidget {
  const ManageFoldersScreen({super.key});

  @override
  ConsumerState<ManageFoldersScreen> createState() =>
      _ManageFoldersScreenState();
}

class _ManageFoldersScreenState extends ConsumerState<ManageFoldersScreen> {
  List<Folder> _orderedFolders = [];
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.surface,
        leading: AppIconButton(
          icon: Icons.arrow_back,
          variant: AppIconButtonVariant.ghost,
          tooltip: l10n.commonBack,
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.libraryManageFolders,
          style: AppTypography.titleLarge.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        actions: [
          if (_hasChanges)
            AppIconButton(
              icon: Icons.check,
              variant: AppIconButtonVariant.ghost,
              tooltip: l10n.commonSave,
              onPressed: _saveOrder,
            ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (!_hasChanges) {
            _orderedFolders = _buildOrderedList(folders);
          }
          return _buildContent();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          logger.w('Folders failed to load', error: e, stackTrace: st);
          return DocumentsErrorView(
            error: e,
            message: l10n.libraryFoldersLoadFailed,
            onRetry: () => ref.invalidate(foldersProvider),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  List<Folder> _buildOrderedList(List<Folder> folders) {
    final result = <Folder>[];
    final roots = folders.where((f) => f.parentId == null).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final root in roots) {
      result.add(root);
      final subs = folders.where((f) => f.parentId == root.id).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      result.addAll(subs);
    }
    return result;
  }

  Widget _buildContent() {
    if (_orderedFolders.isEmpty) {
      final l10n = context.l10n;
      return AppEmptyState(
        icon: Icons.folder_outlined,
        title: l10n.libraryNoFoldersYet,
        description: l10n.libraryNoFoldersHint,
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      itemCount: _orderedFolders.length,
      onReorder: _onReorder,
      proxyDecorator: _proxyDecorator,
      itemBuilder: (context, index) {
        final folder = _orderedFolders[index];
        return ManageFolderListItem(
          key: ValueKey(folder.id),
          folder: folder,
          index: index,
          onRename: () => _showRenameDialog(folder),
          onChangeColor: () => _showColorPicker(folder),
          onAddSubfolder: folder.canHaveSubfolders
              ? () => _showCreateSubfolderDialog(folder)
              : null,
          onDelete: () => _showDeleteConfirm(folder),
        );
      },
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: child,
      ),
      child: child,
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _orderedFolders.removeAt(oldIndex);
      _orderedFolders.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _saveOrder() async {
    final controller = ref.read(foldersControllerProvider.notifier);
    final nextOrder = <String, int>{}; // per parent id; '' is the root
    var saved = true;
    for (final folder in _orderedFolders) {
      final key = folder.parentId ?? '';
      final order = nextOrder[key] ?? 0;
      nextOrder[key] = order + 1;
      // Stop at the first failure; LibraryErrorListener shows it once.
      saved = await controller.updateSortOrder(folder.id, order);
      if (!saved) break;
    }
    ref.invalidate(foldersProvider);
    // On failure keep _hasChanges so the user can retry.
    if (!saved || !mounted) return;
    setState(() => _hasChanges = false);
    AppToast.success(context, context.l10n.libraryFolderOrderSaved);
  }

  /// Folder-name dialog shared by rename, subfolder and new-folder flows.
  /// Returns the trimmed name, or null when cancelled.
  Future<String?> _promptFolderName({
    required String title,
    required String confirmLabel,
    String initial = '',
  }) {
    final l10n = context.l10n;
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.libraryFolderNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(Folder folder) async {
    final l10n = context.l10n;
    final result = await _promptFolderName(
      title: l10n.libraryRenameFolderTitle,
      confirmLabel: l10n.commonSave,
      initial: folder.name,
    );
    if (result != null && result.isNotEmpty && result != folder.name) {
      await ref
          .read(foldersControllerProvider.notifier)
          .renameFolder(folder.id, result);
      ref.invalidate(foldersProvider);
    }
  }

  Future<void> _showColorPicker(Folder folder) async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => FolderColorPicker(currentColor: folder.colorValue),
    );
    if (result != null && result != folder.colorValue) {
      await ref
          .read(foldersControllerProvider.notifier)
          .updateFolderColor(folder.id, result);
      ref.invalidate(foldersProvider);
    }
  }

  Future<void> _showCreateSubfolderDialog(Folder parent) async {
    final l10n = context.l10n;
    final result = await _promptFolderName(
      title: l10n.libraryAddSubfolderTitle(parent.name),
      confirmLabel: l10n.commonCreate,
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(foldersControllerProvider.notifier)
          .createFolder(name: result, parentId: parent.id);
      ref.invalidate(foldersProvider);
    }
  }

  Future<void> _showDeleteConfirm(Folder folder) async {
    final l10n = context.l10n;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: l10n.libraryDeleteFolderTitle,
      message: l10n.libraryDeleteFolderConfirm(folder.name),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed == true) {
      final deleted = await ref
          .read(foldersControllerProvider.notifier)
          .deleteFolder(folder.id);
      ref.invalidate(foldersProvider);
      // Failures are shown by LibraryErrorListener.
      if (deleted && mounted) {
        AppToast.success(context, context.l10n.libraryFolderDeleted);
      }
    }
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppButton(
          label: context.l10n.libraryNewFolder,
          leadingIcon: Icons.add,
          variant: AppButtonVariant.outline,
          onPressed: _showCreateFolderDialog,
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final l10n = context.l10n;
    final result = await _promptFolderName(
      title: l10n.libraryNewFolder,
      confirmLabel: l10n.commonCreate,
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(foldersControllerProvider.notifier)
          .createFolder(name: result);
      ref.invalidate(foldersProvider);
    }
  }
}
