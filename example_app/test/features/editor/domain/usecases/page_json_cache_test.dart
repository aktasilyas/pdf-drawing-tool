import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';
import 'package:example_app/features/editor/editor.dart';

import '../../../../helpers/large_document.dart';

void main() {
  group('PageJsonCache', () {
    final page = buildLargeDocument(pages: 2, strokesPerPage: 2).pages.first;
    var calls = 0;
    late PageJsonCache cache;

    setUp(() {
      calls = 0;
      cache = PageJsonCache(encoder: (p) {
        calls++;
        return PageJsonCache.defaultEncoder(p);
      });
    });

    test('same page twice encodes once, with the plain bytes', () {
      final first = cache.encode(page);
      final second = cache.encode(page);
      expect(calls, 1);
      expect(identical(first, second), isTrue);
      expect(first, isA<EncodedJson>());
      expect(first.text, jsonEncode(page.toJson()));
    });

    test('a new Page instance is a miss', () {
      cache.encode(page);
      cache.encode(page.copyWith(updatedAt: DateTime.utc(2027)));
      expect(calls, 2);
    });

    test('clear drops entries', () {
      cache.encode(page);
      cache.clear();
      cache.encode(page);
      expect(calls, 2);
    });

    test('retainFor keeps entries for the same id, drops for another', () {
      cache.retainFor('a');
      cache.encode(page);
      cache.retainFor('a');
      cache.encode(page);
      expect(calls, 1);
      cache.retainFor('b');
      cache.encode(page);
      expect(calls, 2);
    });
  });
}
