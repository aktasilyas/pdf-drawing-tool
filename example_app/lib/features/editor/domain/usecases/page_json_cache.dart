import 'dart:convert';

import 'package:drawing_core/drawing_core.dart';
import 'package:example_app/features/documents/documents.dart';

/// Encodes a page to JSON text.
typedef PageEncoder = String Function(Page page);

/// Caches encoded page JSON by [Page] identity so an autosave only encodes
/// pages that changed. Pages are immutable, so an unchanged page is the same
/// instance; the weak [Expando] keys let replaced pages be collected.
class PageJsonCache {
  PageJsonCache({PageEncoder? encoder}) : _encoder = encoder ?? defaultEncoder;

  static String defaultEncoder(Page page) => jsonEncode(page.toJson());

  final PageEncoder _encoder;
  Expando<EncodedJson> _entries = Expando<EncodedJson>('page-json');
  String? _documentId;

  /// Encoded [page], computed at most once per instance.
  EncodedJson encode(Page page) =>
      _entries[page] ??= EncodedJson(_encoder(page));

  /// Drops all entries when [documentId] differs from the previous one.
  void retainFor(String documentId) {
    if (_documentId != documentId) clear();
    _documentId = documentId;
  }

  void clear() {
    _entries = Expando<EncodedJson>('page-json');
  }
}
