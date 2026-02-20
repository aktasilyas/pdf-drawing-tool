import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';

/// Shows the appropriate document menu based on whether it's in trash.
void showDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document, {
  required bool isTrash,
}) {
  if (isTrash) {
    _showTrashDocumentMenu(context, ref, document);
  } else {
    _showNormalDocumentMenu(context, ref, document);
  }
}

void _showTrashDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
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
            leading: const Icon(Icons.restore_from_trash),
            title: const Text('Kurtar'),
            onTap: () async {
              Navigator.pop(ctx);
              final controller =
                  ref.read(documentsControllerProvider.notifier);
              final result =
                  await controller.restoreFromTrash(document.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result ? 'Belge geri yüklendi' : 'Belge geri yüklenemedi',
                    ),
                    backgroundColor: result ? null : Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const AppDivider(),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Kalıcı Sil',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Kalıcı Olarak Sil'),
                  content: const Text(
                    'Bu belge kalıcı olarak silinecek. Bu işlem geri alınamaz!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, false),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx2, true),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(ctx2).colorScheme.error,
                      ),
                      child: const Text('Kalıcı Sil'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                final controller =
                    ref.read(documentsControllerProvider.notifier);
                await controller.permanentlyDeleteDocument(document.id);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

void _showNormalDocumentMenu(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
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
              showRenameDocumentDialog(context, ref, document);
            },
          ),
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('Çoğalt'),
            onTap: () async {
              Navigator.pop(ctx);
              final controller =
                  ref.read(documentsControllerProvider.notifier);
              final result =
                  await controller.duplicateDocument(document.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result ? 'Belge çoğaltıldı' : 'Belge çoğaltılamadı',
                    ),
                    backgroundColor: result ? null : Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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
                  documentIds: [document.id],
                ),
              );
              if (result == true) {
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
              document.isFavorite
                  ? 'Favorilerden Kaldır'
                  : 'Favorilere Ekle',
            ),
            onTap: () {
              Navigator.pop(ctx);
              ref
                  .read(documentsControllerProvider.notifier)
                  .toggleFavorite(document.id);
            },
          ),
          const AppDivider(),
          ListTile(
            leading:
                Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Çöpe Taşı',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              Navigator.pop(ctx);
              ref
                  .read(documentsControllerProvider.notifier)
                  .moveToTrash(document.id);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

/// Shows context menu for a trashed page (Kurtar / Kalıcı Sil).
void showTrashedPageMenu(
  BuildContext context,
  WidgetRef ref,
  TrashedPage trashedPage,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              '${trashedPage.sourceDocumentTitle} — Sayfa ${trashedPage.originalPageIndex + 1}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const AppDivider(),
          ListTile(
            leading: const Icon(Icons.restore_from_trash),
            title: const Text('Kurtar'),
            onTap: () async {
              Navigator.pop(ctx);
              final controller =
                  ref.read(documentsControllerProvider.notifier);
              final docExists = await controller
                  .trashedPageDocumentExists(trashedPage.sourceDocumentId);
              if (!docExists) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kaynak belge bulunamadı'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              final result =
                  await controller.restorePageFromTrash(trashedPage.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result
                          ? 'Sayfa geri yüklendi'
                          : 'Sayfa geri yüklenemedi',
                    ),
                    backgroundColor:
                        result ? null : Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const AppDivider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Kalıcı Sil',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Kalıcı Olarak Sil'),
                  content: const Text(
                    'Bu sayfa kalıcı olarak silinecek. Bu işlem geri alınamaz!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2, false),
                      child: const Text('İptal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx2, true),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(ctx2).colorScheme.error,
                      ),
                      child: const Text('Kalıcı Sil'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref
                    .read(documentsControllerProvider.notifier)
                    .permanentlyDeletePage(trashedPage.id);
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

/// Shows rename dialog for a document.
void showRenameDocumentDialog(
  BuildContext context,
  WidgetRef ref,
  DocumentInfo document,
) {
  final controller = TextEditingController(text: document.title);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Yeniden Adlandır'),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Belge Adı',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            final newTitle = controller.text.trim();
            if (newTitle.isNotEmpty) {
              ref
                  .read(documentsControllerProvider.notifier)
                  .renameDocument(document.id, newTitle);
            }
            Navigator.pop(ctx);
          },
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
}
