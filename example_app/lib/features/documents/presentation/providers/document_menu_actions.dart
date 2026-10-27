import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/presentation/providers/documents_provider.dart';
import 'package:example_app/features/documents/presentation/providers/folders_provider.dart';
import 'package:example_app/features/premium/premium.dart';

/// Outcome of [DocumentMenuActions.duplicate].
class DuplicateOutcome {
  const DuplicateOutcome._({this.blockedBy, this.duplicated = false});

  /// The document limit was reached; nothing was duplicated.
  const DuplicateOutcome.blocked(FeatureAccess access)
      : this._(blockedBy: access);

  const DuplicateOutcome.done() : this._(duplicated: true);

  const DuplicateOutcome.failed() : this._();

  /// Set when the feature gate denied the duplicate.
  final FeatureAccess? blockedBy;

  /// True when the copy was created.
  final bool duplicated;
}

/// Outcome of [DocumentMenuActions.restorePage].
enum PageRestoreOutcome { restored, sourceMissing, failed }

/// Actions behind the library document / trash menus.
///
/// Keeps business logic out of the menu widgets; failures are surfaced by
/// the controller through `LibraryErrorListener`.
class DocumentMenuActions {
  DocumentMenuActions(this._ref);

  final Ref _ref;

  DocumentsController get _controller =>
      _ref.read(documentsControllerProvider.notifier);

  /// Renames [document]. A blank [title] is rejected without side effects.
  Future<bool> rename(DocumentInfo document, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return false;
    return _controller.renameDocument(document.id, trimmed);
  }

  /// Duplicates [document] unless the unified document limit is reached.
  Future<DuplicateOutcome> duplicate(
    DocumentInfo document, {
    required String Function(String title) copyTitle,
  }) async {
    final totalCount = await _ref.read(totalDocumentCountProvider.future);
    final access = _ref.read(featureAccessProvider(
      FeatureAccessParams(
        feature: GatedFeature.createDocument,
        currentUsage: totalCount,
      ),
    ));
    if (!access.isAllowed) return DuplicateOutcome.blocked(access);
    final ok = await _controller.duplicateDocument(
      document.id,
      copyTitle: copyTitle,
    );
    return ok ? const DuplicateOutcome.done() : const DuplicateOutcome.failed();
  }

  /// Refreshes the lists after a document was moved to another folder.
  void onMoved() {
    _ref.invalidate(foldersProvider);
    _ref.invalidate(documentsProvider);
  }

  Future<bool> toggleFavorite(DocumentInfo document) =>
      _controller.toggleFavorite(document.id);

  Future<bool> moveToTrash(DocumentInfo document) =>
      _controller.moveToTrash(document.id);

  Future<bool> restore(DocumentInfo document) =>
      _controller.restoreFromTrash(document.id);

  Future<bool> deleteForever(DocumentInfo document) =>
      _controller.permanentlyDeleteDocument(document.id);

  /// Restores a trashed page when its source document still exists.
  Future<PageRestoreOutcome> restorePage(TrashedPage page) async {
    final exists = await _controller.trashedPageDocumentExists(
      page.sourceDocumentId,
    );
    if (!exists) return PageRestoreOutcome.sourceMissing;
    final ok = await _controller.restorePageFromTrash(page.id);
    return ok ? PageRestoreOutcome.restored : PageRestoreOutcome.failed;
  }

  Future<void> deletePageForever(TrashedPage page) =>
      _controller.permanentlyDeletePage(page.id);
}

final documentMenuActionsProvider = Provider<DocumentMenuActions>(
  DocumentMenuActions.new,
);
