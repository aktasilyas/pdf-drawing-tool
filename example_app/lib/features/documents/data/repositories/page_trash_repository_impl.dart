import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:example_app/core/core.dart'
    show CacheException, CacheFailure, Failure, LocalTransactionRunner;
import 'package:example_app/features/documents/data/datasources/document_local_datasource.dart';
import 'package:example_app/features/documents/data/datasources/managed_file_paths.dart';
import 'package:example_app/features/documents/data/datasources/trashed_page_local_datasource.dart';
import 'package:example_app/features/documents/data/models/trashed_page_model.dart';
import 'package:example_app/features/documents/domain/entities/trashed_page.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart'
    show trashRetention;
import 'package:example_app/features/documents/domain/repositories/page_trash_repository.dart';

class PageTrashRepositoryImpl implements PageTrashRepository {
  final TrashedPageLocalDatasource _trashDatasource;
  final DocumentLocalDatasource _documentDatasource;
  final LocalTransactionRunner _runner;
  final Uuid _uuid;

  PageTrashRepositoryImpl(
    this._trashDatasource,
    this._documentDatasource,
    this._runner, [
    Uuid? uuid,
  ]) : _uuid = uuid ?? const Uuid();

  /// Runs [action] and maps errors to a [Failure].
  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to $what: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TrashedPage>>> getTrashedPages() {
    return _guard('get trashed pages', () async {
      final models = await _trashDatasource.getTrashedPages();
      final entities = models.map((m) => m.toEntity()).toList();
      entities.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
      return entities;
    });
  }

  @override
  Future<Either<Failure, String>> movePageToTrash({
    required String documentId,
    required String documentTitle,
    required int pageIndex,
    required Map<String, dynamic> pageData,
  }) {
    return _guard('move page to trash', () async {
      final model = TrashedPageModel(
        id: 'trashed_page_${_uuid.v4()}',
        pageId: pageData['id'] as String? ?? 'unknown',
        sourceDocumentId: documentId,
        sourceDocumentTitle: documentTitle,
        originalPageIndex: pageIndex,
        deletedAt: DateTime.now(),
        pageData: pageData,
      );
      await _trashDatasource.addTrashedPage(model);
      return model.id;
    });
  }

  @override
  Future<Either<Failure, bool>> restorePageFromTrash(String trashedPageId) {
    // Content, page count and trash row change together or not at all.
    return _guard(
      'restore page',
      () => _runner.run(() => _restore(trashedPageId)),
    );
  }

  Future<bool> _restore(String trashedPageId) async {
    final model = await _trashDatasource.getTrashedPage(trashedPageId);
    if (model == null) return false;
    // Never restore into a notebook that is in the trash (or gone).
    if (!await _documentDatasource.isLiveDocument(model.sourceDocumentId)) {
      return false;
    }

    final content =
        await _documentDatasource.getDocumentContent(model.sourceDocumentId);
    if (content == null) return false;

    final pages = (content['pages'] as List).cast<Map<String, dynamic>>();

    // The page is already back (e.g. an editor undo re-inserted it while the
    // trash row stayed): drop the row instead of duplicating the page id.
    final pageId = model.pageData['id'];
    if (pageId != null && pages.any((p) => p['id'] == pageId)) {
      await _trashDatasource.removeTrashedPage(trashedPageId);
      return true;
    }

    // Insert page at clamped original position, then re-index.
    final insertIndex = min(model.originalPageIndex, pages.length);
    pages.insert(insertIndex, model.pageData);
    for (int i = 0; i < pages.length; i++) {
      pages[i]['index'] = i;
    }
    content['pages'] = pages;
    // Keep the page the user was on current when the restored page lands
    // before (or at) it.
    final current = content['currentPageIndex'];
    if (current is int && insertIndex <= current) {
      content['currentPageIndex'] = current + 1;
    }

    await _documentDatasource.saveDocumentContent(
      model.sourceDocumentId,
      content,
    );
    await _updatePageCount(model.sourceDocumentId, pages.length);
    await _trashDatasource.removeTrashedPage(trashedPageId);
    return true;
  }

  @override
  Future<Either<Failure, void>> permanentlyDeletePage(String trashedPageId) {
    return _guard('delete page', () async {
      final page = await _trashDatasource.getTrashedPage(trashedPageId);
      // An unreadable row reads as null; deleting by id removes it anyway.
      await _remove(page == null ? [] : [page], [trashedPageId]);
    });
  }

  @override
  Future<Either<Failure, int>> emptyTrash() {
    return _guard('empty page trash', () async {
      final pages = await _trashDatasource.getTrashedPages();
      final unreadable = await _trashDatasource.getUnreadableTrashedPages();
      await _remove(pages, [for (final u in unreadable) u.id]);
      return pages.length + unreadable.length;
    });
  }

  @override
  Future<Either<Failure, int>> purgeExpired({
    required DateTime now,
    Duration retention = trashRetention,
  }) {
    return _guard('purge trashed pages', () async {
      final cutoff = now.subtract(retention);
      final expired = (await _trashDatasource.getTrashedPages())
          .where((p) => p.deletedAt.isBefore(cutoff))
          .toList();
      final expiredUnreadable = [
        for (final u in await _trashDatasource.getUnreadableTrashedPages())
          if (u.deletedAt.isBefore(cutoff)) u.id,
      ];
      await _remove(expired, expiredUnreadable);
      return expired.length + expiredUnreadable.length;
    });
  }

  @override
  Future<Either<Failure, bool>> documentExists(String documentId) {
    return _guard(
      'check document',
      () => _documentDatasource.isLiveDocument(documentId),
    );
  }

  /// Deletes the trash rows of [pages] in one transaction, then the copied
  /// files (PDFs, images) nothing references any more. [unreadableIds] are
  /// rows that could not be decoded: only the row goes, their files are left
  /// to the orphan sweep.
  Future<void> _remove(
    List<TrashedPageModel> pages, [
    List<String> unreadableIds = const [],
  ]) async {
    if (pages.isEmpty && unreadableIds.isEmpty) return;
    await _runner.run(() async {
      for (final id in [for (final p in pages) p.id, ...unreadableIds]) {
        await _trashDatasource.removeTrashedPage(id);
      }
    });
    await _documentDatasource.deleteUnreferencedFiles({
      for (final page in pages) ...managedFilePathsOfPage(page.pageData),
    });
  }

  Future<void> _updatePageCount(String documentId, int newCount) async {
    final document = await _documentDatasource.getDocument(documentId);
    await _documentDatasource.updateDocument(
      document.copyWith(pageCount: newCount, updatedAt: DateTime.now()),
    );
  }
}
