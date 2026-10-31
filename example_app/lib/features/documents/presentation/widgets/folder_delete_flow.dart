import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/l10n/l10n.dart';

/// Asks to delete [folder] and, when confirmed, deletes it with its
/// subfolders. Their notes move to Recently deleted, and the success toast
/// says how many. Shared by the library folder menu and Manage Folders so
/// both tell the same story. Returns true when the folder was deleted.
Future<bool> confirmAndDeleteFolder(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  final l10n = context.l10n;
  final confirmed = await AppConfirmDialog.show(
    context: context,
    title: l10n.libraryDeleteFolderTitle,
    // documentCount already includes notes in subfolders.
    message: l10n.libraryDeleteFolderConfirm(folder.name, folder.documentCount),
    confirmLabel: l10n.commonDelete,
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) return false;

  final trashed =
      await ref.read(foldersControllerProvider.notifier).deleteFolder(folder.id);
  // Failures are shown by LibraryErrorListener.
  if (trashed == null) return false;
  if (context.mounted) {
    AppToast.success(context, folderDeletedMessage(context.l10n, trashed));
  }
  return true;
}

/// Success text after deleting a folder that moved [trashed] notes.
String folderDeletedMessage(AppLocalizations l10n, int trashed) => trashed > 0
    ? l10n.libraryFolderDeletedNotesTrashed(trashed)
    : l10n.libraryFolderDeleted;
