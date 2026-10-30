import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/core/core.dart' show CacheFailure;
import 'package:example_app/features/documents/domain/entities/document_info.dart';
import 'package:example_app/features/documents/domain/repositories/document_repository.dart';
import 'package:example_app/features/editor/presentation/providers/library_thumbnail_writer.dart';

class _MockDocumentRepository extends Mock implements DocumentRepository {}

/// #528: notebooks opened without a stored library preview get one.
void main() {
  late _MockDocumentRepository repo;
  late List<Page> renders;
  final png = Uint8List.fromList([1, 2, 3]);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repo = _MockDocumentRepository();
    renders = [];
    when(() => repo.saveThumbnail(any(), any()))
        .thenAnswer((_) async => const Right('thumb.png'));
  });

  void rowIs({String? thumbnailPath, bool hasCover = false}) {
    when(() => repo.getDocument('doc_a')).thenAnswer(
      (_) async => Right(
        DocumentInfo(
          id: 'doc_a',
          title: 'A',
          templateId: 'blank',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          thumbnailPath: thumbnailPath,
          hasCover: hasCover,
        ),
      ),
    );
  }

  LibraryThumbnailWriter writer({Duration idleDelay = Duration.zero}) =>
      LibraryThumbnailWriter(
        enabled: true,
        idleDelay: idleDelay,
        repository: () => repo,
        render: (page, width, height) async {
          renders.add(page);
          return png;
        },
      );

  DrawingDocument doc({bool coverFirst = false}) =>
      DrawingDocument.emptyMultiPage('A').copyWith(
        id: 'doc_a',
        pages: [
          if (coverFirst) Page.create(index: 0, isCover: true),
          Page.create(index: coverFirst ? 1 : 0),
        ],
      );

  test('a notebook without a stored preview gets exactly one write',
      () async {
    rowIs();
    final d = doc();
    final w = writer()..baseline(d);

    await w.ensureStored(d);
    await w.idle;

    expect(renders, [same(d.pages.first)]);
    verify(() => repo.saveThumbnail('doc_a', png)).called(1);
  });

  test('an edit saved while the row was read is not overwritten', () async {
    rowIs();
    final opened = doc();
    final w = writer()..baseline(opened);

    final check = w.ensureStored(opened);
    final edited = opened.copyWith(pages: [Page.create(index: 0)]);
    w.request(edited);
    await check;
    await w.idle;

    expect(renders, [same(edited.pages.first)]);
  });

  test('a notebook that already has a preview gets no write', () async {
    rowIs(thumbnailPath: 'images/thumb_doc_a.png');
    final d = doc();
    final w = writer()..baseline(d);

    await w.ensureStored(d);
    await w.idle;

    expect(renders, isEmpty);
    verifyNever(() => repo.saveThumbnail(any(), any()));
  });

  test('a notebook with a cover never requests a page preview', () async {
    rowIs(hasCover: true);
    final w = writer();

    final plain = doc();
    w.baseline(plain);
    await w.ensureStored(plain);

    final covered = doc(coverFirst: true);
    w.baseline(covered);
    await w.ensureStored(covered);
    await w.idle;

    expect(renders, isEmpty);
    verifyNever(() => repo.saveThumbnail(any(), any()));
    // A cover first page is decided without reading the row.
    verify(() => repo.getDocument('doc_a')).called(1);
  });

  test('waits for the idle delay instead of rendering during open', () async {
    rowIs();
    final d = doc();
    final w = writer(idleDelay: const Duration(hours: 1))..baseline(d);

    await w.ensureStored(d);
    await pumpEventQueue();
    expect(renders, isEmpty);

    await w.flush();
    expect(renders, hasLength(1));
  });

  test('a failed row read writes nothing and does not throw', () async {
    when(() => repo.getDocument('doc_a'))
        .thenAnswer((_) async => const Left(CacheFailure('gone')));
    final d = doc();
    final w = writer()..baseline(d);

    await w.ensureStored(d);
    await w.idle;

    expect(renders, isEmpty);
  });

  test('a disabled writer never reads the row', () async {
    final d = doc();
    final w = LibraryThumbnailWriter(
      enabled: false,
      repository: () => repo,
      render: (page, width, height) async => png,
    )..baseline(d);

    await w.ensureStored(d);

    verifyNever(() => repo.getDocument(any()));
  });
}
