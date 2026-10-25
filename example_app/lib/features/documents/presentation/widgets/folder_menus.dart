import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/theme/index.dart';
import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/documents/presentation/widgets/folder_color_picker.dart';
import 'package:example_app/features/documents/presentation/widgets/menu_tile.dart';
import 'package:example_app/features/documents/presentation/widgets/move_to_folder_dialog.dart';

/// Shows context menu for a folder.
void showFolderMenu(
  BuildContext context,
  WidgetRef ref,
  Folder folder, {
  required VoidCallback? onDeleted,
}) {
  final surfaceColor = context.palette.surface;

  showModalBottomSheet(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          MenuTile(
            icon: Icons.edit_outlined,
            label: 'Yeniden Adlandır',
            onTap: () {
              Navigator.pop(ctx);
              _showRenameFolderDialog(context, ref, folder);
            },
          ),
          _softDivider(context),
          MenuTile(
            icon: Icons.color_lens_outlined,
            label: 'Renk Değiştir',
            onTap: () {
              Navigator.pop(ctx);
              _showColorPicker(context, ref, folder);
            },
          ),
          _softDivider(context),
          MenuTile(
            icon: Icons.drive_file_move_outlined,
            label: 'Taşı',
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
          _softDivider(context),
          _buildDeleteFolderTile(context, ref, folder, onDeleted),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
}

Future<void> _showColorPicker(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  final newColor = await showFolderColorPicker(
    context: context,
    currentColor: folder.colorValue,
  );
  if (newColor != null && context.mounted) {
    final success = await ref
        .read(foldersControllerProvider.notifier)
        .updateFolderColor(folder.id, newColor);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Klasör rengi değiştirildi' : 'Renk değiştirilemedi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

Widget _buildDeleteFolderTile(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
  VoidCallback? onDeleted,
) {
  final surfaceColor = context.palette.surface;
  final textPrimary = context.palette.textPrimary;

  return MenuTile(
    icon: Icons.delete_outline,
    label: 'Sil',
    isDestructive: true,
    onTap: () async {
      Navigator.pop(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: surfaceColor,
          title: Text('Klasörü Sil',
              style: AppTypography.titleLarge.copyWith(color: textPrimary)),
          content: Text(
            folder.documentCount > 0
                ? 'Bu klasörde ${folder.documentCount} belge var. '
                    'Klasörü silmek belgelerini de siler. '
                    'Devam etmek istiyor musunuz?'
                : 'Bu klasörü silmek istediğinize emin misiniz?',
            style: AppTypography.bodyMedium.copyWith(color: textPrimary),
          ),
          actions: [
            AppButton(
              label: 'İptal',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            AppButton(
              label: 'Sil',
              variant: AppButtonVariant.destructive,
              onPressed: () => Navigator.pop(ctx, true),
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
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Klasör silindi' : 'Klasör silinemedi'),
              behavior: SnackBarBehavior.floating,
            ),
          );
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
  final surfaceColor = context.palette.surface;
  final textPrimary = context.palette.textPrimary;
  final textSecondary = context.palette.textMuted;
  final outlineColor = context.palette.border;
  final accentColor = context.palette.accent;

  final controller = TextEditingController(text: folder.name);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: surfaceColor,
      title: Text('Klasörü Yeniden Adlandır',
          style: AppTypography.titleLarge.copyWith(color: textPrimary)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      content: SingleChildScrollView(
        child: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyMedium.copyWith(color: textPrimary),
          cursorColor: accentColor,
          decoration: InputDecoration(
            labelText: 'Klasör Adı',
            labelStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
            floatingLabelStyle:
                AppTypography.caption.copyWith(color: accentColor),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: outlineColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: outlineColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: accentColor, width: 2)),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'İptal',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.pop(ctx),
        ),
        AppButton(
          label: 'Kaydet',
          onPressed: () async {
            final newName = controller.text.trim();
            if (newName.isNotEmpty && newName != folder.name) {
              Navigator.pop(ctx);
              final folderController =
                  ref.read(foldersControllerProvider.notifier);
              final success =
                  await folderController.renameFolder(folder.id, newName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Klasör "$newName" olarak yeniden adlandırıldı'
                        : 'Klasör adı değiştirilemedi'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } else {
              Navigator.pop(ctx);
            }
          },
        ),
      ],
    ),
  );
}

/// Soft divider matching settings/sidebar pattern (0.5px, outlineVariant).
Widget _softDivider(BuildContext context) {
  return Divider(
    height: 0.5,
    thickness: 0.5,
    color: context.palette.border,
    indent: 56,
  );
}
