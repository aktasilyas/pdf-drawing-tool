import 'package:drawing_ui/src/services/pdf_page_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePdfPageRange', () {
    PdfPageRangeError? v(int s, int e, {int total = 640}) =>
        validatePdfPageRange(s, e, total: total);

    test('accepts boundaries', () {
      expect(v(1, 500), isNull);
      expect(v(141, 640), isNull);
      expect(v(5, 5), isNull);
    });

    test('rejects start below one', () {
      expect(v(0, 10), PdfPageRangeError.startBelowOne);
    });

    test('rejects start after end', () {
      expect(v(10, 5), PdfPageRangeError.startAfterEnd);
    });

    test('rejects end after total', () {
      expect(v(1, 641), PdfPageRangeError.endAfterTotal);
    });

    test('rejects ranges longer than the limit', () {
      expect(v(1, 501), PdfPageRangeError.tooLong);
      expect(v(1, 600), PdfPageRangeError.tooLong);
    });
  });

  group('PdfPageRange', () {
    test('has value equality', () {
      expect(const PdfPageRange(1, 500), const PdfPageRange(1, 500));
      expect(const PdfPageRange(1, 500).hashCode,
          const PdfPageRange(1, 500).hashCode);
      expect(const PdfPageRange(1, 500), isNot(const PdfPageRange(2, 500)));
    });

    test('toConfig builds a page range config', () {
      final config = const PdfPageRange(141, 640).toConfig();
      expect(config.startPage, 141);
      expect(config.endPage, 640);
    });
  });
}
