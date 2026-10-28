import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/image_page_import.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('img_page_test'));
  tearDown(() => root.deleteSync(recursive: true));

  List<FileSystemEntity> stored() {
    final dir = Directory('${root.path}/elyanotes_images');
    return dir.existsSync() ? dir.listSync() : [];
  }

  testWidgets('stores one file and references it relatively', (tester) async {
    await tester.runAsync(() async {
      final source = File('${root.path}/picked.png')
        ..writeAsBytesSync(await _png(4, 3));

      final page = await importImagePage(
        source.path,
        documentsRoot: root.path,
        paths: PdfPathResolver(root.path),
      );

      expect(stored(), hasLength(1));
      expect(
        page.background.imageFilePath,
        matches(RegExp(r'^elyanotes_images/\d+\.png$')),
      );
      expect(page.background.pdfPageIndex, 1);
      expect(page.background.pdfData, isNotNull);
      expect(page.size, const PageSize(width: 4, height: 3));
      expect(page.background.toJson().containsKey('pdfDataBase64'), isFalse);
    });
  });

  testWidgets('invalid bytes throw unreadable and write nothing',
      (tester) async {
    await tester.runAsync(() async {
      final source = File('${root.path}/bad.png')
        ..writeAsBytesSync([1, 2, 3, 4]);

      await expectLater(
        importImagePage(source.path, documentsRoot: root.path),
        throwsA(isA<ImagePageImportException>().having(
            (e) => e.error, 'error', ImagePageImportError.unreadable)),
      );
      expect(stored(), isEmpty);
    });
  });

  testWidgets('missing source throws unreadable', (tester) async {
    await tester.runAsync(() async {
      await expectLater(
        importImagePage('${root.path}/nope.png', documentsRoot: root.path),
        throwsA(isA<ImagePageImportException>()),
      );
      expect(stored(), isEmpty);
    });
  });

  testWidgets('over maxDimension throws tooLarge and writes nothing',
      (tester) async {
    await tester.runAsync(() async {
      final source = File('${root.path}/big.png')
        ..writeAsBytesSync(await _png(4, 3));

      await expectLater(
        importImagePage(source.path, documentsRoot: root.path, maxDimension: 1),
        throwsA(isA<ImagePageImportException>().having(
            (e) => e.error, 'error', ImagePageImportError.tooLarge)),
      );
      expect(stored(), isEmpty);
    });
  });

  testWidgets('discardImportedImagePage removes the stored file',
      (tester) async {
    await tester.runAsync(() async {
      final source = File('${root.path}/picked.png')
        ..writeAsBytesSync(await _png(2, 2));
      final paths = PdfPathResolver(root.path);
      final page = await importImagePage(
        source.path,
        documentsRoot: root.path,
        paths: paths,
      );
      expect(stored(), hasLength(1));

      await discardImportedImagePage(page, paths: paths);

      expect(stored(), isEmpty);
      expect(source.existsSync(), isTrue);
    });
  });
}
