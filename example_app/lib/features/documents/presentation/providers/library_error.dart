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
  LibraryError(this.failure, this.action, {this.failedCount, this.totalCount})
      : assert((failedCount == null) == (totalCount == null));

  final Failure failure;
  final LibraryAction action;

  /// For a multi-selection action: how many of [totalCount] items failed.
  final int? failedCount;

  /// For a multi-selection action: how many items were tried.
  final int? totalCount;

  /// Text shown to the user: the localized rule for [LibraryRuleFailure]
  /// (written for users), the action-specific text for storage/unknown
  /// failures (their messages are English diagnostics, logged instead).
  /// Multi-selection actions append "N of M failed".
  String message(AppLocalizations l10n) {
    final f = failure;
    final text = f is LibraryRuleFailure
        ? f.rule.message(l10n)
        : action.failureMessage(l10n);
    final failed = failedCount;
    final total = totalCount;
    return failed == null || total == null
        ? text
        : l10n.libraryErrorBulkPartial(text, failed, total);
  }
}

/// Latest failed library mutation; `null` until the first failure.
final libraryErrorProvider = StateProvider<LibraryError?>((ref) => null);

/// Logs [failure] and publishes it for the library error snackbar.
///
/// Multi-selection actions pass [failedCount] and [totalCount] (both or
/// neither) so the message reports how many items failed.
void reportLibraryFailure(
  Ref ref,
  Failure failure,
  LibraryAction action, {
  int? failedCount,
  int? totalCount,
}) {
  final counts = totalCount == null ? '' : ' ($failedCount/$totalCount)';
  logger.w('${action.name}$counts: ${failure.message}');
  ref.read(libraryErrorProvider.notifier).state = LibraryError(
    failure,
    action,
    failedCount: failedCount,
    totalCount: totalCount,
  );
}

/// [reportLibraryFailure] for an unexpected exception.
void reportLibraryError(Ref ref, Object error, LibraryAction action) {
  reportLibraryFailure(ref, UnknownFailure(error.toString()), action);
}
