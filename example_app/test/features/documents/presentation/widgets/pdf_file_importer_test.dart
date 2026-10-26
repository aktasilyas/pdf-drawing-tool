import 'package:flutter_test/flutter_test.dart';

import 'package:example_app/features/documents/documents.dart';

void main() {
  group('pdfTitleFromFileName', () {
    test('strips a trailing .pdf', () {
      expect(pdfTitleFromFileName('Report.pdf'), 'Report');
    });

    test('strips the extension case-insensitively', () {
      expect(pdfTitleFromFileName('Scan.PDF'), 'Scan');
      expect(pdfTitleFromFileName('Scan.Pdf'), 'Scan');
    });

    test('keeps .pdf in the middle of the name', () {
      expect(pdfTitleFromFileName('a.pdf.backup'), 'a.pdf.backup');
      expect(pdfTitleFromFileName('my.pdf notes.pdf'), 'my.pdf notes');
    });

    test('strips only one extension', () {
      expect(pdfTitleFromFileName('a.pdf.pdf'), 'a.pdf');
    });

    test('leaves names without an extension untouched', () {
      expect(pdfTitleFromFileName('Lecture 1'), 'Lecture 1');
    });
  });
}
