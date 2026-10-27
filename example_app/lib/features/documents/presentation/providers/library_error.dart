import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/domain/entities/library_rule.dart';
import 'package:example_app/features/documents/presentation/l10n/library_labels.dart';
import 'package:example_app/l10n/l10n.dart';

/// The library mutation that failed; selects the user-facing message.
enum LibraryAction {
  createDocument,
  importDocument,
  moveDocument,
  toggleFavorite,
  trashDocument,
  deleteDocument,
  renameDocument,
  restoreDocument,
  duplicateDocument,
  deleteDocumentForever,
  trashDocuments,
  deleteDocumentsForever,
  duplicateDocuments,
  moveDocuments,
  trashPage,
  deletePageForever,
  emptyTrash,
  createFolder,
  renameFolder,
  recolorFolder,
  saveFolderOrder,
  moveFolder,
  deleteFolder,
}

/// A failed library mutation (trash, rename, folder create, ...) waiting to
/// be shown to the user by `LibraryErrorListener`.
///
/// Not `const` and not value-equal on purpose: two identical failures in a
/// row are two events and must both notify listeners.
class LibraryError {
  LibraryError(this.failure, this.action);

  final Failure failure;
  final LibraryAction action;

  /// Text shown to the user: the localized rule for [LibraryRuleFailure]
  /// (written for users), the action-specific text for storage/unknown
  /// failures (their messages are English diagnostics, logged instead).
  String message(AppLocalizations l10n) {
    final f = failure;
    return f is LibraryRuleFailure
        ? f.rule.message(l10n)
        : action.failureMessage(l10n);
  }
}

/// Latest failed library mutation; `null` until the first failure.
final libraryErrorProvider = StateProvider<LibraryError?>((ref) => null);

/// Logs [failure] and publishes it for the library error snackbar.
void reportLibraryFailure(Ref ref, Failure failure, LibraryAction action) {
  logger.w('${action.name}: ${failure.message}');
  ref.read(libraryErrorProvider.notifier).state = LibraryError(failure, action);
}

/// [reportLibraryFailure] for an unexpected exception.
void reportLibraryError(Ref ref, Object error, LibraryAction action) {
  reportLibraryFailure(ref, UnknownFailure(error.toString()), action);
}
