import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/l10n/error_strings.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/services/image_page_import.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

/// A [width] × [height] PNG, encoded by the engine.
Future<List<int>> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint(),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Returns [result] from every import.
class _FakeImportService extends Fake implements PDFImportService {
  _FakeImportService(this.result);

  final PDFImportServiceResult result;
  bool disposed = false;

  @override
  Future<PDFImportServiceResult> importFromFile({
    required String filePath,
    required PDFImportConfig config,
  }) async =>
      result;

  @override
  void dispose() => disposed = true;
}

Page _pdfPage(int pdfPage) => Page.create(
      index: pdfPage - 1,
      background: PageBackground.pdfLazy(
        pageIndex: pdfPage,
        pdfFilePath: 'pdfs/a.pdf',
      ),
    );

void main() {
  test('reports the skipped page count and re-indexes the pages', () async {
    final service = _FakeImportService(
      PDFImportServiceResult.success(
        [_pdfPage(1), _pdfPage(2)],
        skippedPages: [3],
      ),
    );
    final skipped = <int>[];
    PdfImportFailure? failure;

    final pages = await importPdfAsPages(
      'in.pdf',
      4,
      onError: (f) => failure = f,
      onPagesSkipped: skipped.add,
      createService: () => service,
    );

    expect(pages.map((p) => p.index), [4, 5]);
    expect(skipped, [1]);
    expect(failure, isNull);
    expect(service.disposed, isTrue);
  });

  test('does not report skipped pages when every page was read', () async {
    final service = _FakeImportService(
      PDFImportServiceResult.success([_pdfPage(1)]),
    );
    var calls = 0;

    final pages = await importPdfAsPages(
      'in.pdf',
      0,
      onPagesSkipped: (_) => calls++,
      createService: () => service,
    );

    expect(pages, hasLength(1));
    expect(calls, 0);
  });

  test('a failed import reports the failure, not skipped pages', () async {
    final service = _FakeImportService(
      PDFImportServiceResult.error(
        const PdfImportFailure(PdfImportError.pagesUnreadable),
      ),
    );
    var calls = 0;
    PdfImportFailure? failure;

    final pages = await importPdfAsPages(
      'in.pdf',
      0,
      onError: (f) => failure = f,
      onPagesSkipped: (_) => calls++,
      createService: () => service,
    );

    expect(pages, isEmpty);
    expect(failure?.error, PdfImportError.pagesUnreadable);
    expect(calls, 0);
  });

  testWidgets('an unreadable image reports onImageError and gives no pages',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('add_page_img_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final garbage = File('${dir.path}/bad.png')..writeAsBytesSync([1, 2, 3]);
    var reported = 0;

    final pages = (await tester.runAsync(
      () => importImageAsPage(
        garbage.path,
        0,
        documentsRoot: dir.path,
        onImageError: (e) {
          expect(e, ImagePageImportError.unreadable);
          reported++;
        },
      ),
    ))!;

    expect(pages, isEmpty);
    expect(reported, 1);
    expect(Directory('${dir.path}/elyanotes_images').existsSync(), isFalse);
  });

  testWidgets('an image above the page cap is rejected as too large',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('add_page_big_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final errors = <ImagePageImportError>[];

    final pages = (await tester.runAsync(() async {
      final big = File('${dir.path}/big.png')
        ..writeAsBytesSync(await _png(maxImagePageEdge + 1, 4));
      return importImageAsPage(
        big.path,
        0,
        documentsRoot: dir.path,
        onImageError: errors.add,
      );
    }))!;

    expect(pages, isEmpty);
    expect(errors, [ImagePageImportError.tooLarge]);
    expect(Directory('${dir.path}/elyanotes_images').existsSync(), isFalse);
  });

  testWidgets('an image at the page cap becomes a page of its size',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('add_page_cap_test');
    addTearDown(() => dir.deleteSync(recursive: true));

    final pages = (await tester.runAsync(() async {
      final ok = File('${dir.path}/ok.png')
        ..writeAsBytesSync(await _png(maxImagePageEdge, 4));
      return importImageAsPage(ok.path, 0, documentsRoot: dir.path);
    }))!;

    expect(pages.single.size.width, maxImagePageEdge);
    expect(pages.single.size.height, 4);
  });

  test('camera and gallery picks are downscaled to the page cap', () async {
    registerFallbackValue(ImageSource.gallery);
    final picker = _MockImagePicker();
    when(() => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        )).thenAnswer((_) async => null);

    for (final source in ImageSource.values) {
      await pickImagePagePhoto(picker, source);
      verify(() => picker.pickImage(
            source: source,
            maxWidth: maxImagePageEdge.toDouble(),
            maxHeight: maxImagePageEdge.toDouble(),
            imageQuality: 85,
          )).called(1);
    }
  });

  test('import errors map to the localized messages', () {
    const strings = ErrorStringsTr();
    expect(imagePageImportMessage(strings, ImagePageImportError.tooLarge),
        strings.imageTooLarge);
    expect(imagePageImportMessage(strings, ImagePageImportError.unreadable),
        strings.imageReadFailed);
    expect(strings.imageTooLarge, contains('$maxImagePageEdge'));
  });
}
