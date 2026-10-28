import 'package:example_app/features/documents/data/models/folder_model.dart';
import 'package:example_app/features/documents/domain/entities/folder.dart';

/// Pure folder-tree helpers used by [FolderRepositoryImpl].
abstract final class FolderTree {
  /// Returns all descendant folder IDs of [folderId] in [allFolders].
  static Set<String> descendantIds(
    String folderId,
    List<FolderModel> allFolders,
  ) {
    final descendants = <String>{};
    for (final child in allFolders.where((f) => f.parentId == folderId)) {
      descendants.add(child.id);
      descendants.addAll(descendantIds(child.id, allFolders));
    }
    return descendants;
  }

  /// Sorts [folders] in place by sortOrder first, then by name.
  static void sort(List<Folder> folders) {
    folders.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.name.compareTo(b.name);
    });
  }
}
