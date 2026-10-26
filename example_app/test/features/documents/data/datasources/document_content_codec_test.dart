import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/core/core.dart';
import 'package:example_app/features/documents/documents.dart';

import '../../../../helpers/large_document.dart';

void main() {
  group('DocumentContentCodec', () {
    final small = buildLargeDocument(pages: 2, strokesPerPage: 2).toJson();
    final large = buildLargeDocument(pages: 30).toJson();

    test('contentWeight counts pages, strokes and points', () {
      final doc = buildLargeDocument(
        pages: 3,
        strokesPerPage: 4,
        pointsPerStroke: 5,
      );
      expect(DocumentContentCodec.contentWeight(doc.toJson()), 3 + 12 + 60);
    });

    test('contentWeight tolerates unknown shapes', () {
      expect(DocumentContentCodec.contentWeight({}), 0);
      expect(
        DocumentContentCodec.contentWeight({
          'pages': [
            'x',
            {'layers': 'y'},
          ],
        }),
        2,
      );
    });

    test('small and large content encode exactly like jsonEncode', () async {
      const codec = DocumentContentCodec();
      expect(
        DocumentContentCodec.contentWeight(large),
        greaterThanOrEqualTo(DocumentContentCodec.defaultEncodeOffloadWeight),
      );
      expect(await codec.encode(small), jsonEncode(small));
      expect(await codec.encode(large), jsonEncode(large));
    });

    test('offloaded decode matches inline decode', () async {
      final data = jsonEncode(large);
      expect(
        data.length,
        greaterThanOrEqualTo(DocumentContentCodec.defaultDecodeOffloadLength),
      );
      const offloaded = DocumentContentCodec();
      const inline = DocumentContentCodec.inline();
      expect(await offloaded.decode(data), await inline.decode(data));
    });

    test('invalid JSON fails on the isolate path too', () async {
      const codec = DocumentContentCodec(decodeOffloadLength: 0);
      await expectLater(codec.decode('{not json'), throwsFormatException);
    });
  });

  group('DocumentLocalDatasourceImpl content', () {
    late AppDatabase db;
    late DocumentLocalDatasourceImpl ds;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      ds = DocumentLocalDatasourceImpl(db);
    });

    tearDown(() => db.close());

    test('300-page document with strokes round-trips unchanged', () async {
      final document = buildLargeDocument();
      final original = document.toJson();

      await ds.saveDocumentContent(document.id, original);
      final loaded = await ds.getDocumentContent(document.id);

      expect(loaded, equals(original));
      final restored = DrawingDocument.fromJson(loaded!);
      expect(restored.pageCount, 300);
      expect(restored.pages.last.layers.single.strokes, hasLength(20));
      expect(restored.toJson(), equals(original));
    });

    test('corrupt content still maps to CacheException', () async {
      await db.into(db.documentContents).insert(
            DocumentContentsCompanion.insert(
              documentId: 'broken',
              data: '{not json',
              updatedAt: DateTime.utc(2026),
            ),
          );
      await expectLater(
        ds.getDocumentContent('broken'),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
