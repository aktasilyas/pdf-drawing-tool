import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_to_page_converter.dart';
import 'package:drawing_ui/src/services/pdf_page_renderer.dart';

void main() {
  group('PDFToPageConverter', () {
    late PDFToPageConverter converter;

    setUp(() {
      converter = PDFToPageConverter();
    });

    group('Constructor', () {
      test('should create with default options', () {
        final converter = PDFToPageConverter();
        expect(converter, isNotNull);
      });

      test('should create with custom options', () {
        final options = PDFRenderOptions(
          zoom: 2.0,
          devicePixelRatio: 2.0,
        );
        final converter = PDFToPageConverter(defaultRenderOptions: options);
        expect(converter, isNotNull);
      });
    });

    group('Page Size Calculation', () {
      test('should calculate page size from PDF dimensions', () {
        final size = converter.calculatePageSize(
          pdfWidth: 595.0, // A4 width in points
          pdfHeight: 842.0, // A4 height in points
        );

        expect(size.width, 595.0);
        expect(size.height, 842.0);
      });

      test('should handle landscape orientation', () {
        final size = converter.calculatePageSize(
          pdfWidth: 842.0, // Landscape A4
          pdfHeight: 595.0,
        );

        expect(size.width, 842.0);
        expect(size.height, 595.0);
      });

      test('should handle square pages', () {
        final size = converter.calculatePageSize(
          pdfWidth: 600.0,
          pdfHeight: 600.0,
        );

        expect(size.width, 600.0);
        expect(size.height, 600.0);
      });

      test('should handle very small PDF pages', () {
        final size = converter.calculatePageSize(
          pdfWidth: 100.0,
          pdfHeight: 100.0,
        );

        expect(size.width, 100.0);
        expect(size.height, 100.0);
      });

      test('should handle very large PDF pages', () {
        final size = converter.calculatePageSize(
          pdfWidth: 5000.0,
          pdfHeight: 5000.0,
        );

        expect(size.width, 5000.0);
        expect(size.height, 5000.0);
      });
    });

    group('Background Creation', () {
      test('should create solid background by default', () {
        final background = converter.createDefaultBackground();

        expect(background, isNotNull);
        expect(background.type, BackgroundType.solid);
        expect(background.color, 0xFFFFFFFF); // White
      });

      test('should create background with custom color', () {
        final background = converter.createBackgroundWithColor(0xFF000000);

        expect(background.type, BackgroundType.solid);
        expect(background.color, 0xFF000000); // Black
      });
    });

    group('Page Index Handling', () {
      test('should use provided target page index', () {
        final index = converter.determinePageIndex(
          targetIndex: 5,
          pdfPageNumber: 1,
        );

        expect(index, 5);
      });

      test('should derive index from PDF page number when target not provided', () {
        final index = converter.determinePageIndex(
          targetIndex: null,
          pdfPageNumber: 3,
        );

        expect(index, 2); // PDF page 3 → index 2 (0-based)
      });

      test('should handle first PDF page', () {
        final index = converter.determinePageIndex(
          targetIndex: null,
          pdfPageNumber: 1,
        );

        expect(index, 0);
      });
    });

    group('Page Metadata', () {
      test('should generate page name from PDF page number', () {
        final name = converter.generatePageName(
          pdfPageNumber: 1,
          documentTitle: 'Test Document',
        );

        expect(name, contains('1'));
      });

      test('should generate page name without document title', () {
        final name = converter.generatePageName(
          pdfPageNumber: 5,
          documentTitle: null,
        );

        expect(name, contains('5'));
      });

      test('should generate unique page names for different pages', () {
        final name1 = converter.generatePageName(pdfPageNumber: 1);
        final name2 = converter.generatePageName(pdfPageNumber: 2);

        expect(name1, isNot(equals(name2)));
      });
    });

    group('Batch Page Number Validation', () {
      test('should validate all pages in range', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [1, 2, 3, 4, 5],
          totalPages: 10,
        );

        expect(isValid, true);
      });

      test('should reject out of range page numbers', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [1, 2, 11],
          totalPages: 10,
        );

        expect(isValid, false);
      });

      test('should reject negative page numbers', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [1, -1, 3],
          totalPages: 10,
        );

        expect(isValid, false);
      });

      test('should reject zero page number', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [0, 1, 2],
          totalPages: 10,
        );

        expect(isValid, false);
      });

      test('should accept single page', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [5],
          totalPages: 10,
        );

        expect(isValid, true);
      });

      test('should accept all pages', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          totalPages: 10,
        );

        expect(isValid, true);
      });

      test('should reject empty list', () {
        final isValid = converter.validatePageNumbers(
          pageNumbers: [],
          totalPages: 10,
        );

        expect(isValid, false);
      });
    });

    group('Page Range Generation', () {
      test('should generate range for all pages', () {
        final range = converter.generatePageRange(1, 5);

        expect(range, [1, 2, 3, 4, 5]);
      });

      test('should generate range for single page', () {
        final range = converter.generatePageRange(3, 3);

        expect(range, [3]);
      });

      test('should handle reversed range', () {
        final range = converter.generatePageRange(5, 1);

        expect(range, isEmpty);
      });
    });

    group('Conversion Options', () {
      test('should create default conversion options', () {
        final options = PDFConversionOptions();

        expect(options.includeAnnotations, false);
        expect(options.preserveLinks, false);
        expect(options.embedImages, true);
      });

      test('should create custom conversion options', () {
        final options = PDFConversionOptions(
          includeAnnotations: true,
          preserveLinks: true,
          embedImages: false,
        );

        expect(options.includeAnnotations, true);
        expect(options.preserveLinks, true);
        expect(options.embedImages, false);
      });

      test('should copy with new values', () {
        final original = PDFConversionOptions(includeAnnotations: false);
        final copy = original.copyWith(includeAnnotations: true);

        expect(copy.includeAnnotations, true);
        expect(copy.preserveLinks, original.preserveLinks);
      });
    });

    group('Error Handling', () {
      test('should handle invalid page dimensions', () {
        expect(
          () => converter.calculatePageSize(
            pdfWidth: 0.0,
            pdfHeight: 842.0,
          ),
          throwsArgumentError,
        );
      });

      test('should handle negative page dimensions', () {
        expect(
          () => converter.calculatePageSize(
            pdfWidth: -100.0,
            pdfHeight: 842.0,
          ),
          throwsArgumentError,
        );
      });

      test('should handle invalid PDF page number', () {
        expect(
          () => converter.determinePageIndex(
            targetIndex: null,
            pdfPageNumber: 0,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Page Properties', () {
      test('should create page with empty layers', () {
        final page = converter.createEmptyPage(
          index: 0,
          width: 595.0,
          height: 842.0,
        );

        expect(page.index, 0);
        expect(page.size.width, 595.0);
        expect(page.size.height, 842.0);
        expect(page.layers, isEmpty);
      });

      test('should create page with default background', () {
        final page = converter.createEmptyPage(
          index: 0,
          width: 595.0,
          height: 842.0,
        );

        expect(page.background.type, BackgroundType.solid);
      });

      test('should create page with custom name', () {
        final page = converter.createEmptyPage(
          index: 0,
          width: 595.0,
          height: 842.0,
          name: 'Custom Page',
        );

        expect(page.name, 'Custom Page');
      });
    });
  });
}
