import 'package:drawing_ui/src/services/pdf_import_service.dart';
import 'package:drawing_ui/src/services/pdf_import_with_limit.dart';
import 'package:drawing_ui/src/services/pdf_page_range.dart';
import 'package:flutter_test/flutter_test.dart';

PDFImportServiceResult _tooMany() => PDFImportServiceResult.error(
      const PdfImportFailure(
        PdfImportError.tooManyPages,
        pageCount: 640,
        maxPages: 500,
      ),
    );

void main() {
  late List<PDFImportConfig> calls;

  Future<PDFImportServiceResult> importWith(PDFImportConfig c) async {
    calls.add(c);
    return c.startPage == null
        ? _tooMany()
        : PDFImportServiceResult.success(const []);
  }

  setUp(() => calls = []);

  test('re-imports with the chosen range after tooManyPages (AC1)', () async {
    int? gotCount, gotMax;
    final result = await importPdfWithPageLimit(
      importWith: importWith,
      chooseRange: (n, max) async {
        gotCount = n;
        gotMax = max;
        return const PdfPageRange(1, 500);
      },
    );

    expect(result!.isSuccess, isTrue);
    expect(gotCount, 640);
    expect(gotMax, 500);
    expect(calls, hasLength(2));
    expect(calls[1].startPage, 1);
    expect(calls[1].endPage, 500);
  });

  test('cancel returns null after one call (AC3)', () async {
    final result = await importPdfWithPageLimit(
      importWith: importWith,
      chooseRange: (_, __) async => null,
    );
    expect(result, isNull);
    expect(calls, hasLength(1));
  });

  test('success makes one call and never asks (AC5)', () async {
    var asked = false;
    final result = await importPdfWithPageLimit(
      importWith: (c) async {
        calls.add(c);
        return PDFImportServiceResult.success(const []);
      },
      chooseRange: (_, __) async {
        asked = true;
        return null;
      },
    );
    expect(result!.isSuccess, isTrue);
    expect(calls, hasLength(1));
    expect(asked, isFalse);
  });

  test('without chooseRange the error is returned as today', () async {
    final result = await importPdfWithPageLimit(importWith: importWith);
    expect(result!.failure!.error, PdfImportError.tooManyPages);
    expect(calls, hasLength(1));
  });

  test('other failures are returned without asking', () async {
    var asked = false;
    final result = await importPdfWithPageLimit(
      importWith: (_) async => PDFImportServiceResult.error(
        const PdfImportFailure(PdfImportError.openFailed),
      ),
      chooseRange: (_, __) async {
        asked = true;
        return null;
      },
    );
    expect(result!.failure!.error, PdfImportError.openFailed);
    expect(asked, isFalse);
  });
}
