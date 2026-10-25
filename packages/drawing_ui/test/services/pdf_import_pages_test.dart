import 'package:drawing_ui/src/services/pdf_import_pages.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pdfImportPageNumbers', () {
    test('all pages', () {
      expect(pdfImportPageNumbers(PDFImportConfig.all(), 3), [1, 2, 3]);
    });

    test('a page range', () {
      final config = PDFImportConfig.pageRange(startPage: 2, endPage: 4);
      expect(pdfImportPageNumbers(config, 10), [2, 3, 4]);
    });

    test('selected pages keep their order and are copied', () {
      final selected = [5, 1];
      final config = PDFImportConfig.selectedPages(pages: selected);
      final numbers = pdfImportPageNumbers(config, 10);
      expect(numbers, [5, 1]);
      numbers.add(7);
      expect(selected, [5, 1]);
    });
  });

  test('generatePdfPageRange is empty when start > end', () {
    expect(generatePdfPageRange(start: 3, end: 1), isEmpty);
  });

  group('optimalPdfBatchSize', () {
    const mb = 1024 * 1024;

    test('is capped by the page count', () {
      expect(optimalPdfBatchSize(totalPages: 3, availableMemory: 500 * mb), 3);
    });

    test('is at least 1 and at most 50', () {
      expect(optimalPdfBatchSize(totalPages: 100, availableMemory: 0), 1);
      expect(
        optimalPdfBatchSize(totalPages: 100, availableMemory: 5000 * mb),
        50,
      );
    });
  });

  test('state machine allows error from any state', () {
    for (final state in PDFImportState.values) {
      expect(state.canTransitionTo(PDFImportState.error), isTrue);
    }
    const idle = PDFImportState.idle;
    expect(idle.canTransitionTo(PDFImportState.completed), isFalse);
  });
}
