import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_page_renderer.dart';

void main() {
  group('PDFImportService', () {
    late PDFImportService service;

    setUp(() {
      service = PDFImportService();
    });

    tearDown(() {
      service.dispose();
    });

    group('Constructor', () {
      test('should create with default dependencies', () {
        final service = PDFImportService();
        expect(service, isNotNull);
        expect(service.isDisposed, false);
      });

      test('should create with custom render options', () {
        final options = PDFRenderOptions(zoom: 2.0);
        final service = PDFImportService(defaultRenderOptions: options);
        expect(service, isNotNull);
      });
    });

    group('State Management', () {
      test('should start in idle state', () {
        expect(service.state, PDFImportState.idle);
      });

      test('should track loading state', () {
        expect(service.isLoading, false);
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

    group('Page Selection', () {
      test('should validate page selection', () {
        expect(
          service.validatePageSelection(
            pageNumbers: [1, 2, 3],
            totalPages: 10,
          ),
          true,
        );
      });

      test('should reject invalid page numbers', () {
        expect(
          service.validatePageSelection(
            pageNumbers: [0, 1, 2],
            totalPages: 10,
          ),
          false,
        );
      });

      test('should reject out of range pages', () {
        expect(
          service.validatePageSelection(
            pageNumbers: [1, 11],
            totalPages: 10,
          ),
          false,
        );
      });

      test('should reject empty selection', () {
        expect(
          service.validatePageSelection(
            pageNumbers: [],
            totalPages: 10,
          ),
          false,
        );
      });
    });

    group('Page Range Generation', () {
      test('should generate page range', () {
        final range = service.generatePageRange(start: 1, end: 5);
        expect(range, [1, 2, 3, 4, 5]);
      });

      test('should handle single page range', () {
        final range = service.generatePageRange(start: 3, end: 3);
        expect(range, [3]);
      });

      test('should return empty for invalid range', () {
        final range = service.generatePageRange(start: 5, end: 1);
        expect(range, isEmpty);
      });
    });

    group('Import Configuration', () {
      test('should create default import config', () {
        final config = PDFImportConfig();

        expect(config.pageSelection, PDFPageSelection.all);
        expect(config.startPage, isNull);
        expect(config.endPage, isNull);
        expect(config.selectedPages, isNull);
        expect(config.embedImages, true);
      });

      test('should create config for page range', () {
        final config = PDFImportConfig.pageRange(
          startPage: 1,
          endPage: 5,
        );

        expect(config.pageSelection, PDFPageSelection.range);
        expect(config.startPage, 1);
        expect(config.endPage, 5);
      });

      test('should create config for selected pages', () {
        final config = PDFImportConfig.selectedPages(
          pages: [1, 3, 5],
        );

        expect(config.pageSelection, PDFPageSelection.selected);
        expect(config.selectedPages, [1, 3, 5]);
      });

      test('should validate range config', () {
        final config = PDFImportConfig.pageRange(
          startPage: 1,
          endPage: 5,
        );

        expect(config.isValid(totalPages: 10), true);
      });

      test('should reject invalid range', () {
        final config = PDFImportConfig.pageRange(
          startPage: 5,
          endPage: 1,
        );

        expect(config.isValid(totalPages: 10), false);
      });

      test('should reject out of bounds range', () {
        final config = PDFImportConfig.pageRange(
          startPage: 1,
          endPage: 15,
        );

        expect(config.isValid(totalPages: 10), false);
      });
    });

    group('Import State', () {
      test('should have idle state', () {
        expect(PDFImportState.idle, isNotNull);
      });

      test('should have loading PDF state', () {
        expect(PDFImportState.loadingPDF, isNotNull);
      });

      test('should have rendering pages state', () {
        expect(PDFImportState.renderingPages, isNotNull);
      });

      test('should have converting pages state', () {
        expect(PDFImportState.convertingPages, isNotNull);
      });

      test('should have completed state', () {
        expect(PDFImportState.completed, isNotNull);
      });

      test('should have error state', () {
        expect(PDFImportState.error, isNotNull);
      });
    });

    group('Page Selection Mode', () {
      test('should have all pages mode', () {
        expect(PDFPageSelection.all, isNotNull);
      });

      test('should have range mode', () {
        expect(PDFPageSelection.range, isNotNull);
      });

      test('should have selected mode', () {
        expect(PDFPageSelection.selected, isNotNull);
      });
    });

    group('Import Result', () {
      test('should create successful result', () {
        final pages = [
          Page.create(index: 0),
          Page.create(index: 1),
        ];

        final result = PDFImportServiceResult.success(pages);

        expect(result.isSuccess, true);
        expect(result.pages, pages);
        expect(result.errorMessage, isNull);
      });

      test('should create error result', () {
        final result = PDFImportServiceResult.error('Failed to load PDF');

        expect(result.isSuccess, false);
        expect(result.pages, isEmpty);
        expect(result.errorMessage, 'Failed to load PDF');
      });

      test('should create cancelled result', () {
        final result = PDFImportServiceResult.cancelled();

        expect(result.isSuccess, false);
        expect(result.pages, isEmpty);
        expect(result.errorMessage, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle null file path', () {
        expect(
          () => service.importFromFile(
            filePath: '',
            config: PDFImportConfig(),
          ),
          throwsArgumentError,
        );
      });

      test('should handle invalid config', () {
        final config = PDFImportConfig.pageRange(
          startPage: 10,
          endPage: 1,
        );

        expect(
          () => service.importFromFile(
            filePath: 'test.pdf',
            config: config,
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
          () => service.importFromFile(
            filePath: 'test.pdf',
            config: PDFImportConfig(),
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

    group('Progress Calculation', () {
      test('should calculate progress for partial completion', () {
        final progress = service.calculateProgress(
          processedPages: 3,
          totalPages: 10,
        );

        expect(progress, closeTo(0.3, 0.01));
      });

      test('should calculate 0% for no progress', () {
        final progress = service.calculateProgress(
          processedPages: 0,
          totalPages: 10,
        );

        expect(progress, 0.0);
      });

      test('should calculate 100% for completion', () {
        final progress = service.calculateProgress(
          processedPages: 10,
          totalPages: 10,
        );

        expect(progress, 1.0);
      });

      test('should handle zero total pages', () {
        final progress = service.calculateProgress(
          processedPages: 0,
          totalPages: 0,
        );

        expect(progress, 0.0);
      });
    });

    group('State Transitions', () {
      test('should transition from idle to loading', () {
        expect(service.canTransitionTo(PDFImportState.loadingPDF), true);
      });

      test('should not allow invalid transitions', () {
        expect(service.canTransitionTo(PDFImportState.convertingPages), false);
      });

      test('should allow transition to error from any state', () {
        expect(service.canTransitionTo(PDFImportState.error), true);
      });
    });

    group('Batch Operations', () {
      test('should calculate batch size', () {
        final batchSize = service.calculateOptimalBatchSize(
          totalPages: 100,
          availableMemory: 50 * 1024 * 1024, // 50MB
        );

        expect(batchSize, greaterThan(0));
        expect(batchSize, lessThanOrEqualTo(100));
      });

      test('should limit batch size to reasonable maximum', () {
        final batchSize = service.calculateOptimalBatchSize(
          totalPages: 1000,
          availableMemory: 1024 * 1024 * 1024, // 1GB
        );

        expect(batchSize, lessThanOrEqualTo(50)); // Max batch size
      });
    });
  });
}
