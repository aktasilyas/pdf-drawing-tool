import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';

/// Shows context menu for a folder.
void showFolderMenu(
  BuildContext context,
  WidgetRef ref,
  Folder folder, {
  required VoidCallback? onDeleted,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Yeniden Adlandır'),
            onTap: () {
              Navigator.pop(ctx);
              _showRenameFolderDialog(context, ref, folder);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outlined),
            title: const Text('Taşı'),
            onTap: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final result = await showDialog<bool>(
                context: context,
                builder: (ctx2) => MoveToFolderDialog(
                  folderIds: [folder.id],
                ),
              );
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
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Renk değiştirme özelliği yakında eklenecek'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const AppDivider(),
          _buildDeleteFolderTile(context, ref, folder, onDeleted),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _buildDeleteFolderTile(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
  VoidCallback? onDeleted,
) {
  return ListTile(
    leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
    title: Text('Sil', style: TextStyle(color: Colors.red.shade400)),
    onTap: () async {
      Navigator.pop(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Klasörü Sil'),
          content: Text(
            folder.documentCount > 0
                ? 'Bu klasörde ${folder.documentCount} belge var. '
                    'Klasörü silmek belgelerini de siler. '
                    'Devam etmek istiyor musunuz?'
                : 'Bu klasörü silmek istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        final controller = ref.read(foldersControllerProvider.notifier);
        final success = await controller.deleteFolder(folder.id);
        if (context.mounted) {
          if (success) {
            onDeleted?.call();
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
  );
}

void _showRenameFolderDialog(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) {
  final controller = TextEditingController(text: folder.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Klasörü Yeniden Adlandır'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Klasör Adı'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            controller.dispose();
            Navigator.pop(ctx);
          },
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () async {
            final newName = controller.text.trim();
            controller.dispose();
            if (newName.isNotEmpty && newName != folder.name) {
              Navigator.pop(ctx);
              final folderController =
                  ref.read(foldersControllerProvider.notifier);
              final success =
                  await folderController.renameFolder(folder.id, newName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Klasör "$newName" olarak yeniden adlandırıldı'
                          : 'Klasör adı değiştirilemedi',
                    ),
                    backgroundColor: success ? null : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              Navigator.pop(ctx);
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}
