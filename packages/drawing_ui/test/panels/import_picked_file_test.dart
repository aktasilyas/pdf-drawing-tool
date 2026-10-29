import 'dart:io';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/panels/add_page_import_helper.dart';
import 'package:drawing_ui/src/services/image_page_import.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/picked_file_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  @override
  Future<PDFImportServiceResult> importFromFile({
    required String filePath,
    required PDFImportConfig config,
  }) async =>
      result;

  @override
  void dispose() {}
}

Page _pdfPage(int pdfPage) => Page.create(
      index: pdfPage - 1,
      background: PageBackground.pdfLazy(
        pageIndex: pdfPage,
        pdfFilePath: 'pdfs/a.pdf',
      ),
    );

void main() {
  group('importPickedFile drops the picker copy (#469)', () {
    late Directory root;
    late Directory cache;

    setUp(() {
      root = Directory.systemTemp.createTempSync('picked_import_test');
      cache = Directory('${root.path}/cache/file_picker/1')
        ..createSync(recursive: true);
    });

    tearDown(() => root.deleteSync(recursive: true));

    Future<void> cleanup(String path) => deletePickedFileCopy(
          path,
          cacheDirectory: () async => '${root.path}/cache',
        );

    File picked(String name) =>
        File('${cache.path}/$name')..writeAsBytesSync([1, 2, 3]);

    test('after a PDF import', () async {
      final pdf = picked('in.pdf');
      final service = _FakeImportService(
        PDFImportServiceResult.success([_pdfPage(1)]),
      );

      final pages = await importPickedFile(
        pdf.path,
        0,
        createService: () => service,
        cleanup: cleanup,
      );

      expect(pages, hasLength(1));
      expect(pdf.existsSync(), isFalse);
    });

    test('after a failed PDF import', () async {
      final pdf = picked('in.pdf');
      final service = _FakeImportService(
        PDFImportServiceResult.error(
          const PdfImportFailure(PdfImportError.openFailed),
        ),
      );
      PdfImportFailure? failure;

      final pages = await importPickedFile(
        pdf.path,
        0,
        onError: (f) => failure = f,
        createService: () => service,
        cleanup: cleanup,
      );

      expect(pages, isEmpty);
      expect(failure?.error, PdfImportError.openFailed);
      expect(pdf.existsSync(), isFalse);
    });

    testWidgets('after an image import, keeping the stored image',
        (tester) async {
      final docs = '${root.path}/docs';

      final (pages, image) = (await tester.runAsync(() async {
        final image = File('${cache.path}/ok.png')
          ..writeAsBytesSync(await _png(8, 4));
        final pages = await importPickedFile(
          image.path,
          0,
          documentsRoot: docs,
          cleanup: cleanup,
        );
        return (pages, image);
      }))!;

      expect(pages, hasLength(1));
      expect(image.existsSync(), isFalse);
      expect(
        Directory('$docs/elyanotes_images').listSync(),
        hasLength(1),
      );
    });

    testWidgets('after a too-large image import', (tester) async {
      final errors = <ImagePageImportError>[];

      final image = (await tester.runAsync(() async {
        final image = File('${cache.path}/big.png')
          ..writeAsBytesSync(await _png(maxImagePageEdge + 1, 4));
        await importPickedFile(
          image.path,
          0,
          documentsRoot: '${root.path}/docs',
          onImageError: errors.add,
          cleanup: cleanup,
        );
        return image;
      }))!;

      expect(errors, [ImagePageImportError.tooLarge]);
      expect(image.existsSync(), isFalse);
    });

    test('but never deletes a picked file outside the cache', () async {
      final original = File('${root.path}/Documents/in.pdf')
        ..createSync(recursive: true);

      await importPickedFile(
        original.path,
        0,
        createService: () => _FakeImportService(
          PDFImportServiceResult.success([_pdfPage(1)]),
        ),
        cleanup: cleanup,
      );

      expect(original.existsSync(), isTrue);
    });
  });
}
