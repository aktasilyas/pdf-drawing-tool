import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/domain/entities/folder.dart';
import 'package:example_app/features/documents/domain/entities/folder_move_rules.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';

/// A folder offered by the move dialog; [depth] is 0 for top-level folders.
class MoveTarget {
  const MoveTarget(this.folder, this.depth);

  final Folder folder;
  final int depth;

  @override
  bool operator ==(Object other) =>
      other is MoveTarget && other.folder == folder && other.depth == depth;

  @override
  int get hashCode => Object.hash(folder, depth);
}

/// Actions behind the "move to folder" dialog.
///
/// Keeps business logic out of the dialog; failures are surfaced by the
/// controllers through `LibraryErrorListener`.
class MoveToFolderActions {
  MoveToFolderActions(this._ref);

  final Ref _ref;

  /// Folders the move dialog offers, each parent followed by its subfolders.
  ///
  /// With [movedIds] (folders being moved) only targets the repository will
  /// accept are kept ([FolderMoveRules]): never a moved folder or a subfolder,
  /// and nothing but the root when a moved folder has subfolders.
  static List<MoveTarget> targetsFor(
    List<Folder> folders,
    List<String> movedIds,
  ) {
    final nested = _nested(folders);
    if (movedIds.isEmpty) return nested;
    final moved = movedIds.toSet();
    final movedHasSubfolders = folders.any((f) => moved.contains(f.parentId));
    if (FolderMoveRules.checkMoved(hasSubfolders: movedHasSubfolders) != null) {
      return const [];
    }
    return nested
        .where((t) =>
            !moved.contains(t.folder.id) &&
            FolderMoveRules.checkTarget(
                  targetIsSubfolder: t.folder.isSubfolder,
                ) ==
                null)
        .toList();
  }

  /// [folders] in tree order (depth first, siblings keep their order).
  /// Folders whose parent is missing are listed at the top level.
  static List<MoveTarget> _nested(List<Folder> folders) {
    final ids = {for (final f in folders) f.id};
    final children = <String?, List<Folder>>{};
    for (final f in folders) {
      final parent = ids.contains(f.parentId) ? f.parentId : null;
      children.putIfAbsent(parent, () => []).add(f);
    }
    final result = <MoveTarget>[];
    final visited = <String>{};
    void visit(String? parentId, int depth) {
      for (final f in children[parentId] ?? const <Folder>[]) {
        if (!visited.add(f.id)) continue;
        result.add(MoveTarget(f, depth));
        visit(f.id, depth + 1);
      }
    }

    visit(null, 0);
    // A parent cycle never reaches the top level; keep those folders listed.
    for (final f in folders) {
      if (visited.add(f.id)) result.add(MoveTarget(f, 0));
    }
    return result;
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
