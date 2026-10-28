import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';

import '../../../../helpers/large_document.dart';

void main() {
  group('DocumentJsonSlicer', () {
    test('large document: same bytes as single-shot jsonEncode', () async {
      final document = buildLargeDocument(pages: 40);
      // Zero budget yields after every page.
      const slicer = DocumentJsonSlicer(sliceBudget: Duration.zero);
      expect(DocumentJsonSlicer.weightOf(document), greaterThan(5000));

      final sliced = await slicer.toJson(document);

      expect(jsonEncode(sliced), jsonEncode(document.toJson()));
    });

    test('300-page fixture: identical to toJson()', () async {
      final document = buildLargeDocument();
      final sliced = await const DocumentJsonSlicer().toJson(document);
      expect(jsonEncode(sliced), jsonEncode(document.toJson()));
    });

    test('small document: single-shot path, identical output', () async {
      final document = buildLargeDocument(pages: 2, strokesPerPage: 2);
      final sliced = await const DocumentJsonSlicer().toJson(document);
      expect(jsonEncode(sliced), jsonEncode(document.toJson()));
    });

    test('cached path: codec output is byte-identical to jsonEncode', () async {
      final document = buildLargeDocument(pages: 5, strokesPerPage: 3);
      final json = await const DocumentJsonSlicer().toJson(
        document,
        cache: PageJsonCache(),
      );
      final encoded = await const DocumentContentCodec().encode(json);
      expect(encoded, jsonEncode(document.toJson()));
    });

    test('cached path: header keys and order equal toJson()', () async {
      final document = buildLargeDocument(pages: 5, strokesPerPage: 3);
      final json = await const DocumentJsonSlicer().toJson(
        document,
        cache: PageJsonCache(),
      );
      expect(json.keys.toList(), document.toJson().keys.toList());
      expect(json['pages'], everyElement(isA<EncodedJson>()));
    });

    test('cached path: second call encodes nothing', () async {
      final document = buildLargeDocument(pages: 5, strokesPerPage: 3);
      var calls = 0;
      final cache = PageJsonCache(encoder: (p) {
        calls++;
        return PageJsonCache.defaultEncoder(p);
      });
      await const DocumentJsonSlicer().toJson(document, cache: cache);
      await const DocumentJsonSlicer().toJson(document, cache: cache);
      expect(calls, 5);
    });
  });
}
