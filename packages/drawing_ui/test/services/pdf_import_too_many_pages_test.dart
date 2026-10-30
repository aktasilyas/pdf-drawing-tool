import 'dart:io';

import 'package:drawing_core/drawing_core.dart';
import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class _MockPdfDocument extends Mock implements pdfx.PdfDocument {}

void main() {
  late Directory docs;
  late Directory src;

  setUp(() {
    docs = Directory.systemTemp.createTempSync('pdf_many_docs');
    src = Directory.systemTemp.createTempSync('pdf_many_src');
  });

  tearDown(() {
    docs.deleteSync(recursive: true);
    src.deleteSync(recursive: true);
  });

  test('640 pages: tooManyPages and no stored copy remains (AC3)', () async {
    final doc = _MockPdfDocument();
    when(() => doc.pagesCount).thenReturn(640);
    when(() => doc.close()).thenAnswer((_) async {});
    final source = File('${src.path}/big.pdf')..writeAsBytesSync([1, 2, 3]);
    final service = PDFImportService(
      pdfPaths: PdfPathResolver(docs.path),
      loader: PDFLoader(openFile: (_) async => doc),
    );

    final result = await service.importFromFile(
      filePath: source.path,
      config: PDFImportConfig.all(),
    );
    service.dispose();

    expect(result.failure!.error, PdfImportError.tooManyPages);
    expect(result.failure!.pageCount, 640);
    expect(result.failure!.maxPages, 500);
    final left = docs
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.pdf'));
    expect(left, isEmpty);
  });
}
