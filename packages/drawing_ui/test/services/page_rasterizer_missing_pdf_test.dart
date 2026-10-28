import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/page_png_exporter.dart';
import 'package:drawing_ui/src/services/page_rasterizer.dart';
import 'package:drawing_ui/src/services/thumbnail_generator.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rendering uses real async (picture.toImage, file I/O), which never
/// completes under the FakeAsync zone of a plain [testWidgets].
void testRender(String name, Future<void> Function() body) {
  testWidgets(name, (tester) async {
    await tester.runAsync(body);
  });
}

/// A page whose lazy PDF background points at a file that does not exist.
Page _missingPdfPage() => Page.create(
      index: 0,
      size: const PageSize(width: 200, height: 300),
      background: PageBackground.pdfLazy(
        pageIndex: 1,
        pdfFilePath: '/nonexistent/elyanotes_missing.pdf',
      ),
    );

void main() {
  late List<(DrawingLogLevel, String)> logs;

  setUp(() {
    logs = [];
    DrawingLog.sink = (level, message, error, stackTrace) =>
        logs.add((level, message));
  });

  tearDown(() => DrawingLog.sink = null);

  testRender('a missing PDF file is reported and logged', () async {
    final page = _missingPdfPage();

    final result = await PageRasterizer.renderPngWithStatus(
      page,
      width: 20,
      height: 30,
    );

    expect(result.bytes, isNotEmpty);
    expect(result.pdfBackgroundMissing, isTrue);
    final warnings = logs.where((l) => l.$1 == DrawingLogLevel.warning);
    expect(warnings, hasLength(1));
    expect(warnings.single.$2, contains(page.id));
  });

  testRender('a page without a PDF background is not reported', () async {
    final result = await PageRasterizer.renderPngWithStatus(
      Page.create(index: 0, size: const PageSize(width: 200, height: 300)),
      width: 20,
      height: 30,
    );

    expect(result.pdfBackgroundMissing, isFalse);
    expect(logs, isEmpty);
  });

  testRender('PNG export flags the page exported without its PDF', () async {
    final result = await PagePngExporter.export(
      _missingPdfPage(),
      infiniteCanvas: false,
    );

    expect(result.bytes, isNotEmpty);
    expect(result.pdfBackgroundMissing, isTrue);
  });

  testRender('thumbnails still render a page with a missing PDF', () async {
    final bytes = await ThumbnailGenerator.generate(_missingPdfPage());

    expect(bytes, isNotNull);
    expect(logs.where((l) => l.$1 == DrawingLogLevel.warning), hasLength(1));
  });
}
