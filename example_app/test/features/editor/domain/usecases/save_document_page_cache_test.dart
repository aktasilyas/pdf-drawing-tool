import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';

import '../../../../helpers/large_document.dart';

class MockDocumentRepository extends Mock implements DocumentRepository {}

void main() {
  late MockDocumentRepository repository;
  late SaveDocumentUseCase useCase;
  var encodes = 0;
  final contents = <Map<String, dynamic>>[];

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    encodes = 0;
    contents.clear();
    repository = MockDocumentRepository();
    when(() => repository.saveDocumentContent(
          id: any(named: 'id'),
          content: any(named: 'content'),
          pageCount: any(named: 'pageCount'),
          updatedAt: any(named: 'updatedAt'),
          coverId: any(named: 'coverId'),
          updateCover: any(named: 'updateCover'),
          title: any(named: 'title'),
        )).thenAnswer((inv) async {
      contents.add(inv.namedArguments[#content] as Map<String, dynamic>);
      return const Right(null);
    });
    useCase = SaveDocumentUseCase(
      repository,
      pageCache: PageJsonCache(encoder: (p) {
        encodes++;
        return PageJsonCache.defaultEncoder(p);
      }),
    );
  });

  group('SaveDocumentUseCase page cache', () {
    test('300 pages: first save encodes all, re-save none, one edit one',
        () async {
      final doc = buildLargeDocument(pages: 300, strokesPerPage: 2);

      await useCase(doc);
      expect(encodes, 300);
      await useCase(doc);
      expect(encodes, 300);

      final pages = [...doc.pages];
      pages[7] = pages[7].copyWith(updatedAt: DateTime.utc(2027));
      await useCase(doc.copyWith(pages: pages));
      expect(encodes, 301);
    });

    test('stored content equals the uncached encoding', () async {
      final doc = buildLargeDocument(pages: 6, strokesPerPage: 2);
      await useCase(doc);
      final stored = contents.single;
      final plain = doc.toJson()..['updatedAt'] = stored['updatedAt'];
      expect(
          await const DocumentContentCodec().encode(stored), jsonEncode(plain));
    });

    test('cover page without drawings keeps identity across saves', () async {
      final doc = DrawingDocument.multiPage(
        id: 'd',
        title: 't',
        pages: [Page.createCover(index: 0), Page.create(index: 1)],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      await useCase(doc);
      expect(encodes, 2);
      await useCase(doc);
      expect(encodes, 2);
    });

    test('a different document id resets the cache', () async {
      final doc = buildLargeDocument(pages: 3, strokesPerPage: 1);
      await useCase(doc);
      await useCase(doc.copyWith(id: 'other'));
      expect(encodes, 6);
    });
  });
}
