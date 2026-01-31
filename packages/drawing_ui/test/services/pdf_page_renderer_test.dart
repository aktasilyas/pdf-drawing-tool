import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/pdf_page_renderer.dart';

void main() {
  group('PDFPageRenderer', () {
    late PDFPageRenderer renderer;

    setUp(() {
      renderer = PDFPageRenderer();
    });

    group('DPI Calculation', () {
      test('should calculate DPI for zoom 1.0 and devicePixelRatio 1.0', () {
        final dpi = renderer.calculateDPI(
          zoom: 1.0,
          devicePixelRatio: 1.0,
        );

        expect(dpi, 72.0); // Base DPI
      });

      test('should calculate DPI for zoom 2.0 and devicePixelRatio 1.0', () {
        final dpi = renderer.calculateDPI(
          zoom: 2.0,
          devicePixelRatio: 1.0,
        );

        expect(dpi, 144.0); // 72 × 2.0 × 1.0
      });

      test('should calculate DPI for zoom 1.0 and devicePixelRatio 2.0', () {
        final dpi = renderer.calculateDPI(
          zoom: 1.0,
          devicePixelRatio: 2.0,
        );

        expect(dpi, 144.0); // 72 × 1.0 × 2.0
      });

      test('should calculate DPI for zoom 2.0 and devicePixelRatio 2.0', () {
        final dpi = renderer.calculateDPI(
          zoom: 2.0,
          devicePixelRatio: 2.0,
        );

        expect(dpi, 288.0); // 72 × 2.0 × 2.0
      });

      test('should calculate DPI for fractional zoom', () {
        final dpi = renderer.calculateDPI(
          zoom: 1.5,
          devicePixelRatio: 1.0,
        );

        expect(dpi, 108.0); // 72 × 1.5 × 1.0
      });

      test('should calculate DPI for fractional devicePixelRatio', () {
        final dpi = renderer.calculateDPI(
          zoom: 1.0,
          devicePixelRatio: 1.5,
        );

        expect(dpi, 108.0); // 72 × 1.0 × 1.5
      });

      test('should handle very high zoom levels', () {
        final dpi = renderer.calculateDPI(
          zoom: 10.0,
          devicePixelRatio: 3.0,
        );

        expect(dpi, 2160.0); // 72 × 10.0 × 3.0
      });

      test('should handle very low zoom levels', () {
        final dpi = renderer.calculateDPI(
          zoom: 0.1,
          devicePixelRatio: 1.0,
        );

        expect(dpi, 7.2); // 72 × 0.1 × 1.0
      });
    });

    group('Render Settings', () {
      test('should calculate width for given DPI', () {
        final width = renderer.calculateRenderWidth(
          pageWidth: 595.0, // A4 width in points
          dpi: 144.0,
        );

        // 595 points × (144 / 72) = 1190 pixels
        expect(width, 1190.0);
      });

      test('should calculate height for given DPI', () {
        final height = renderer.calculateRenderHeight(
          pageHeight: 842.0, // A4 height in points
          dpi: 144.0,
        );

        // 842 points × (144 / 72) = 1684 pixels
        expect(height, 1684.0);
      });

      test('should calculate render size', () {
        final size = renderer.calculateRenderSize(
          pageWidth: 595.0,
          pageHeight: 842.0,
          dpi: 144.0,
        );

        expect(size.width, 1190.0);
        expect(size.height, 1684.0);
      });
    });

    group('Render Quality', () {
      test('should determine quality level for zoom', () {
        expect(renderer.getQualityLevel(0.5), RenderQuality.low);
        expect(renderer.getQualityLevel(1.0), RenderQuality.medium);
        expect(renderer.getQualityLevel(2.0), RenderQuality.high);
        expect(renderer.getQualityLevel(4.0), RenderQuality.veryHigh);
      });

      test('should recommend DPI for quality level', () {
        expect(
          renderer.getRecommendedDPI(RenderQuality.low, 1.0),
          lessThan(144.0),
        );
        expect(
          renderer.getRecommendedDPI(RenderQuality.medium, 1.0),
          equals(144.0),
        );
        expect(
          renderer.getRecommendedDPI(RenderQuality.high, 1.0),
          greaterThan(144.0),
        );
      });
    });

    group('Page Number Validation', () {
      test('should validate valid page numbers', () {
        expect(renderer.isValidPageNumber(1, 10), true);
        expect(renderer.isValidPageNumber(5, 10), true);
        expect(renderer.isValidPageNumber(10, 10), true);
      });

      test('should reject invalid page numbers', () {
        expect(renderer.isValidPageNumber(0, 10), false);
        expect(renderer.isValidPageNumber(-1, 10), false);
        expect(renderer.isValidPageNumber(11, 10), false);
      });

      test('should handle single page document', () {
        expect(renderer.isValidPageNumber(1, 1), true);
        expect(renderer.isValidPageNumber(2, 1), false);
      });
    });

    group('Render Options', () {
      test('should create default render options', () {
        final options = PDFRenderOptions();

        expect(options.zoom, 1.0);
        expect(options.devicePixelRatio, 1.0);
        expect(options.backgroundColor, 0xFFFFFFFF);
      });

      test('should create custom render options', () {
        final options = PDFRenderOptions(
          zoom: 2.0,
          devicePixelRatio: 2.0,
          backgroundColor: 0xFF000000,
          quality: RenderQuality.high,
        );

        expect(options.zoom, 2.0);
        expect(options.devicePixelRatio, 2.0);
        expect(options.backgroundColor, 0xFF000000);
        expect(options.quality, RenderQuality.high);
      });

      test('should copy with new values', () {
        final original = PDFRenderOptions(zoom: 1.0);
        final copy = original.copyWith(zoom: 2.0);

        expect(copy.zoom, 2.0);
        expect(copy.devicePixelRatio, original.devicePixelRatio);
      });
    });

    group('Cache Key Generation', () {
      test('should generate unique cache key for page and options', () {
        final key1 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 1,
          options: PDFRenderOptions(zoom: 1.0),
        );

        final key2 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 1,
          options: PDFRenderOptions(zoom: 2.0),
        );

        expect(key1, isNot(equals(key2)));
      });

      test('should generate same key for same inputs', () {
        final options = PDFRenderOptions(zoom: 1.5);

        final key1 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 1,
          options: options,
        );

        final key2 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 1,
          options: options,
        );

        expect(key1, equals(key2));
      });

      test('should generate different keys for different pages', () {
        final options = PDFRenderOptions();

        final key1 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 1,
          options: options,
        );

        final key2 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 2,
          options: options,
        );

        expect(key1, isNot(equals(key2)));
      });

      test('should generate different keys for different documents', () {
        final options = PDFRenderOptions();

        final key1 = renderer.generateCacheKey(
          documentId: 'doc1',
          pageNumber: 1,
          options: options,
        );

        final key2 = renderer.generateCacheKey(
          documentId: 'doc2',
          pageNumber: 1,
          options: options,
        );

        expect(key1, isNot(equals(key2)));
      });
    });

    group('Edge Cases', () {
      test('should handle zero zoom', () {
        final dpi = renderer.calculateDPI(
          zoom: 0.0,
          devicePixelRatio: 1.0,
        );

        expect(dpi, 0.0);
      });

      test('should handle zero devicePixelRatio', () {
        final dpi = renderer.calculateDPI(
          zoom: 1.0,
          devicePixelRatio: 0.0,
        );

        expect(dpi, 0.0);
      });

      test('should handle very small page dimensions', () {
        final size = renderer.calculateRenderSize(
          pageWidth: 1.0,
          pageHeight: 1.0,
          dpi: 72.0,
        );

        expect(size.width, 1.0);
        expect(size.height, 1.0);
      });

      test('should handle very large page dimensions', () {
        final size = renderer.calculateRenderSize(
          pageWidth: 10000.0,
          pageHeight: 10000.0,
          dpi: 72.0,
        );

        expect(size.width, 10000.0);
        expect(size.height, 10000.0);
      });
    });
  });
}
