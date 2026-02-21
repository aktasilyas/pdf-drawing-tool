import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

void main() {
  group('PDFExporter', () {
    group('Constructor', () {
      test('should create instance', () {
        final exporter = PDFExporter();
        expect(exporter, isNotNull);
      });
    });

    group('Page Format', () {
      test('should have A4 format', () {
        expect(PDFPageFormat.a4.width, 595);
        expect(PDFPageFormat.a4.height, 842);
      });

      test('should have A5 format', () {
        expect(PDFPageFormat.a5.width, 420);
        expect(PDFPageFormat.a5.height, 595);
      });

      test('should have Letter format', () {
        expect(PDFPageFormat.letter.width, 612);
        expect(PDFPageFormat.letter.height, 792);
      });

      test('should have Legal format', () {
        expect(PDFPageFormat.legal.width, 612);
        expect(PDFPageFormat.legal.height, 1008);
      });
    });

    group('Export Options', () {
      test('should create default export options', () {
        const options = PDFExportOptions();

        expect(options.includeBackground, true);
        expect(options.exportMode, PDFExportMode.raster);
        expect(options.quality, PDFExportQuality.medium);
      });

      test('should create custom export options', () {
        const options = PDFExportOptions(
          includeBackground: false,
          exportMode: PDFExportMode.vector,
          quality: PDFExportQuality.high,
        );

        expect(options.includeBackground, false);
        expect(options.exportMode, PDFExportMode.vector);
        expect(options.quality, PDFExportQuality.high);
      });

      test('should copy with new values', () {
        const original = PDFExportOptions();
        final copy = original.copyWith(includeBackground: false);

        expect(copy.includeBackground, false);
        expect(copy.exportMode, original.exportMode);
      });
    });

    group('Export Mode', () {
      test('should have all modes', () {
        expect(PDFExportMode.vector, isNotNull);
        expect(PDFExportMode.raster, isNotNull);
        expect(PDFExportMode.hybrid, isNotNull);
      });
    });

    group('Export Quality', () {
      test('should get DPI for quality level', () {
        expect(PDFExportQuality.low.dpi, 72);
        expect(PDFExportQuality.medium.dpi, 150);
        expect(PDFExportQuality.high.dpi, 300);
        expect(PDFExportQuality.print.dpi, 600);
      });
    });

    group('Export Result', () {
      test('should create successful result', () {
        final bytes = [1, 2, 3, 4];
        final result = PDFExportResult.success(bytes);

        expect(result.isSuccess, true);
        expect(result.pdfBytes, bytes);
        expect(result.errorMessage, isNull);
      });

      test('should create error result', () {
        final result = PDFExportResult.error('Export failed');

        expect(result.isSuccess, false);
        expect(result.pdfBytes, isEmpty);
        expect(result.errorMessage, 'Export failed');
      });

      test('should provide file size', () {
        final bytes = List.generate(1024, (i) => i % 256);
        final result = PDFExportResult.success(bytes);

        expect(result.fileSizeBytes, 1024);
      });

      test('should format file size in KB', () {
        final bytes = List.generate(1024, (i) => i % 256);
        final result = PDFExportResult.success(bytes);

        expect(result.fileSizeFormatted, contains('KB'));
      });

      test('should format file size in MB', () {
        final bytes = List.generate(1024 * 1024 + 1, (i) => i % 256);
        final result = PDFExportResult.success(bytes);

        expect(result.fileSizeFormatted, contains('MB'));
      });

      test('should format file size in B', () {
        final result = PDFExportResult.success([1, 2, 3]);

        expect(result.fileSizeFormatted, '3 B');
      });
    });

    group('Document Metadata', () {
      test('should create metadata with title', () {
        const metadata = PDFDocumentMetadata(title: 'Test Document');

        expect(metadata.title, 'Test Document');
        expect(metadata.creator, 'StarNote');
      });

      test('should create metadata with all fields', () {
        const metadata = PDFDocumentMetadata(
          title: 'Test',
          author: 'John Doe',
          creator: 'StarNote',
        );

        expect(metadata.title, 'Test');
        expect(metadata.author, 'John Doe');
        expect(metadata.creator, 'StarNote');
      });
    });
  });
}
