import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';

/// Actions behind the "move to folder" dialog.
///
/// Keeps business logic out of the dialog; failures are surfaced by the
/// controllers through `LibraryErrorListener`.
class MoveToFolderActions {
  MoveToFolderActions(this._ref);

  final Ref _ref;

  /// Folders a moved folder set may be dropped into: everything except the
  /// moved folders themselves and their descendants.
  static List<Folder> targetsFor(List<Folder> folders, List<String> movedIds) {
    if (movedIds.isEmpty) return folders;
    final blocked = <String>{...movedIds};
    var grew = true;
    while (grew) {
      grew = false;
      for (final f in folders) {
        if (f.parentId != null &&
            blocked.contains(f.parentId) &&
            blocked.add(f.id)) {
          grew = true;
        }
      }
    }
    return folders.where((f) => !blocked.contains(f.id)).toList();
  }

  /// Creates a folder named [name] (trimmed) and returns its id, or `null`
  /// when the name is blank or creation failed.
  Future<String?> createFolder({
    required String name,
    required int colorValue,
    String? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final id = await _ref.read(foldersControllerProvider.notifier).createFolder(
          name: trimmed,
          parentId: parentId,
          colorValue: colorValue,
        );
    if (id != null) _ref.invalidate(foldersProvider);
    return id;
  }

  /// Moves [documentIds] and [folderIds] into [targetFolderId] (`null` is the
  /// root). Returns `true` only if every move succeeded.
  Future<bool> move({
    required List<String> documentIds,
    required List<String> folderIds,
    required String? targetFolderId,
  }) async {
    if (documentIds.isNotEmpty) {
      final ok = await _ref
          .read(documentsControllerProvider.notifier)
          .moveDocumentsToFolder(documentIds, targetFolderId);
      if (!ok) return false;
    }
    final folders = _ref.read(foldersControllerProvider.notifier);
    for (final id in folderIds) {
      final ok =
          await folders.moveFolder(folderId: id, newParentId: targetFolderId);
      if (!ok) return false;
    }
    return true;
  }
}

final moveToFolderActionsProvider = Provider<MoveToFolderActions>(
  MoveToFolderActions.new,
);
