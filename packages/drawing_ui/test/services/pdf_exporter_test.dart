import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

void main() {
  group('PDFExporter', () {
    late PDFExporter exporter;

    setUp(() {
      exporter = PDFExporter();
    });

    group('Constructor', () {
      test('should create with default options', () {
        final exporter = PDFExporter();
        expect(exporter, isNotNull);
      });

      test('should create with custom page format', () {
        final exporter = PDFExporter(
          defaultPageFormat: PDFPageFormat.a4,
        );
        expect(exporter, isNotNull);
      });
    });

    group('Page Format', () {
      test('should have A4 format', () {
        expect(PDFPageFormat.a4, isNotNull);
      });

      test('should have A5 format', () {
        expect(PDFPageFormat.a5, isNotNull);
      });

      test('should have Letter format', () {
        expect(PDFPageFormat.letter, isNotNull);
      });

      test('should have Legal format', () {
        expect(PDFPageFormat.legal, isNotNull);
      });

      test('should have custom format', () {
        final format = PDFPageFormat.custom(
          width: 600,
          height: 800,
        );
        expect(format.width, 600);
        expect(format.height, 800);
      });
    });

    group('Export Options', () {
      test('should create default export options', () {
        final options = PDFExportOptions();

        expect(options.includeBackground, true);
        expect(options.exportMode, PDFExportMode.vector);
        expect(options.quality, PDFExportQuality.high);
      });

      test('should create custom export options', () {
        final options = PDFExportOptions(
          includeBackground: false,
          exportMode: PDFExportMode.raster,
          quality: PDFExportQuality.medium,
        );

        expect(options.includeBackground, false);
        expect(options.exportMode, PDFExportMode.raster);
        expect(options.quality, PDFExportQuality.medium);
      });

      test('should copy with new values', () {
        final original = PDFExportOptions();
        final copy = original.copyWith(
          includeBackground: false,
        );

        expect(copy.includeBackground, false);
        expect(copy.exportMode, original.exportMode);
      });
    });

    group('Export Mode', () {
      test('should have vector mode', () {
        expect(PDFExportMode.vector, isNotNull);
      });

      test('should have raster mode', () {
        expect(PDFExportMode.raster, isNotNull);
      });

      test('should have hybrid mode', () {
        expect(PDFExportMode.hybrid, isNotNull);
      });
    });

    group('Export Quality', () {
      test('should have low quality', () {
        expect(PDFExportQuality.low, isNotNull);
      });

      test('should have medium quality', () {
        expect(PDFExportQuality.medium, isNotNull);
      });

      test('should have high quality', () {
        expect(PDFExportQuality.high, isNotNull);
      });

      test('should have print quality', () {
        expect(PDFExportQuality.print, isNotNull);
      });

      test('should get DPI for quality level', () {
        expect(PDFExportQuality.low.dpi, 72);
        expect(PDFExportQuality.medium.dpi, 150);
        expect(PDFExportQuality.high.dpi, 300);
        expect(PDFExportQuality.print.dpi, 600);
      });
    });

    group('Page Validation', () {
      test('should validate non-empty page', () {
        final page = Page.create(index: 0).addStroke(
          Stroke(
            id: 's1',
            points: [
              DrawingPoint(x: 0, y: 0),
              DrawingPoint(x: 100, y: 100),
            ],
            style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          ),
        );

        expect(exporter.isPageExportable(page), true);
      });

      test('should consider empty page exportable (for background)', () {
        final page = Page.create(index: 0);
        expect(exporter.isPageExportable(page), true);
      });
    });

    group('Size Calculation', () {
      test('should calculate PDF size from page size', () {
        final pageSize = PageSize(width: 595, height: 842); // A4 in points

        final pdfSize = exporter.calculatePDFSize(pageSize);

        expect(pdfSize.width, 595);
        expect(pdfSize.height, 842);
      });

      test('should handle custom page sizes', () {
        final pageSize = PageSize(width: 1000, height: 1500);

        final pdfSize = exporter.calculatePDFSize(pageSize);

        expect(pdfSize.width, 1000);
        expect(pdfSize.height, 1500);
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

      test('should provide file size for successful result', () {
        final bytes = List.generate(1024, (i) => i % 256);
        final result = PDFExportResult.success(bytes);

        expect(result.fileSizeBytes, 1024);
      });

      test('should format file size', () {
        final bytes = List.generate(1024, (i) => i % 256);
        final result = PDFExportResult.success(bytes);

        expect(result.fileSizeFormatted, contains('KB'));
      });
    });

    group('Document Metadata', () {
      test('should create metadata with title', () {
        final metadata = PDFDocumentMetadata(
          title: 'Test Document',
        );

        expect(metadata.title, 'Test Document');
      });

      test('should create metadata with all fields', () {
        final metadata = PDFDocumentMetadata(
          title: 'Test',
          author: 'John Doe',
          subject: 'Test Subject',
          keywords: ['test', 'pdf'],
          creator: 'StarNote',
        );

        expect(metadata.title, 'Test');
        expect(metadata.author, 'John Doe');
        expect(metadata.subject, 'Test Subject');
        expect(metadata.keywords, ['test', 'pdf']);
        expect(metadata.creator, 'StarNote');
      });
    });

    group('Progress Tracking', () {
      test('should calculate export progress', () {
        final progress = exporter.calculateProgress(
          currentPage: 3,
          totalPages: 10,
        );

        expect(progress, closeTo(0.3, 0.01));
      });

      test('should handle zero pages', () {
        final progress = exporter.calculateProgress(
          currentPage: 0,
          totalPages: 0,
        );

        expect(progress, 0.0);
      });

      test('should handle completion', () {
        final progress = exporter.calculateProgress(
          currentPage: 10,
          totalPages: 10,
        );

        expect(progress, 1.0);
      });
    });

    group('Error Handling', () {
      test('should validate non-empty page list', () {
        expect(
          () => exporter.exportPages(
            pages: [],
            options: PDFExportOptions(),
          ),
          throwsArgumentError,
        );
      });

      test('should validate page dimensions', () {
        final page = Page(
          id: 'p1',
          index: 0,
          name: 'Page 1',
          size: PageSize(width: 0, height: 0), // Invalid
          background: PageBackground.solid(),
          layers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(exporter.isPageExportable(page), false);
      });
    });

    group('Output Format', () {
      test('should support PDF output', () {
        expect(PDFOutputFormat.pdf, isNotNull);
      });

      test('should get file extension', () {
        expect(PDFOutputFormat.pdf.extension, 'pdf');
      });

      test('should get MIME type', () {
        expect(PDFOutputFormat.pdf.mimeType, 'application/pdf');
      });
    });

    group('Coordinate Conversion', () {
      test('should convert drawing coordinates to PDF coordinates', () {
        final drawingX = 100.0;
        final drawingY = 200.0;

        final (pdfX, pdfY) = exporter.convertCoordinates(
          drawingX: drawingX,
          drawingY: drawingY,
          pageHeight: 842.0,
        );

        // PDF has origin at bottom-left, Drawing at top-left
        expect(pdfX, drawingX);
        expect(pdfY, 842.0 - drawingY);
      });

      test('should handle zero coordinates', () {
        final (pdfX, pdfY) = exporter.convertCoordinates(
          drawingX: 0,
          drawingY: 0,
          pageHeight: 842.0,
        );

        expect(pdfX, 0);
        expect(pdfY, 842.0);
      });
    });
  });
}
