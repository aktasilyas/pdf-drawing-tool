/// Library business rules a user can run into. Presentation maps each rule to
/// localized copy; the domain only carries the typed reason.
library;

import 'package:example_app/core/core.dart';

enum LibraryRule {
  /// Folders can only be one level deep (create).
  folderDepth('Folders can only be one level deep'),

  /// A folder can't be moved into its own subfolder.
  folderIntoOwnSubfolder("A folder can't be moved into its own subfolder"),

  /// A folder can't be moved into a subfolder.
  folderMoveDepth("A folder can't be moved into a subfolder"),

  /// A folder that has subfolders can't be moved into another folder.
  folderWithSubfoldersMove(
    "A folder with subfolders can't be moved into another folder",
  ),

  /// Free-tier notebook limit reached.
  documentLimit('Free document limit reached'),

  /// Free-tier folder limit reached.
  folderLimit('Free folder limit reached');

  const LibraryRule(this.diagnostic);

  /// English text for logs; never shown to the user.
  final String diagnostic;
}

/// A [ValidationFailure] caused by a [LibraryRule].
class LibraryRuleFailure extends ValidationFailure {
  // Not const: the diagnostic message is read from the enum value.
  LibraryRuleFailure(this.rule) : super('library rule: ${rule.diagnostic}');

  final LibraryRule rule;

  @override
  List<Object?> get props => [...super.props, rule];
}
