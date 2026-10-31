/// Bulk delete for the library selection mode (notebooks and folders).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/core/widgets/index.dart';
import 'package:example_app/features/documents/presentation/providers/bulk_result.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/l10n/l10n.dart';

/// Leaves selection mode and clears both selections.
void exitSelectionMode(WidgetRef ref) {
  ref.read(selectionModeProvider.notifier).state = false;
  ref.read(selectedDocumentsProvider.notifier).state = {};
  ref.read(selectedFoldersProvider.notifier).state = {};
}

/// Confirms, then deletes the selected notebooks and folders.
///
/// In the Trash section notebooks are removed permanently. Elsewhere
/// notebooks go to the trash and folders are deleted through
/// [FoldersController.deleteFolder] (their notes go to the trash). Items that
/// fail stay selected so a retry only repeats those.
Future<void> deleteSelection(
  BuildContext context,
  WidgetRef ref, {
  required Set<String> selectedDocs,
  required Set<String> selectedFolders,
  required bool isTrashSection,
}) async {
  final docCount = selectedDocs.length;
  // Trash lists no folders; ignore any stray ids there.
  final folderIds = isTrashSection ? <String>[] : selectedFolders.toList();
  if (docCount == 0 && folderIds.isEmpty) return;

  final l10n = context.l10n;
  final String title;
  final String message;
  if (isTrashSection) {
    title = l10n.libraryDeleteForeverTitle;
    message = l10n.libraryDeleteDocumentsForeverMessage(docCount);
  } else if (folderIds.isEmpty) {
    title = l10n.libraryDeleteDocumentsTitle;
    message = l10n.libraryTrashDocumentsMessage(docCount);
  } else if (docCount == 0) {
    title = l10n.libraryDeleteFolderTitle;
    message = l10n.libraryDeleteFoldersMessage(folderIds.length);
  } else {
    title = l10n.libraryDeleteDocumentsTitle;
    message = l10n.libraryDeleteSelectionMessage(folderIds.length, docCount);
  }

  final confirmed = await AppConfirmDialog.show(
    context: context,
    title: title,
    message: message,
    confirmLabel: l10n.commonDelete,
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) return;

  var docResult = const BulkResult();
  if (docCount > 0) {
    final controller = ref.read(documentsControllerProvider.notifier);
    final ids = selectedDocs.toList();
    docResult = isTrashSection
        ? await controller.permanentlyDeleteDocuments(ids)
        : await controller.moveDocumentsToTrash(ids);
  }
  final failedFolders = <String>[];
  for (final id in folderIds) {
    final ok =
        await ref.read(foldersControllerProvider.notifier).deleteFolder(id);
    if (!ok) failedFolders.add(id);
  }

  // The failure itself is shown by LibraryErrorListener.
  if (docResult.hasFailures || failedFolders.isNotEmpty) {
    ref.read(selectedDocumentsProvider.notifier).state =
        docResult.failed.toSet();
    ref.read(selectedFoldersProvider.notifier).state = failedFolders.toSet();
    return;
  }
  exitSelectionMode(ref);
  if (!context.mounted) return;
  final parts = <String>[
    if (docCount > 0)
      isTrashSection
          ? l10n.libraryDocumentsDeleted(docCount)
          : l10n.libraryDocumentsTrashed(docCount),
    if (folderIds.isNotEmpty) l10n.libraryFoldersDeleted(folderIds.length),
  ];
  AppToast.success(context, parts.join('. '));
}
