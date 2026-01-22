import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_export_service.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';

void main() {
  group('PDFExportService', () {
    late PDFExportService service;

    setUp(() {
      service = PDFExportService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Constructor', () {
      test('should create with default settings', () {
        final service = PDFExportService();
        expect(service, isNotNull);
        expect(service.isDisposed, false);
      });

      test('should create with custom exporter', () {
        final exporter = PDFExporter();
        final service = PDFExportService(exporter: exporter);
        expect(service, isNotNull);
      });
    });

    group('State Management', () {
      test('should start in idle state', () {
        expect(service.state, PDFExportState.idle);
      });

      test('should track exporting state', () {
        expect(service.isExporting, false);
      });

      test('should have no error initially', () {
        expect(service.hasError, false);
        expect(service.errorMessage, isNull);
      });
    });

    group('Progress Tracking', () {
      test('should track current progress', () {
        expect(service.currentProgress, 0.0);
      });

      test('should track total pages', () {
        expect(service.totalPages, 0);
      });

      test('should track processed pages', () {
        expect(service.processedPages, 0);
      });

      test('should calculate progress percentage', () {
        expect(service.progressPercentage, 0);
      });
    });

    group('Export Configuration', () {
      test('should create default export options', () {
        final config = ExportConfiguration();

        expect(config.exportMode, PDFExportMode.vector);
        expect(config.quality, PDFExportQuality.high);
        expect(config.includeBackground, true);
      });

      test('should create custom export options', () {
        final config = ExportConfiguration(
          exportMode: PDFExportMode.raster,
          quality: PDFExportQuality.medium,
          includeBackground: false,
        );

        expect(config.exportMode, PDFExportMode.raster);
        expect(config.quality, PDFExportQuality.medium);
        expect(config.includeBackground, false);
      });

      test('should convert to PDFExportOptions', () {
        final config = ExportConfiguration(
          exportMode: PDFExportMode.hybrid,
          quality: PDFExportQuality.print,
        );

        final options = config.toExportOptions();

        expect(options.exportMode, PDFExportMode.hybrid);
        expect(options.quality, PDFExportQuality.print);
      });
    });

    group('Export State', () {
      test('should have idle state', () {
        expect(PDFExportState.idle, isNotNull);
      });

      test('should have preparing state', () {
        expect(PDFExportState.preparing, isNotNull);
      });

      test('should have exporting state', () {
        expect(PDFExportState.exporting, isNotNull);
      });

      test('should have completed state', () {
        expect(PDFExportState.completed, isNotNull);
      });

      test('should have error state', () {
        expect(PDFExportState.error, isNotNull);
      });
    });

    group('Export Result', () {
      test('should create successful result', () {
        final bytes = [1, 2, 3, 4];
        final result = PDFExportServiceResult.success(bytes);

        expect(result.isSuccess, true);
        expect(result.pdfBytes, bytes);
        expect(result.errorMessage, isNull);
      });

      test('should create error result', () {
        final result = PDFExportServiceResult.error('Export failed');

        expect(result.isSuccess, false);
        expect(result.pdfBytes, isEmpty);
        expect(result.errorMessage, 'Export failed');
      });

      test('should provide file size', () {
        final bytes = List.generate(1024, (i) => i % 256);
        final result = PDFExportServiceResult.success(bytes);

        expect(result.fileSizeBytes, 1024);
      });

      test('should format file size', () {
        final bytes = List.generate(1024, (i) => i % 256);
        final result = PDFExportServiceResult.success(bytes);

        expect(result.fileSizeFormatted, contains('KB'));
      });
    });

    group('Page Validation', () {
      test('should validate non-empty pages list', () {
        final pages = [Page.create(index: 0)];

        expect(service.validatePages(pages), true);
      });

      test('should reject empty pages list', () {
        expect(service.validatePages([]), false);
      });

      test('should validate exportable pages', () {
        final page = Page.create(index: 0);

        expect(service.isPageExportable(page), true);
      });

      test('should reject pages with invalid dimensions', () {
        final page = Page(
          id: 'p1',
          index: 0,
          name: 'Page 1',
          size: PageSize(width: 0, height: 0),
          background: PageBackground.solid(),
          layers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(service.isPageExportable(page), false);
      });
    });

    group('Progress Calculation', () {
      test('should calculate progress for partial completion', () {
        final progress = service.calculateProgress(
          processedPages: 3,
          totalPages: 10,
        );

        expect(progress, closeTo(0.3, 0.01));
      });

      test('should handle zero pages', () {
        final progress = service.calculateProgress(
          processedPages: 0,
          totalPages: 0,
        );

        expect(progress, 0.0);
      });

      test('should handle completion', () {
        final progress = service.calculateProgress(
          processedPages: 10,
          totalPages: 10,
        );

        expect(progress, 1.0);
      });
    });

    group('State Transitions', () {
      test('should transition from idle to preparing', () {
        expect(service.canTransitionTo(PDFExportState.preparing), true);
      });

      test('should not allow invalid transitions', () {
        expect(service.canTransitionTo(PDFExportState.completed), false);
      });

      test('should allow transition to error from any state', () {
        expect(service.canTransitionTo(PDFExportState.error), true);
      });
    });

    group('Metadata Handling', () {
      test('should create metadata from document', () {
        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Test Document',
          pages: [Page.create(index: 0)],
        );

        final metadata = service.createMetadata(doc);

        expect(metadata.title, 'Test Document');
      });

      test('should handle document without title', () {
        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: '',
          pages: [Page.create(index: 0)],
        );

        final metadata = service.createMetadata(doc);

        expect(metadata.title, isNotNull);
      });
    });

    group('Export Mode Selection', () {
      test('should recommend vector for simple pages', () {
        final page = Page.create(index: 0).addStroke(
          Stroke(
            id: 's1',
            points: [
              DrawingPoint(x: 0, y: 0),
              DrawingPoint(x: 100, y: 100),
            ],
            style: StrokeStyle.ballpoint(),
          ),
        );

        final mode = service.recommendExportMode(page);
        expect(mode, PDFExportMode.vector);
      });

      test('should recommend raster for complex pages', () {
        var page = Page.create(index: 0);

        for (int i = 0; i < 2000; i++) {
          page = page.addStroke(
            Stroke(
              id: 's$i',
              points: [
                DrawingPoint(x: 0, y: 0),
                DrawingPoint(x: 100, y: 100),
              ],
              style: StrokeStyle.ballpoint(),
            ),
          );
        }

        final mode = service.recommendExportMode(page);
        expect(mode, PDFExportMode.raster);
      });
    });

    group('Error Handling', () {
      test('should handle empty pages list', () {
        expect(
          () => service.exportPages(
            pages: [],
            config: ExportConfiguration(),
          ),
          throwsArgumentError,
        );
      });

      test('should handle invalid page dimensions', () {
        final page = Page(
          id: 'p1',
          index: 0,
          name: 'Page 1',
          size: PageSize(width: -1, height: -1),
          background: PageBackground.solid(),
          layers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => service.exportPages(
            pages: [page],
            config: ExportConfiguration(),
          ),
          throwsArgumentError,
        );
      });
    });

    group('Disposal', () {
      test('should dispose correctly', () {
        service.dispose();
        expect(service.isDisposed, true);
      });

      test('should throw when using after disposal', () {
        service.dispose();

        expect(
          () => service.exportPages(
            pages: [Page.create(index: 0)],
            config: ExportConfiguration(),
          ),
          throwsStateError,
        );
      });

      test('should allow multiple dispose calls', () {
        service.dispose();
        service.dispose();
        expect(service.isDisposed, true);
      });
    });

    group('File Naming', () {
      test('should generate filename from document title', () {
        final filename = service.generateFilename(
          documentTitle: 'My Document',
        );

        expect(filename, contains('My Document'));
        expect(filename, endsWith('.pdf'));
      });

      test('should sanitize filename', () {
        final filename = service.generateFilename(
          documentTitle: 'Test/File:Name*',
        );

        expect(filename, isNot(contains('/')));
        expect(filename, isNot(contains(':')));
        expect(filename, isNot(contains('*')));
      });

      test('should handle empty title', () {
        final filename = service.generateFilename(
          documentTitle: '',
        );

        expect(filename, isNotEmpty);
        expect(filename, endsWith('.pdf'));
      });
    });

    group('Progress Messages', () {
      test('should generate progress message', () {
        final message = service.generateProgressMessage(
          currentPage: 3,
          totalPages: 10,
        );

        expect(message, contains('3'));
        expect(message, contains('10'));
      });

      test('should handle single page', () {
        final message = service.generateProgressMessage(
          currentPage: 1,
          totalPages: 1,
        );

        expect(message, isNotEmpty);
      });
    });
  });
}
