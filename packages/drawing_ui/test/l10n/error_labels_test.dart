import 'package:drawing_ui/drawing_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const strings = DrawingStringsTr();

  test('every ExportFailure has a non-empty distinct message', () {
    final messages = [for (final f in ExportFailure.values) f.message(strings)];
    expect(messages, everyElement(isNotEmpty));
    expect(messages.toSet(), hasLength(ExportFailure.values.length));
  });

  test('every PdfImportError has a non-empty distinct message', () {
    final messages = [
      for (final e in PdfImportError.values)
        PdfImportFailure(e, pageCount: 600, maxPages: 500).message(strings),
    ];
    expect(messages, everyElement(isNotEmpty));
    expect(messages.toSet(), hasLength(PdfImportError.values.length));
  });

  test('too-many-pages message carries both counts', () {
    final message = const PdfImportFailure(
      PdfImportError.tooManyPages,
      pageCount: 600,
      maxPages: 500,
    ).message(strings);
    expect(message, contains('600'));
    expect(message, contains('500'));
  });

  test('PdfImportFailure compares by value', () {
    const a = PdfImportFailure(PdfImportError.tooManyPages, pageCount: 2);
    const b = PdfImportFailure(PdfImportError.tooManyPages, pageCount: 2);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(const PdfImportFailure(PdfImportError.openFailed)));
  });
}
