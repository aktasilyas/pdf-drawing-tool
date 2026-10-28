import 'dart:convert';

import 'package:drawing_ui/src/panels/export_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sanitizeFilename', () {
    test('keeps a normal title unchanged', () {
      expect(sanitizeFilename('Ders Notları', fallback: 'x'), 'Ders Notları');
    });

    test('long Turkish title stays within the byte budget', () {
      final name = sanitizeFilename('ş' * 300, fallback: 'x');
      expect(utf8.encode(name).length + 22, lessThanOrEqualTo(255));
      expect(name, matches(RegExp(r'^ş+$')));
    });

    test('does not split an emoji at the cut point', () {
      final name = sanitizeFilename('a' * 232 + '😀😀', fallback: 'x');
      expect(name, 'a' * 232);
      final emoji = sanitizeFilename('a' * 230 + '😀', fallback: 'x');
      expect(emoji.runes.every((r) => r != 0xFFFD), isTrue);
      expect(utf8.encode(emoji).length + 22, lessThanOrEqualTo(255));
    });

    test('removes newlines, tabs and reserved characters', () {
      expect(sanitizeFilename('a\nb\tc/d', fallback: 'x'), 'abcd');
    });

    test('whitespace-only title uses the fallback', () {
      expect(sanitizeFilename('  \n ', fallback: 'Notebook'), 'Notebook');
    });

    test('trims spaces and dots', () {
      expect(sanitizeFilename(' ..name.. ', fallback: 'x'), 'name');
    });
  });

  test('buildExportFilename stays within 255 bytes with extension', () {
    final name = buildExportFilename('ğ' * 400, fallback: 'x');
    expect(utf8.encode('$name.pdf').length, lessThanOrEqualTo(255));
  });
}
