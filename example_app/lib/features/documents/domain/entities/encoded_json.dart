import 'dart:convert';

/// JSON text that was already produced by `jsonEncode`, so writers can embed
/// it verbatim instead of encoding the same value again.
final class EncodedJson {
  const EncodedJson(this.text);

  /// Output of `jsonEncode(...)`.
  final String text;

  /// Safety net: a plain `jsonEncode` of a map holding this value still
  /// yields the same bytes (slow path), so no consumer can corrupt content.
  Object? toJson() => jsonDecode(text);
}
