/// StarNote Manage Folders Screen
///
/// Klasörleri yönet ekranı - drag-drop sıralama, renk değiştirme, silme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_color_picker.dart';
import 'package:example_app/features/documents/presentation/widgets/manage_folder_list_item.dart';

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
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        leading: AppIconButton(
          icon: Icons.arrow_back,
          variant: AppIconButtonVariant.ghost,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Klasörleri Yönet',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          if (_hasChanges)
            AppIconButton(
              icon: Icons.check,
              variant: AppIconButtonVariant.ghost,
              tooltip: 'Kaydet',
              onPressed: _saveOrder,
            ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (_orderedFolders.isEmpty) {
            _orderedFolders = _buildOrderedList(folders);
          }
          return _buildContent();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
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
      return const AppEmptyState(
        icon: Icons.folder_outlined,
        title: 'Henüz klasör yok',
        description:
            'Yeni bir klasör oluşturmak için aşağıdaki butona tıklayın',
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
    int rootOrder = 0;
    final subOrders = <String, int>{};

    for (final folder in _orderedFolders) {
      if (folder.parentId == null) {
        await controller.updateSortOrder(folder.id, rootOrder++);
      } else {
        final parentKey = folder.parentId!;
        subOrders[parentKey] = (subOrders[parentKey] ?? 0);
        await controller.updateSortOrder(folder.id, subOrders[parentKey]!);
        subOrders[parentKey] = subOrders[parentKey]! + 1;
      }
    }

    ref.invalidate(foldersProvider);
    setState(() => _hasChanges = false);
    if (mounted) AppToast.success(context, 'Sıralama kaydedildi');
  }

  Future<void> _showRenameDialog(Folder folder) async {
    final controller = TextEditingController(text: folder.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klasörü Yeniden Adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Klasör adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != folder.name) {
      await ref
          .read(foldersControllerProvider.notifier)
          .renameFolder(folder.id, result);
      ref.invalidate(foldersProvider);
      _orderedFolders = [];
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
      _orderedFolders = [];
    }
  }

  Future<void> _showCreateSubfolderDialog(Folder parent) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${parent.name} altına klasör ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Klasör adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(foldersControllerProvider.notifier)
          .createFolder(name: result, parentId: parent.id);
      ref.invalidate(foldersProvider);
      _orderedFolders = [];
    }
  }

  Future<void> _showDeleteConfirm(Folder folder) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Klasörü Sil',
      message:
          '"${folder.name}" klasörünü silmek istediğinize emin misiniz?\nİçindeki notlar çöp kutusuna taşınacak.',
      confirmLabel: 'Sil',
      isDestructive: true,
    );
    if (confirmed == true) {
      await ref
          .read(foldersControllerProvider.notifier)
          .deleteFolder(folder.id);
      ref.invalidate(foldersProvider);
      _orderedFolders = [];
      if (mounted) AppToast.success(context, 'Klasör silindi');
    }
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppButton(
          label: 'Yeni Klasör',
          leadingIcon: Icons.add,
          variant: AppButtonVariant.outline,
          onPressed: _showCreateFolderDialog,
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Klasör'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Klasör adı', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Oluştur')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref
          .read(foldersControllerProvider.notifier)
          .createFolder(name: result);
      ref.invalidate(foldersProvider);
      _orderedFolders = [];
    }
  }
}
