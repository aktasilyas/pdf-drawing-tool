import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_exporter.dart';
import 'package:drawing_ui/src/utils/drawing_log.dart';
import 'package:flutter_test/flutter_test.dart';

// A page whose PDF background cannot be loaded is still exported, but the
// result names it so the export flow can warn (#355).

Page _pdfPage(int i, String path) => Page.create(
      index: i,
      size: PageSize.a4Portrait,
      background: PageBackground.pdfLazy(pageIndex: 1, pdfFilePath: path),
    );

const _lowDpi = PDFExportOptions(quality: PDFExportQuality.low);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> warnings;

  setUp(() {
    warnings = [];
    DrawingLog.sink = (level, message, error, stackTrace) {
      if (level == DrawingLogLevel.warning) warnings.add(message);
    };
  });

  tearDown(() => DrawingLog.sink = null);

  test('a missing PDF file is reported by its page position', () async {
    final result = await PDFExporter().exportPages(
      pages: [_pdfPage(0, '/nonexistent/elyanotes_missing.pdf')],
      options: _lowDpi,
    );

    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(result.pdfBytes, isNotEmpty);
    expect(result.missingBackgroundPages, [1]);
    expect(warnings, hasLength(1));
  });

  test('only the pages without their PDF are reported', () async {
    final result = await PDFExporter(sourceOpener: (_) async => null)
        .exportPages(
      pages: [
        Page.create(index: 0, size: PageSize.a4Portrait),
        _pdfPage(1, 'pdfs/gone.pdf'),
        Page.create(index: 2, size: PageSize.a4Portrait),
        _pdfPage(3, 'pdfs/gone.pdf'),
      ],
      options: _lowDpi,
    );

    expect(result.isSuccess, isTrue, reason: result.failure?.name);
    expect(result.missingBackgroundPages, [2, 4]);
  });

  test('pages without a PDF background report nothing', () async {
    final result = await PDFExporter().exportPages(
      pages: [Page.create(index: 0, size: PageSize.a4Portrait)],
      options: _lowDpi,
    );

    expect(result.isSuccess, isTrue);
    expect(result.missingBackgroundPages, isEmpty);
    expect(warnings, isEmpty);
  });
}
