import 'package:example_app/features/documents/domain/entities/library_rule.dart';

/// Where a folder may be moved. Folders are at most one level deep, so:
/// - only the root and top-level folders accept a moved folder;
/// - a folder that has subfolders can only live at the root.
///
/// Shared by the folder repository (which enforces the rules) and the move
/// dialog (which only offers targets the move can succeed into).
abstract final class FolderMoveRules {
  /// The rule refusing a move into a target folder, or `null` when the target
  /// accepts folders. [targetIsSubfolder] is true when the target itself has
  /// a parent.
  static LibraryRule? checkTarget({required bool targetIsSubfolder}) =>
      targetIsSubfolder ? LibraryRule.folderMoveDepth : null;

  /// The rule refusing to move a folder out of the root, or `null` when the
  /// moved folder may go into another folder.
  static LibraryRule? checkMoved({required bool hasSubfolders}) =>
      hasSubfolders ? LibraryRule.folderWithSubfoldersMove : null;
}
