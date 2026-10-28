/// File names for exported documents.
library;

import 'dart:convert';

/// Builds an export filename with title + date/time stamp.
String buildExportFilename(String title, {required String fallback}) {
  final base = sanitizeFilename(title, fallback: fallback);
  final now = DateTime.now();
  final stamp = '${now.year}'
      '${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}'
      '_'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}';
  return '${base}_$stamp';
}

/// Longest file name the file systems we target accept, in UTF-8 bytes.
const int _maxFileNameBytes = 255;

/// Room kept for the `_yyyyMMdd_HHmm` stamp and the extension (`.pdf`, `.png`).
const int _reservedBytes = 14 + 8;

final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F\u0080-\u009F]');
final RegExp _forbiddenChars = RegExp(r'[<>:"/\\|?*]');

/// Sanitizes a string for use as a filename.
///
/// Removes control and reserved characters, trims spaces and dots, falls back
/// when nothing is left, and cuts on a whole code point so that the result plus
/// the export stamp and extension stays within 255 UTF-8 bytes.
String sanitizeFilename(String title, {required String fallback}) {
  final cleaned = _clean(title);
  final name = cleaned.isEmpty ? _clean(fallback) : cleaned;
  return _truncateBytes(name, _maxFileNameBytes - _reservedBytes);
}

String _clean(String value) => value
    .replaceAll(_controlChars, '')
    .replaceAll(_forbiddenChars, '')
    .trim()
    .replaceAll(RegExp(r'^\.+|\.+$'), '')
    .trim();

String _truncateBytes(String value, int maxBytes) {
  var bytes = 0;
  final out = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    bytes += utf8.encode(char).length;
    if (bytes > maxBytes) break;
    out.write(char);
  }
  return out.toString().trim();
}
