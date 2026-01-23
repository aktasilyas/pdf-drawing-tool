import 'package:flutter_test/flutter_test.dart';
import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/raster_pdf_renderer.dart';

void main() {
  group('RasterPDFRenderer', () {
    late RasterPDFRenderer renderer;

    setUp(() {
      renderer = RasterPDFRenderer();
    });

    group('Constructor', () {
      test('should create with default DPI', () {
        final renderer = RasterPDFRenderer();
        expect(renderer, isNotNull);
        expect(renderer.defaultDPI, 300);
      });

      test('should create with custom DPI', () {
        final renderer = RasterPDFRenderer(defaultDPI: 150);
        expect(renderer.defaultDPI, 150);
      });
    });

    group('DPI Settings', () {
      test('should use low quality DPI', () {
        expect(RasterQuality.low.dpi, 72);
      });

      test('should use medium quality DPI', () {
        expect(RasterQuality.medium.dpi, 150);
      });

      test('should use high quality DPI', () {
        expect(RasterQuality.high.dpi, 300);
      });

      test('should use print quality DPI', () {
        expect(RasterQuality.print.dpi, 600);
      });
    });

    group('Raster Size Calculation', () {
      test('should calculate pixel dimensions from page size', () {
        final size = renderer.calculateRasterSize(
          pageWidth: 595, // A4 width in points
          pageHeight: 842, // A4 height in points
          dpi: 300,
        );

        // 595 points * (300/72) = 2479 pixels
        // 842 points * (300/72) = 3508 pixels
        expect(size.width, closeTo(2479, 1));
        expect(size.height, closeTo(3508, 1));
      });

      test('should handle different DPI values', () {
        final size72 = renderer.calculateRasterSize(
          pageWidth: 595,
          pageHeight: 842,
          dpi: 72,
        );

        final size300 = renderer.calculateRasterSize(
          pageWidth: 595,
          pageHeight: 842,
          dpi: 300,
        );

        expect(size300.width, greaterThan(size72.width));
        expect(size300.height, greaterThan(size72.height));
      });
    });

    group('Complexity Detection', () {
      test('should detect simple page', () {
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

        expect(renderer.isPageComplex(page), false);
      });

      test('should detect complex page with many strokes', () {
        var page = Page.create(index: 0);

        // Add many strokes
        for (int i = 0; i < 1000; i++) {
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

      test('should detect complex page with many points', () {
        final stroke = Stroke(
          id: 's1',
          points: List.generate(
            10000,
            (i) => DrawingPoint(x: i.toDouble(), y: 0),
          ),
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          createdAt: DateTime.now(),
        );

        final page = Page.create(index: 0).addStroke(stroke);

        expect(renderer.isPageComplex(page), true);
      });
    });

    group('Fallback Decision', () {
      test('should recommend vector for simple content', () {
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

        expect(renderer.shouldUseRasterFallback(page), false);
      });

      test('should recommend raster for complex content', () {
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

        expect(renderer.shouldUseRasterFallback(page), true);
      });
    });

    group('Memory Estimation', () {
      test('should estimate memory for raster image', () {
        final memory = renderer.estimateMemoryUsage(
          width: 1000,
          height: 1000,
          dpi: 300,
        );

        // Rough estimate: width * height * 4 bytes (RGBA)
        expect(memory, greaterThan(0));
      });

      test('should scale with resolution', () {
        final memory72 = renderer.estimateMemoryUsage(
          width: 595,
          height: 842,
          dpi: 72,
        );

        final memory300 = renderer.estimateMemoryUsage(
          width: 595,
          height: 842,
          dpi: 300,
        );

        expect(memory300, greaterThan(memory72));
      });
    });

    group('Image Format', () {
      test('should support PNG format', () {
        expect(RasterImageFormat.png, isNotNull);
      });

      test('should support JPEG format', () {
        expect(RasterImageFormat.jpeg, isNotNull);
      });

      test('should get PNG extension', () {
        expect(RasterImageFormat.png.extension, 'png');
      });

      test('should get JPEG extension', () {
        expect(RasterImageFormat.jpeg.extension, 'jpg');
      });

      test('should support transparency for PNG', () {
        expect(RasterImageFormat.png.supportsTransparency, true);
      });

      test('should not support transparency for JPEG', () {
        expect(RasterImageFormat.jpeg.supportsTransparency, false);
      });
    });

    group('Compression Settings', () {
      test('should create default compression settings', () {
        final settings = CompressionSettings();

        expect(settings.enabled, true);
        expect(settings.quality, 90);
      });

      test('should create custom compression settings', () {
        final settings = CompressionSettings(
          enabled: false,
          quality: 80,
        );

        expect(settings.enabled, false);
        expect(settings.quality, 80);
      });

      test('should validate quality range', () {
        expect(
          () => CompressionSettings(quality: 101),
          throwsArgumentError,
        );

        expect(
          () => CompressionSettings(quality: -1),
          throwsArgumentError,
        );
      });
    });

    group('Raster Options', () {
      test('should create default raster options', () {
        final options = RasterExportOptions();

        expect(options.quality, RasterQuality.high);
        expect(options.format, RasterImageFormat.png);
        expect(options.antialiasing, true);
      });

      test('should create custom raster options', () {
        final options = RasterExportOptions(
          quality: RasterQuality.medium,
          format: RasterImageFormat.jpeg,
          antialiasing: false,
        );

        expect(options.quality, RasterQuality.medium);
        expect(options.format, RasterImageFormat.jpeg);
        expect(options.antialiasing, false);
      });

      test('should get DPI from quality', () {
        final options = RasterExportOptions(
          quality: RasterQuality.print,
        );

        expect(options.dpi, 600);
      });
    });

    group('Render Target', () {
      test('should create render target', () {
        final target = RenderTarget(
          width: 1000,
          height: 1000,
          dpi: 300,
        );

        expect(target.width, 1000);
        expect(target.height, 1000);
        expect(target.dpi, 300);
      });

      test('should calculate scale factor', () {
        final target = RenderTarget(
          width: 1000,
          height: 1000,
          dpi: 300,
        );

        // Scale factor = DPI / 72
        expect(target.scaleFactor, closeTo(300 / 72, 0.01));
      });

      test('should calculate pixel area', () {
        final target = RenderTarget(
          width: 100,
          height: 200,
          dpi: 300,
        );

        expect(target.pixelArea, 100 * 200);
      });
    });

    group('Complexity Metrics', () {
      test('should calculate stroke count', () {
        var page = Page.create(index: 0);

        for (int i = 0; i < 50; i++) {
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

        final metrics = renderer.calculateComplexityMetrics(page);
        expect(metrics.strokeCount, 50);
      });

      test('should calculate total point count', () {
        final stroke = Stroke(
          id: 's1',
          points: List.generate(100, (i) => DrawingPoint(x: i.toDouble(), y: 0)),
          style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
          createdAt: DateTime.now(),
        );

        final page = Page.create(index: 0).addStroke(stroke);

        final metrics = renderer.calculateComplexityMetrics(page);
        expect(metrics.totalPoints, 100);
      });

      test('should calculate complexity score', () {
        var page = Page.create(index: 0);

        for (int i = 0; i < 100; i++) {
          page = page.addStroke(
            Stroke(
              id: 's$i',
              points: List.generate(
                100,
                (j) => DrawingPoint(x: j.toDouble(), y: 0),
              ),
              style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
              createdAt: DateTime.now(),
            ),
          );
        }

        final metrics = renderer.calculateComplexityMetrics(page);
        expect(metrics.complexityScore, greaterThan(0.5));
      });
    });

    group('Performance Recommendations', () {
      test('should recommend high DPI for simple pages', () {
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

        final dpi = renderer.recommendDPI(page);
        expect(dpi, greaterThanOrEqualTo(300));
      });

      test('should recommend lower DPI for complex pages', () {
        var page = Page.create(index: 0);

        for (int i = 0; i < 2000; i++) {
          page = page.addStroke(
            Stroke(
              id: 's$i',
              points: List.generate(
                100,
                (j) => DrawingPoint(x: j.toDouble(), y: 0),
              ),
              style: StrokeStyle(color: 0xFF000000, thickness: 2.0),
              createdAt: DateTime.now(),
            ),
          );
        }

        final dpi = renderer.recommendDPI(page);
        expect(dpi, lessThan(300));
      });
    });
  });
}
