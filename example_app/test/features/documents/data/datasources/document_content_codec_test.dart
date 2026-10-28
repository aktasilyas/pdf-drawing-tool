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
        greaterThanOrEqualTo(DocumentContentCodec.defaultEncodeSliceWeight),
      );
      expect(await codec.encode(small), jsonEncode(small));
      expect(await codec.encode(large), jsonEncode(large));
    });

    test('EncodedJson pages encode exactly like plain maps', () async {
      const codec = DocumentContentCodec();
      for (final plain in [small, large]) {
        final pages = plain['pages'] as List;
        final pre = {
          ...plain,
          'pages': [for (final p in pages) EncodedJson(jsonEncode(p))],
        };
        expect(await codec.encode(pre), jsonEncode(plain));
      }
    });

    test('jsonEncode of a map holding EncodedJson matches plain output', () {
      final page = (small['pages'] as List).first;
      expect(
        jsonEncode({
          'pages': [EncodedJson(jsonEncode(page))],
        }),
        jsonEncode({
          'pages': [page],
        }),
      );
    });

    test('sliced encode yields between pages and keeps the output', () async {
      const codec = DocumentContentCodec(sliceBudget: Duration.zero);
      var ticks = 0;
      final ticker = Stream<void>.periodic(Duration.zero).listen((_) {
        ticks++;
      });
      final encoded = await codec.encode(large);
      await ticker.cancel();
      expect(encoded, jsonEncode(large));
      expect(ticks, greaterThan(0));
    });

    test('content without a page list encodes in one go', () async {
      const codec = DocumentContentCodec(encodeSliceWeight: 0);
      final legacy = {
        'id': 'v1',
        'layers': [
          {'strokes': <Object>[]},
        ],
      };
      expect(await codec.encode(legacy), jsonEncode(legacy));
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

    test('getDrawingDocument equals fromJson of the stored map', () async {
      for (final document in [
        buildLargeDocument(),
        buildLargeDocument(pages: 2, strokesPerPage: 2),
      ]) {
        final original = document.toJson();
        await ds.saveDocumentContent(document.id, original);

        final model = await ds.getDrawingDocument(document.id);

        expect(model!.toJson(), equals(original));
        expect(model.pageCount, document.pageCount);
      }
      expect(await ds.getDrawingDocument('missing'), isNull);
    });

    test('getDrawingDocument reports corrupt content', () async {
      await ds.saveDocumentContent('bad', {'invalid': 'data'});
      await expectLater(
        ds.getDrawingDocument('bad'),
        throwsA(isA<CacheException>()),
      );
    });

    test('overlapping saves land in call order', () async {
      final sliced = DocumentLocalDatasourceImpl(
        db,
        codec: const DocumentContentCodec(sliceBudget: Duration.zero),
      );
      final older = buildLargeDocument(pages: 30).toJson();
      final newer = buildLargeDocument(pages: 1).toJson();

      // The older, large save yields mid-encode; the newer one is quick.
      await Future.wait([
        sliced.saveDocumentContent('doc', older),
        sliced.saveDocumentContent('doc', newer),
      ]);

      expect(await sliced.getDocumentContent('doc'), equals(newer));
    });

    test('a failed save does not block the next one', () async {
      final cyclic = <String, dynamic>{};
      cyclic['self'] = cyclic;
      await expectLater(
        ds.saveDocumentContent('doc', cyclic),
        throwsA(isA<CacheException>()),
      );
      await ds.saveDocumentContent('doc', {'ok': true});
      expect(await ds.getDocumentContent('doc'), {'ok': true});
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
