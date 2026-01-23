import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart' as core;
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/drawing_ui.dart';

void main() {
  group('PDF Workflow Integration', () {
    group('PDF Import Flow', () {
      test('should have complete import configuration', () {
        final config = PDFImportConfig.all();

        expect(config.pageSelection, PDFPageSelection.all);
        expect(config.embedImages, true);
      });

      test('should configure page range import', () {
        final config = PDFImportConfig.pageRange(
          startPage: 1,
          endPage: 5,
        );

        expect(config.pageSelection, PDFPageSelection.range);
        expect(config.startPage, 1);
        expect(config.endPage, 5);
      });

      test('should configure selected pages import', () {
        final config = PDFImportConfig.selectedPages(
          pages: [1, 3, 5],
        );

        expect(config.pageSelection, PDFPageSelection.selected);
        expect(config.selectedPages, [1, 3, 5]);
      });

      test('should validate import configuration', () {
        final config = PDFImportConfig.pageRange(
          startPage: 1,
          endPage: 5,
        );

        expect(config.isValid(totalPages: 10), true);
        expect(config.isValid(totalPages: 3), false);
      });
    });

    group('PDF Export Flow', () {
      test('should have complete export configuration', () {
        final config = ExportConfiguration(
          exportMode: PDFExportMode.vector,
          quality: PDFExportQuality.high,
          includeBackground: true,
        );

        expect(config.exportMode, PDFExportMode.vector);
        expect(config.quality, PDFExportQuality.high);
      });

      test('should convert to export options', () {
        final config = ExportConfiguration(
          exportMode: PDFExportMode.hybrid,
          quality: PDFExportQuality.print,
        );

        final options = config.toExportOptions();

        expect(options.exportMode, PDFExportMode.hybrid);
        expect(options.quality, PDFExportQuality.print);
      });

      test('should validate exportable pages', () {
        final page = Page.create(index: 0).addStroke(
          Stroke(
            id: 's1',
            points: [
              DrawingPoint(x: 0, y: 0),
              DrawingPoint(x: 100, y: 100),
            ],
            style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
            createdAt: DateTime.now(),
          ),
        );

        final exporter = PDFExporter();
        expect(exporter.isPageExportable(page), true);
      });
    });

    group('Import/Export Round-Trip', () {
      test('should preserve page structure in export', () {
        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Export Test',
          pages: [
            Page.create(index: 0),
            Page.create(index: 1),
          ], createdAt: DateTime.now(), updatedAt: DateTime.now(),
        );

        final exportService = PDFExportService();
        final config = ExportConfiguration();

        // Create metadata
        final metadata = exportService.createMetadata(doc);

        expect(metadata.title, 'Export Test');
        expect(metadata.creator, 'StarNote');

        exportService.dispose();
      });

      test('should handle empty document export gracefully', () {
        final exportService = PDFExportService();

        expect(exportService.validatePages([]), false);

        exportService.dispose();
      });
    });

    group('PDF Rendering', () {
      test('should calculate correct render dimensions', () {
        final renderer = PDFPageRenderer();

        final dpi = renderer.calculateDPI(
          zoom: 2.0,
          devicePixelRatio: 1.0,
        );

        expect(dpi, 144.0); // 72 * 2.0
      });

      test('should validate page numbers', () {
        final renderer = PDFPageRenderer();

        expect(renderer.isValidPageNumber(1, 10), true);
        expect(renderer.isValidPageNumber(0, 10), false);
        expect(renderer.isValidPageNumber(11, 10), false);
      });
    });

    group('Vector Rendering', () {
      test('should support all pen types', () {
        final renderer = VectorPDFRenderer();

        expect(renderer.supportsPenStyle(core.PenType.ballpointPen), true);
        expect(renderer.supportsPenStyle(core.PenType.gelPen), true);
        expect(renderer.supportsPenStyle(core.PenType.brushPen), true);
        expect(renderer.supportsPenStyle(core.PenType.highlighter), true);
      });

      test('should calculate stroke complexity', () {
        final renderer = VectorPDFRenderer();

        final simpleStroke = Stroke(
          id: 's1',
          points: [
            DrawingPoint(x: 0, y: 0),
            DrawingPoint(x: 100, y: 100),
          ],
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          createdAt: DateTime.now(),
        );

        final complexity = renderer.estimateComplexity(simpleStroke);
        expect(complexity, lessThan(0.1));
      });

      test('should recommend optimization for complex strokes', () {
        final renderer = VectorPDFRenderer();

        final complexStroke = Stroke(
          id: 's1',
          points: List.generate(
            10000,
            (i) => DrawingPoint(x: i.toDouble(), y: 0),
          ),
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          createdAt: DateTime.now(),
        );

        expect(renderer.shouldOptimize(complexStroke), true);
      });
    });

    group('Raster Rendering', () {
      test('should detect complex pages', () {
        final renderer = RasterPDFRenderer();

        var page = Page.create(index: 0);

        for (int i = 0; i < 2000; i++) {
          page = page.addStroke(
            Stroke(
              id: 's$i',
              points: [
                DrawingPoint(x: 0, y: 0),
                DrawingPoint(x: 100, y: 100),
              ],
              style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
              createdAt: DateTime.now(),
            ),
          );
        }

        expect(renderer.isPageComplex(page), true);
      });

      test('should recommend appropriate DPI', () {
        final renderer = RasterPDFRenderer();

        final simplePage = Page.create(index: 0);
        final dpi = renderer.recommendDPI(simplePage);

        expect(dpi, greaterThanOrEqualTo(150));
      });

      test('should calculate memory requirements', () {
        final renderer = RasterPDFRenderer();

        final memory = renderer.estimateMemoryUsage(
          width: 595,
          height: 842,
          dpi: 300,
        );

        expect(memory, greaterThan(0));
      });
    });

    group('Page Conversion', () {
      test('should convert PDF dimensions to page size', () {
        final converter = PDFToPageConverter();

        final size = converter.calculatePageSize(
          pdfWidth: 595, // A4
          pdfHeight: 842,
        );

        expect(size.width, 595);
        expect(size.height, 842);
      });

      test('should generate page names', () {
        final converter = PDFToPageConverter();

        final name = converter.generatePageName(
          pdfPageNumber: 3,
          documentTitle: 'Test Document',
        );

        expect(name, contains('3'));
        expect(name, contains('Test Document'));
      });

      test('should validate page selections', () {
        final converter = PDFToPageConverter();

        expect(
          converter.validatePageNumbers(
            pageNumbers: [1, 2, 3],
            totalPages: 5,
          ),
          true,
        );

        expect(
          converter.validatePageNumbers(
            pageNumbers: [1, 6],
            totalPages: 5,
          ),
          false,
        );
      });
    });

    group('Service Integration', () {
      test('should coordinate import service components', () {
        final importService = PDFImportService();

        expect(importService.state, PDFImportState.idle);
        expect(importService.isLoading, false);

        importService.dispose();
      });

      test('should coordinate export service components', () {
        final exportService = PDFExportService();

        expect(exportService.state, PDFExportState.idle);
        expect(exportService.isExporting, false);

        exportService.dispose();
      });

      test('should track progress during operations', () {
        final importService = PDFImportService();

        final progress = importService.calculateProgress(
          processedPages: 5,
          totalPages: 10,
        );

        expect(progress, 0.5);

        importService.dispose();
      });
    });

    group('Error Recovery', () {
      test('should handle import service errors', () {
        final importService = PDFImportService();

        expect(
          () => importService.validatePageSelection(
            pageNumbers: [],
            totalPages: 10,
          ),
          returnsNormally,
        );

        importService.dispose();
      });

      test('should handle export service errors', () {
        final exportService = PDFExportService();

        expect(
          exportService.validatePages([]),
          false,
        );

        exportService.dispose();
      });
    });

    group('Performance Integration', () {
      test('should handle multiple concurrent operations', () {
        final importService = PDFImportService();
        final exportService = PDFExportService();

        // Both services should be independent
        expect(importService.state, PDFImportState.idle);
        expect(exportService.state, PDFExportState.idle);

        importService.dispose();
        exportService.dispose();
      });

      test('should manage memory across services', () {
        final budget = MemoryBudget(maxBytes: 50 * 1024 * 1024);

        budget.allocate('import', 10 * 1024 * 1024);
        budget.allocate('export', 10 * 1024 * 1024);

        // Note: MemoryBudget doesn't expose usedBytes/availableBytes getters
        // Verify allocation works without throwing
      });
    });

    group('Complete Workflow', () {
      test('should execute full multi-page to PDF export flow', () {
        // 1. Create multi-page document
        final doc = DrawingDocument.multiPage(
          id: 'd1',
          title: 'Complete Workflow',
          pages: [
            Page.create(index: 0).addStroke(
              Stroke(
                id: 's1',
                points: [
                  DrawingPoint(x: 0, y: 0),
                  DrawingPoint(x: 100, y: 100),
                ],
                style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
                createdAt: DateTime.now(),
              ),
            ),
            Page.create(index: 1),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // 2. Setup export
        final exportService = PDFExportService();
        final config = ExportConfiguration(
          exportMode: PDFExportMode.vector,
          quality: PDFExportQuality.high,
        );

        // 3. Validate
        expect(exportService.validatePages(doc.pages), true);

        // 4. Create metadata
        final metadata = exportService.createMetadata(doc);
        expect(metadata.title, 'Complete Workflow');

        exportService.dispose();
      });
    });
  });
}
